import 'package:flutter/material.dart';

/// Typography tokens  Design.md § 3 (revisi 2026-08-06). Dua font family:
/// **Outfit** untuk display/heading/angka rank, **Inter** untuk body/label.
/// `TextTheme` (Material 3) has no `caption`/`rankNumber` slot  keduanya
/// diekspos terpisah di bawah.
abstract final class AppTextTheme {
  static const _display = 'Outfit';
  static const _body = 'Inter';

  static const displayLarge = TextStyle(
    fontFamily: _display,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.1,
  );

  static const titleMedium = TextStyle(
    fontFamily: _display,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  /// Angka rank 1-3 di Top 10  oversized, sesuai temuan Figma Make.
  static const rankNumber = TextStyle(
    fontFamily: _display,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1.0,
  );

  static const bodyMedium = TextStyle(
    fontFamily: _body,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const bodySmall = TextStyle(
    fontFamily: _body,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const labelMedium = TextStyle(
    fontFamily: _body,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// Fine print / timestamp. Not part of Material 3's `TextTheme`.
  static const caption = TextStyle(
    fontFamily: _body,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static TextTheme textTheme(TextTheme base) => base.copyWith(
    displayLarge: displayLarge,
    titleMedium: titleMedium,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelMedium: labelMedium,
    labelLarge: labelMedium,
  );
}
