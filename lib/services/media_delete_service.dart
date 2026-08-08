import 'package:flutter/services.dart';

/// Wrapper tipis di atas `MethodChannel` native (`MainActivity.kt`) —
/// Architecture.md § 4a. Hapus file fisik dari storage Android lewat
/// `MediaStore.createDeleteRequest` (Android 11+, wajib approve dialog
/// sistem) atau `ContentResolver.delete()`/`RecoverableSecurityException`
/// fallback di device lebih lama.
abstract final class MediaDeleteService {
  static const _channel = MethodChannel('com.anandabint.beatfy/media_store');

  /// `true` kalau file sukses terhapus (atau user approve dialog sistem
  /// Android 11+). `false` kalau user membatalkan dialog sistem atau delete
  /// gagal karena alasan lain — bukan exception, supaya UI bisa kasih
  /// feedback "batal"/"gagal" tanpa perlu try-catch di caller untuk kasus
  /// normal ini.
  static Future<bool> deleteFiles(List<String> uris) async {
    final result = await _channel.invokeMethod<bool>('deleteMediaFiles', {
      'uris': uris,
    });
    return result ?? false;
  }
}
