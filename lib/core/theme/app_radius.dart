/// Shape/radius tokens — Design.md § 5 (circular-first, revisi 2026-08-06).
/// Semua art/avatar/playlist cover sekarang lingkaran penuh — pakai
/// `BorderRadius.circular(size / 2)` atau `CircleBorder()` langsung di
/// tempat pemakaian, bukan token di sini.
abstract final class AppRadius {
  static const xs = 4.0; // input, alert
  static const md =
      8.0; // dialog, popup menu — non-art surface, tidak dicover eksplisit oleh Design.md v3
  static const lg =
      16.0; // featured card — satu-satunya elemen besar yang tetap rounded-rect (Design.md § 5)
  static const pill = 999.0; // filter pill, sort pill, search input, button
}
