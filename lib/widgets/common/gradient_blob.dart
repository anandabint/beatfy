import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Dekoratif radial-gradient blob ungu-pink  Design.md § 2, dipakai di
/// background Home + Now Playing **saja** (§ 11: jangan taruh di screen
/// padat/scannable lain seperti Library/Search/Playlist). Murni atmosferik,
/// tidak pernah interaktif  selalu di-`IgnorePointer`.
class GradientBlob extends StatelessWidget {
  const GradientBlob({super.key, this.size = 280, this.colors});

  final double size;

  /// Override 2 warna (dominant + shade lebih gelap)  dipakai Now Playing
  /// untuk ambient color dinamis dari artwork (Architecture.md § 7b,
  /// Design.md § 7 "Now Playing  ambient color dinamis"). Null = default
  /// ungu-pink statis (dipakai juga di Home, yang tidak punya konsep "lagu
  /// aktif").
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    final gradientColors = colors != null
        ? [colors![0], colors![1], Colors.transparent]
        : const [AppColors.blobPurple, AppColors.blobPink, Colors.transparent];

    return IgnorePointer(
      // Isolasi layer blur (mahal secara GPU) dari repaint tetangganya 
      // tanpa ini, scroll di ListView/Hero transition sekitarnya bisa ikut
      // memicu raster ulang blob padahal posisinya statis (audit performa
      // PRD.md § 11, 2026-08-07).
      child: RepaintBoundary(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: gradientColors,
                stops: const [0.0, 0.45, 0.7],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
