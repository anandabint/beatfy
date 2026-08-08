import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';

/// Ekstrak dominant color dari artwork lagu untuk ambient blob Now Playing
/// (Architecture.md § 7b) — cache in-memory per `songId`, cukup untuk satu
/// sesi app (tidak perlu persist ke Hive).
abstract final class AmbientColorCache {
  static final Map<String, List<Color>> _cache = {};
  static final OnAudioQuery _query = OnAudioQuery();

  /// Hasil yang sudah pernah diekstrak untuk `songId`, kalau ada — dipakai
  /// untuk render instan tanpa nunggu extraction ulang saat lagu yang sama
  /// diputar lagi dalam sesi yang sama.
  static List<Color>? cached(String songId) => _cache[songId];

  /// Null kalau lagu tidak punya artwork atau ekstraksi gagal — caller wajib
  /// fallback ke blob ungu-pink default di kasus itu, bukan crash/blank.
  static Future<List<Color>?> extract(String songId, int albumArtId) async {
    final existing = _cache[songId];
    if (existing != null) return existing;

    try {
      final bytes = await _query.queryArtwork(
        albumArtId,
        ArtworkType.ALBUM,
        format: ArtworkFormat.JPEG,
        size: 200,
      );
      if (bytes == null || bytes.isEmpty) return null;

      final palette = await PaletteGenerator.fromImageProvider(
        MemoryImage(bytes),
        maximumColorCount: 12,
      );
      final dominant =
          palette.dominantColor?.color ?? palette.colors.firstOrNull;
      if (dominant == null) return null;

      final hsl = HSLColor.fromColor(dominant);
      final colors = [
        dominant,
        hsl.withLightness((hsl.lightness * 0.5).clamp(0.0, 1.0)).toColor(),
      ];
      _cache[songId] = colors;
      return colors;
    } on Object {
      return null;
    }
  }
}
