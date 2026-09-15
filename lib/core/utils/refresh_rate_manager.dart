import 'package:flutter/widgets.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

/// Menjaga refresh rate di mode tertinggi yang device dukung (PRD.md § 11
/// performance gate; Android-only, no-op diam-diam di platform lain).
///
/// `setHighRefreshRate()` otomatis mengikuti kemampuan device (ambil mode
/// dengan refresh rate tertinggi pada resolusi aktif) — device yang cuma
/// sanggup 90Hz akan dapat 90Hz, yang sanggup 120Hz akan dapat 120Hz, tanpa
/// perlu logic pembeda di sisi app.
///
/// FIX (v1.0.3 lanjutan): preferensi ini ternyata tidak persisten di semua
/// device — kembali dari background/setelah app di-kill lalu dibuka lagi
/// bisa jatuh balik ke 60Hz kalau cuma di-set sekali saat cold start.
/// Observer ini re-apply tiap kali app kembali ke foreground (resumed),
/// bukan cuma sekali di [main].
class RefreshRateManager extends WidgetsBindingObserver {
  void start() {
    WidgetsBinding.instance.addObserver(this);
    _apply();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _apply();
  }

  Future<void> _apply() async {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
      final active = await FlutterDisplayMode.active;
      debugPrint('Display mode set: ${active.refreshRate}Hz');
    } on Object catch (error) {
      debugPrint('Failed to set high refresh rate: $error');
      // no-op; refresh rate tetap default kalau device/platform tidak support.
    }
  }
}
