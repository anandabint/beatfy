import 'package:flutter/material.dart';

/// Transisi antar screen default — Design.md § 10: fade + slight slide
/// (~250-300ms, `Curves.easeOutCubic`), bukan default abrupt Material
/// transition. Dipasang lewat `ThemeData.pageTransitionsTheme` supaya
/// berlaku untuk semua navigasi `MaterialPageRoute`/`PageRoute`, bukan cuma
/// expand mini player → Now Playing (yang sudah pakai `Hero` terpisah).
class FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
