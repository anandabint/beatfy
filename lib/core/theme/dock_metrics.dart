/// Fallback tinggi dock (`MiniPlayer` + pill bottom nav) — Design.md § 7.
/// **Bukan** dipakai sebagai padding final list mana pun  itu sumber bug
/// "baris terakhir list ketutup dock" yang berulang balik lagi di beberapa
/// sesi (Architecture.md § 3a/§ 7e): device beda punya safe-area beda,
/// `MiniPlayer` bisa muncul/hilang, dan angka statis manapun gampang
/// meleset dari ukuran layout asli. Padding final sekarang diukur langsung
/// dari layout nyata lewat `dockHeightProvider`
/// (`providers/layout_providers.dart`)  konstanta di sini cuma dipakai
/// sebagai nilai awal sebelum pengukuran pertama selesai (frame pertama
/// startup), supaya tidak mulai dari 0/tanpa clearance sama sekali.
abstract final class DockMetrics {
  /// `MiniPlayer`: `Container` tinggi 64 + padding bawah `AppSpacing.sm` (8).
  static const miniPlayerHeight = 72.0;

  /// `_BottomNavBar`: pill icon 44 + padding vertikal `AppSpacing.sm` * 2 (16)
  /// + padding bawah `AppSpacing.sm` (8).
  static const navBarHeight = 68.0;

  /// Perkiraan awal (dock lengkap, MiniPlayer+NavBar) sebelum pengukuran
  /// layout nyata pertama selesai.
  static const fallbackClearance = miniPlayerHeight + navBarHeight;
}
