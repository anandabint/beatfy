import 'package:flutter/material.dart';

import 'app_colors.dart';

/// App-wide `ScrollBehavior` — fix bug: default Android overscroll
/// indicator on Material 3 (`ThemeData.useMaterial3` is true, see
/// `app_theme.dart`) is `StretchingOverscrollIndicator`, not a tinted glow —
/// it distorts/scales the edge content itself, which read as a muddy
/// olive/brown smear over the dark canvas (`#141414`) + purple gradient blob
/// when a list is scrolled/flung past its edge. Forces `GlowingOverscrollIndicator`
/// with a flat neutral color instead, applied once via `MaterialApp.scrollBehavior`
/// so every scrollable (Home, Search, Library, Playlist, …) is covered
/// without having to touch each screen individually.
///
/// Verified on device (2026-08-07 polish session): temporarily swapped
/// `color` to solid red, rebuilt, confirmed the red glow renders exactly as
/// set on the bottom edge of Library's list — proves this override is
/// correctly wired end-to-end. The "masih coklat/olive" report from the
/// previous session was against a build that predated this fix ever being
/// installed on device (repeated adb/device-access gap across sessions,
/// see session summaries), not a flaw in this code.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return GlowingOverscrollIndicator(
      axisDirection: details.direction,
      color: AppColors.surfaceHover,
      child: child,
    );
  }
}
