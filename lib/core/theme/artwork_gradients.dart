import 'package:flutter/material.dart';

/// Palet gradient fallback untuk artwork lagu tanpa embedded art
/// (Architecture.md § 7b, Design.md § 7 "Artwork fallback gradient").
///
/// Kurasi manual (bukan hue acak penuh spektrum dari HSL) supaya semua
/// kombinasi tetap cocok tema gelap `#141414`  tiap pasangan sudah
/// dipilih agar kontras cukup untuk ikon musik putih di atasnya tanpa
/// terasa norak.
abstract final class ArtworkGradients {
  static const List<List<Color>> _palette = [
    [Color(0xFF3A2E5C), Color(0xFF1F1533)], // deep violet
    [Color(0xFF1F4B4A), Color(0xFF10262A)], // teal ink
    [Color(0xFF5C2A45), Color(0xFF2E1220)], // plum rose
    [Color(0xFF2E3A5C), Color(0xFF15192E)], // indigo navy
    [Color(0xFF4A3B1F), Color(0xFF261D10)], // amber bronze
    [Color(0xFF1F5C3A), Color(0xFF102B1D)], // forest green
    [Color(0xFF5C3A2E), Color(0xFF2E1D15)], // clay rust
    [Color(0xFF3A5C55), Color(0xFF1A2E2A)], // sage slate
    [Color(0xFF4A2E5C), Color(0xFF241530)], // orchid
    [Color(0xFF2E4A5C), Color(0xFF15242E)], // steel blue
  ];

  /// Seed dari judul+artis lagu (bukan album  banyak file lokal tidak
  /// punya album tag, atau MediaStore mengisi placeholder generik yang
  /// sama untuk banyak lagu berbeda, yang sebelumnya bikin semua lagu
  /// tanpa artwork jatuh ke gradient identik).
  static String songSeed(String title, String artist) => '$title|$artist';

  static List<Color> forSeed(String seed) {
    if (seed.isEmpty) return _palette[0];
    final hash = seed.codeUnits.fold<int>(0, (acc, c) => acc * 31 + c);
    return _palette[hash.abs() % _palette.length];
  }
}
