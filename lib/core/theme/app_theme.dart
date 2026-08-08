import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_page_transitions.dart';
import 'app_radius.dart';
import 'app_text_theme.dart';

/// Single dark `ThemeData` — Beatfy is dark-only, no light theme (Design.md § 0).
abstract final class AppTheme {
  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: Colors.black,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: AppColors.danger,
      onError: Colors.black,
    );

    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvas,
      fontFamily: 'Inter',
      dividerColor: AppColors.divider,
      // Design.md § 12: highlight/splash yang kelihatan jelas di dark bg —
      // default Material ripple abu-abu terang kontrasnya rendah di near-black.
      splashColor: AppColors.surfaceHover.withValues(alpha: 0.5),
      highlightColor: AppColors.surfaceHover.withValues(alpha: 0.3),
    );

    return base.copyWith(
      textTheme: AppTextTheme.textTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        elevation: 0,
        // Fix bug: M3 default blends `colorScheme.surfaceTint` (follows
        // `primary`, lime) into the AppBar once `scrolledUnderElevation`
        // kicks in (list scrolled off-top) — reads as a coklat/olive smear
        // on the near-black canvas, reverting to pure black back at top.
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: AppTextTheme.titleMedium.copyWith(color: AppColors.ink),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          textStyle: AppTextTheme.labelMedium,
          shape: const StadiumBorder(),
          minimumSize: const Size(64, 44),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.ink),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceHover,
        textStyle: AppTextTheme.bodyMedium.copyWith(color: AppColors.ink),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {TargetPlatform.android: FadeSlidePageTransitionsBuilder()},
      ),
    );
  }
}
