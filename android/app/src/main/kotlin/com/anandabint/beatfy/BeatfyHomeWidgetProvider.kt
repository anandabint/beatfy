package com.anandabint.beatfy

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.Shader
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import android.util.Size
import android.view.KeyEvent
import android.widget.RemoteViews
import com.ryanheise.audioservice.MediaButtonReceiver
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home screen widget (docs/prompt_home_widget.md). Pure presentation +
 * command sender, exactly like the mini player / Now Playing screen treat
 * `AudioHandler` (Architecture.md § 2, § 4) - this class has zero playback
 * logic of its own:
 *
 * - Data comes from [HomeWidgetService] (Dart) pushing whatever
 *   `AudioHandler` already broadcasts via `mediaItem`/`playbackState`, saved
 *   through the `home_widget` plugin's `SharedPreferences` bridge. This
 *   class only reads that data back and lays it out - it never queries
 *   MediaStore/Hive itself.
 * - Button taps never call into this class' own code: prev/play-pause/next
 *   broadcast a plain `ACTION_MEDIA_BUTTON` intent straight to
 *   `com.ryanheise.audioservice.MediaButtonReceiver`, the exact same
 *   receiver + intent shape `AudioService.java` itself builds for the
 *   notification's controls (`buildMediaButtonPendingIntent`). Same
 *   command path as notification/lock-screen, no second action handler.
 */
class BeatfyHomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val hasSong = widgetData.getBoolean(KEY_HAS_SONG, false)
        val title = widgetData.getString(KEY_TITLE, null)
        val artist = widgetData.getString(KEY_ARTIST, null)
        val artUri = widgetData.getString(KEY_ART_URI, null)
        val playing = widgetData.getBoolean(KEY_PLAYING, false)

        for (appWidgetId in appWidgetIds) {
            val views = buildViews(context, hasSong, title, artist, artUri, playing)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun buildViews(
        context: Context,
        hasSong: Boolean,
        title: String?,
        artist: String?,
        artUri: String?,
        playing: Boolean,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.beatfy_home_widget)

        views.setViewVisibility(R.id.widget_content_row, if (hasSong) android.view.View.VISIBLE else android.view.View.GONE)
        views.setViewVisibility(R.id.widget_empty_state, if (hasSong) android.view.View.GONE else android.view.View.VISIBLE)

        // Tap anywhere outside the buttons opens the app, straight to Now
        // Playing - same destination as tapping the notification
        // (Architecture.md § 4a).
        views.setOnClickPendingIntent(R.id.widget_root, buildOpenAppPendingIntent(context))

        if (!hasSong) return views

        views.setTextViewText(R.id.widget_title, title ?: "")
        views.setTextViewText(R.id.widget_artist, artist ?: "")

        val artworkSizePx = (WIDGET_ARTWORK_SIZE_DP * context.resources.displayMetrics.density).toInt()
        val artworkBitmap =
            loadCircularArtwork(context, artUri, artworkSizePx)
                ?: WidgetArtworkFallback.circularGradientBitmap(
                    context,
                    ArtworkGradients.songSeed(title ?: "", artist ?: ""),
                    artworkSizePx,
                )
        views.setImageViewBitmap(R.id.widget_artwork, artworkBitmap)

        views.setImageViewResource(
            R.id.widget_btn_play_pause,
            if (playing) R.drawable.ic_widget_pause else R.drawable.ic_widget_play,
        )
        // Play/pause sits on a lime circle (widget_play_pause_circle) - black
        // glyph on top of it, same treatment as the in-app play/pause button
        // (mini player, Now Playing). Prev/next stay plain ink-tinted icons.
        views.setInt(R.id.widget_btn_play_pause, "setColorFilter", Color.BLACK)
        val inkColor = context.getColor(R.color.widget_ink)
        views.setInt(R.id.widget_btn_prev, "setColorFilter", inkColor)
        views.setInt(R.id.widget_btn_next, "setColorFilter", inkColor)

        views.setOnClickPendingIntent(
            R.id.widget_btn_prev,
            buildMediaButtonPendingIntent(context, KeyEvent.KEYCODE_MEDIA_PREVIOUS),
        )
        views.setOnClickPendingIntent(
            R.id.widget_btn_play_pause,
            buildMediaButtonPendingIntent(context, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE),
        )
        views.setOnClickPendingIntent(
            R.id.widget_btn_next,
            buildMediaButtonPendingIntent(context, KeyEvent.KEYCODE_MEDIA_NEXT),
        )

        return views
    }

    /**
     * Same shape as `AudioService.buildMediaButtonPendingIntent` (bundled
     * with the `audio_service` plugin): a broadcast `Intent` carrying
     * `ACTION_MEDIA_BUTTON` + a `KeyEvent` extra, targeted explicitly at
     * `MediaButtonReceiver`. That receiver forwards it to whichever
     * `MediaSessionCompat` is currently active, which is `AudioHandler`'s -
     * this works whether the app is foregrounded, backgrounded, or fully
     * swiped from recents, exactly like the notification's own buttons,
     * because it IS the notification's own mechanism.
     */
    private fun buildMediaButtonPendingIntent(context: Context, keyCode: Int): PendingIntent {
        val intent = Intent(context, MediaButtonReceiver::class.java)
        intent.setAction(Intent.ACTION_MEDIA_BUTTON)
        intent.putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }
        return PendingIntent.getBroadcast(context, keyCode, intent, flags)
    }

    private fun buildOpenAppPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }
        return PendingIntent.getActivity(context, OPEN_APP_REQUEST_CODE, intent, flags)
    }

    /**
     * Same `content://media/external/audio/media/<id>` URI + `loadThumbnail`
     * strategy as `AudioService.java`'s own notification/lock-screen artwork
     * (see `QueueManager.toMediaItem` on the Dart side) - null on any
     * failure (no embedded art, revoked permission, etc.), never throws.
     */
    private fun loadCircularArtwork(context: Context, artUriString: String?, sizePx: Int): Bitmap? {
        if (artUriString.isNullOrEmpty()) return null
        return try {
            val uri = Uri.parse(artUriString)
            val square =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    context.contentResolver.loadThumbnail(uri, Size(sizePx, sizePx), null)
                } else {
                    context.contentResolver.openFileDescriptor(uri, "r")?.use {
                        BitmapFactory.decodeFileDescriptor(it.fileDescriptor)
                    } ?: return null
                }
            WidgetArtworkFallback.cropToCircle(square, sizePx)
        } catch (error: Exception) {
            null
        }
    }

    private companion object {
        const val KEY_HAS_SONG = "hasSong"
        const val KEY_TITLE = "title"
        const val KEY_ARTIST = "artist"
        const val KEY_ART_URI = "artUri"
        const val KEY_PLAYING = "playing"
        const val WIDGET_ARTWORK_SIZE_DP = 40
        const val OPEN_APP_REQUEST_CODE = 4272
    }
}

/**
 * Port of `lib/core/theme/artwork_gradients.dart` (`ArtworkGradients`) -
 * same curated 10-pair palette, same `title|artist` seed, same rolling
 * multiply-by-31 hash (computed with `Long` here to mirror Dart's 64-bit
 * `int` wraparound instead of Kotlin's 32-bit `String.hashCode()`, so the
 * palette pick matches the in-app fallback for virtually every real title -
 * the two diverge only in the astronomically unlikely case a hash lands on
 * exactly `Long.MIN_VALUE`). Deliberately NOT reusing the in-app
 * `SongArtwork`/`ArtworkGradients` Dart code directly - this surface is
 * rendered by the launcher process, outside the Flutter widget tree
 * (docs/prompt_home_widget.md Langkah 2), so the same visual logic has to
 * exist natively too. Keep this palette in sync with the Dart source if it
 * ever changes.
 */
private object ArtworkGradients {
    private val palette =
        listOf(
            0xFF3A2E5C.toInt() to 0xFF1F1533.toInt(), // deep violet
            0xFF1F4B4A.toInt() to 0xFF10262A.toInt(), // teal ink
            0xFF5C2A45.toInt() to 0xFF2E1220.toInt(), // plum rose
            0xFF2E3A5C.toInt() to 0xFF15192E.toInt(), // indigo navy
            0xFF4A3B1F.toInt() to 0xFF261D10.toInt(), // amber bronze
            0xFF1F5C3A.toInt() to 0xFF102B1D.toInt(), // forest green
            0xFF5C3A2E.toInt() to 0xFF2E1D15.toInt(), // clay rust
            0xFF3A5C55.toInt() to 0xFF1A2E2A.toInt(), // sage slate
            0xFF4A2E5C.toInt() to 0xFF241530.toInt(), // orchid
            0xFF2E4A5C.toInt() to 0xFF15242E.toInt(), // steel blue
        )

    fun songSeed(title: String, artist: String): String = "$title|$artist"

    fun forSeed(seed: String): Pair<Int, Int> {
        if (seed.isEmpty()) return palette[0]
        var hash = 0L
        for (unit in seed) {
            hash = hash * 31 + unit.code
        }
        val index = ((hash % palette.size) + palette.size) % palette.size
        return palette[index.toInt()]
    }
}

/** Circular crop + gradient-fallback bitmap helpers shared by [BeatfyHomeWidgetProvider]. */
private object WidgetArtworkFallback {
    fun cropToCircle(source: Bitmap, sizePx: Int): Bitmap {
        val output = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        canvas.drawOval(0f, 0f, sizePx.toFloat(), sizePx.toFloat(), paint)
        paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
        val scaled = Bitmap.createScaledBitmap(source, sizePx, sizePx, true)
        canvas.drawBitmap(scaled, 0f, 0f, paint)
        return output
    }

    /** Same look as Dart's `_GradientPlaceholder`: diagonal gradient circle + a centered note glyph. */
    fun circularGradientBitmap(context: Context, seed: String, sizePx: Int): Bitmap {
        val (startColor, endColor) = ArtworkGradients.forSeed(seed)
        val output = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val size = sizePx.toFloat()

        val gradientPaint = Paint(Paint.ANTI_ALIAS_FLAG)
        gradientPaint.shader =
            LinearGradient(0f, 0f, size, size, startColor, endColor, Shader.TileMode.CLAMP)
        canvas.drawOval(0f, 0f, size, size, gradientPaint)

        val noteDrawable = Icon.createWithResource(context, R.drawable.ic_widget_note).loadDrawable(context)
        if (noteDrawable != null) {
            noteDrawable.setTint(Color.argb(217, 255, 255, 255)) // ~0.85 alpha white, matches Dart
            val noteSize = (size * 0.45f).toInt()
            val left = ((size - noteSize) / 2f).toInt()
            val top = ((size - noteSize) / 2f).toInt()
            noteDrawable.setBounds(left, top, left + noteSize, top + noteSize)
            noteDrawable.draw(canvas)
        }
        return output
    }
}
