import 'package:flutter/services.dart';

/// Baca byte mentah dari `content://` URI lagu  sumber upload Drive
/// (Architecture.md § 7). Lewat native channel yang sama dengan
/// `MediaDeleteService` (`readMediaBytes`), bukan lewat `Song.dataPath`
/// (kolom `_data` tidak reliable buat baca byte di scoped storage
/// Android 10+  lihat Schema.md § 2).
abstract final class MediaReadService {
  static const _channel = MethodChannel('com.anandabint.beatfy/media_store');

  static Future<Uint8List> readBytes(String uri) async {
    final result = await _channel.invokeMethod<Uint8List>('readMediaBytes', {
      'uri': uri,
    });
    if (result == null) {
      throw StateError('readMediaBytes returned null for $uri');
    }
    return result;
  }
}
