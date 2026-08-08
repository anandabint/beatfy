import 'package:flutter/services.dart';

/// Tulis file audio hasil restore Drive ke koleksi Audio publik
/// (`Music/Beatfy`), bukan app-private storage (Schema.md § 5 — keputusan
/// dilaporkan ke Pann) — supaya `AudioQueryService.scan()` biasa langsung
/// menemukannya. Lewat native channel yang sama dengan `MediaDeleteService`.
abstract final class MediaInsertService {
  static const _channel = MethodChannel('com.anandabint.beatfy/media_store');

  /// Return content:// URI hasil insert.
  static Future<String> insertAudioFile({
    required String displayName,
    required Uint8List bytes,
    String mimeType = 'audio/mpeg',
  }) async {
    final result = await _channel.invokeMethod<String>('insertAudioFile', {
      'displayName': displayName,
      'bytes': bytes,
      'mimeType': mimeType,
    });
    if (result == null) {
      throw StateError('insertAudioFile returned null for $displayName');
    }
    return result;
  }
}
