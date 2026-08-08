import 'package:flutter/material.dart';

/// Color tokens — Design.md § 2 (revisi 2026-08-06, dibaca dari source Figma
/// Make Version 3). Lime accent + canvas gelap non-achromatic, ditambah
/// gradient blob dekoratif ungu-pink sebagai elemen atmosferik (Home + Now
/// Playing saja — lihat Design.md § 11).
abstract final class AppColors {
  // Brand — lime, bukan hijau Spotify versi lama
  static const primary = Color(0xFFC8F135);
  static const primaryDeep = Color(0xFFB0D62A);

  // Canvas
  static const canvas = Color(0xFF141414);
  static const surface = Color(0xFF1C1C1C);
  static const surfaceHover = Color(0xFF2A2A2A);
  static const surfaceMuted = Color(0xFF242424);

  // Text
  static const ink = Color(0xFFF0F0F0);
  static const ash = Color(0xFFB3B3B3);
  static const stone = Color(0xFF7C7C7C);

  // Gradient blob dekoratif — Home + Now Playing background saja, dekoratif
  // murni (pointer-events none), tidak pernah dipakai sebagai warna fungsional.
  static const blobPurple = Color.fromRGBO(150, 80, 220, 0.55);
  static const blobPink = Color.fromRGBO(200, 60, 160, 0.3);

  // Semantic — dipertahankan dari versi sebelumnya
  static const success = Color(0xFF2B9A66);
  static const warning = Color(0xFFFFA42B);
  static const danger = Color(0xFFF3727F);
  static const info = Color(0xFF539DF5);

  static const hairline = Color(0xFF2A2A2A);
  static const divider = Color(0xFF2A2A2A);
}
