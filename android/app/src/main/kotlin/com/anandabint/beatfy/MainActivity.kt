package com.anandabint.beatfy

import android.app.Activity
import android.app.RecoverableSecurityException
import android.content.ContentValues
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

/**
 * PRD.md § 7.7 / Architecture.md § 4a  real file delete via scoped storage.
 * Extended (2026-08-07, cloud backup session) with `readMediaBytes` (upload
 * source) and `insertAudioFile` (restore target)  same channel, same
 * rationale: no actively-maintained Flutter plugin wraps these MediaStore
 * write/read APIs reliably for arbitrary (non app-owned) content URIs.
 * Restore writes to the public Music collection, not app-private storage
 * (Schema.md § 5)  so restored files are visible to the same
 * `AudioQueryService.scan()` used for every other song.
 */
class MainActivity : AudioServiceActivity() {
    private val channelName = "com.anandabint.beatfy/media_store"
    private var pendingDeleteResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "deleteMediaFiles" -> {
                    @Suppress("UNCHECKED_CAST")
                    val uris = (call.argument<List<String>>("uris") ?: emptyList()).map(Uri::parse)
                    deleteMediaFiles(uris, result)
                }
                "readMediaBytes" -> {
                    val uri = Uri.parse(call.argument<String>("uri"))
                    readMediaBytes(uri, result)
                }
                "insertAudioFile" -> {
                    val displayName = call.argument<String>("displayName")!!
                    val bytes = call.argument<ByteArray>("bytes")!!
                    val mimeType = call.argument<String>("mimeType") ?: "audio/mpeg"
                    insertAudioFile(displayName, bytes, mimeType, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Sumber byte upload (Architecture.md § 7)  dibaca lewat resolver dari
     * URI `content://` yang sudah dipakai buat playback, bukan dari kolom
     * `_data` (tidak reliable buat baca byte di scoped storage Android 10+).
     */
    private fun readMediaBytes(uri: Uri, result: MethodChannel.Result) {
        try {
            val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() }
            if (bytes == null) {
                result.error("READ_FAILED", "openInputStream returned null for $uri", null)
            } else {
                result.success(bytes)
            }
        } catch (e: Exception) {
            result.error("READ_ERROR", e.message, null)
        }
    }

    /**
     * Target restore Drive (Schema.md § 5)  insert ke koleksi Audio publik
     * `Music/Beatfy`, bukan app-private, supaya `AudioQueryService.scan()`
     * biasa langsung menemukannya tanpa kode khusus.
     */
    private fun insertAudioFile(
        displayName: String,
        bytes: ByteArray,
        mimeType: String,
        result: MethodChannel.Result,
    ) {
        try {
            val uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                insertAudioFileScoped(displayName, bytes, mimeType)
            } else {
                insertAudioFileLegacy(displayName, bytes, mimeType)
            }
            if (uri == null) {
                result.error("INSERT_FAILED", "MediaStore insert returned null", null)
            } else {
                result.success(uri.toString())
            }
        } catch (e: Exception) {
            result.error("INSERT_ERROR", e.message, null)
        }
    }

    @RequiresApi(Build.VERSION_CODES.Q)
    private fun insertAudioFileScoped(displayName: String, bytes: ByteArray, mimeType: String): Uri? {
        val values = ContentValues().apply {
            put(MediaStore.Audio.Media.DISPLAY_NAME, displayName)
            put(MediaStore.Audio.Media.MIME_TYPE, mimeType)
            put(MediaStore.Audio.Media.RELATIVE_PATH, Environment.DIRECTORY_MUSIC + "/Beatfy")
            put(MediaStore.Audio.Media.IS_PENDING, 1)
        }
        val uri = contentResolver.insert(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, values) ?: return null
        contentResolver.openOutputStream(uri)?.use { it.write(bytes) }
        values.clear()
        values.put(MediaStore.Audio.Media.IS_PENDING, 0)
        contentResolver.update(uri, values, null, null)
        return uri
    }

    /** Android < 10 (pre scoped-storage)  file write langsung + media scan. */
    private fun insertAudioFileLegacy(displayName: String, bytes: ByteArray, mimeType: String): Uri? {
        val musicDir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC), "Beatfy")
        if (!musicDir.exists()) musicDir.mkdirs()
        val file = File(musicDir, displayName)
        FileOutputStream(file).use { it.write(bytes) }

        val values = ContentValues().apply {
            put(MediaStore.Audio.Media.DISPLAY_NAME, displayName)
            put(MediaStore.Audio.Media.MIME_TYPE, mimeType)
            @Suppress("DEPRECATION")
            put(MediaStore.Audio.Media.DATA, file.absolutePath)
        }
        val uri = contentResolver.insert(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, values)
        MediaScannerConnection.scanFile(this, arrayOf(file.absolutePath), arrayOf(mimeType), null)
        return uri
    }

    @RequiresApi(Build.VERSION_CODES.R)
    private fun deleteViaSystemConfirmation(uris: List<Uri>, result: MethodChannel.Result) {
        val pendingIntent = MediaStore.createDeleteRequest(contentResolver, uris)
        pendingDeleteResult = result
        @Suppress("DEPRECATION")
        startIntentSenderForResult(pendingIntent.intentSender, DELETE_REQUEST_CODE, null, 0, 0, 0)
    }

    /**
     * Android 11+ (R, API 30): satu-satunya jalur resmi adalah
     * `createDeleteRequest`, yang selalu memunculkan dialog approve sistem
     * (di luar/tambahan dari dialog konfirmasi in-app Beatfy).
     *
     * Android 10 (Q, API 29): scoped storage sudah berlaku tapi
     * `createDeleteRequest` belum ada  jalur resminya adalah tangkap
     * [RecoverableSecurityException] dari `contentResolver.delete()` lalu
     * jalankan `IntentSender` bawaan exception itu (pola khusus Q).
     *
     * Di bawah Q: scoped storage belum berlaku, `contentResolver.delete()`
     * langsung berhasil tanpa dialog tambahan.
     */
    private fun deleteMediaFiles(uris: List<Uri>, result: MethodChannel.Result) {
        if (uris.isEmpty()) {
            result.success(true)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            deleteViaSystemConfirmation(uris, result)
            return
        }
        try {
            uris.forEach { contentResolver.delete(it, null, null) }
            result.success(true)
        } catch (e: RecoverableSecurityException) {
            pendingDeleteResult = result
            @Suppress("DEPRECATION")
            startIntentSenderForResult(
                e.userAction.actionIntent.intentSender,
                DELETE_REQUEST_CODE,
                null,
                0,
                0,
                0,
            )
        } catch (e: SecurityException) {
            result.error("PERMISSION_DENIED", e.message, null)
        }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == DELETE_REQUEST_CODE) {
            pendingDeleteResult?.success(resultCode == Activity.RESULT_OK)
            pendingDeleteResult = null
        }
    }

    private companion object {
        const val DELETE_REQUEST_CODE = 4271
    }
}
