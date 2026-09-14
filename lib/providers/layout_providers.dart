import 'package:flutter_riverpod/legacy.dart';

import '../core/theme/dock_metrics.dart';

/// Tinggi asli dock (`MiniPlayer` + `_BottomNavBar` di `MainShell`) hasil
/// pengukuran layout nyata (bukan konstanta ditebak)  Architecture.md
/// § 3a/§ 7e: riwayat bug "baris terakhir list ketutup dock" berulang kali
/// balik lagi karena versi-versi sebelumnya selalu pakai angka statis yang
/// gampang meleset (safe-area beda-beda per device, `MiniPlayer` bisa
/// muncul/hilang tergantung ada/tidaknya sesi playback aktif, dst). Di-update
/// oleh `_DockMeasurer` (`main_shell.dart`) tiap kali dock selesai layout.
/// Seed awal `DockMetrics.fallbackClearance` supaya frame pertama (sebelum
/// pengukuran nyata selesai) tidak mulai dari 0/tanpa clearance sama sekali.
final dockHeightProvider = StateProvider<double>(
  (ref) => DockMetrics.fallbackClearance,
);
