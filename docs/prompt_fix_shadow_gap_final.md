# Prompt Claude Code  Fix Presisi: Gap Keyboard Search + Hapus Shadow Pill

Saya sudah baca sendiri `main_shell.dart`, `mini_player.dart`, `search_screen.dart` langsung dari project  ini bukan prompt "tolong investigasi", ini instruksi persis. Tolong terapkan, build, verifikasi visual cepat, tidak perlu eksplorasi luas lagi.

## 1. Hapus shadow di pill (bottom nav + mini player)  final, bukan dikecilkan

Pann sudah putuskan: pill harus berdiri sendiri tanpa shadow gelap sama sekali, bukan cuma dikurangi.

- `lib/screens/shell/main_shell.dart`, class `_BottomNavBar`  di dalam `BoxDecoration` pada `DecoratedBox`, hapus properti `boxShadow: [...]` seluruhnya (baris ~99-105 di versi saat ini).
- `lib/widgets/now_playing/mini_player.dart`, class `MiniPlayer`  di dalam `BoxDecoration` pada `DecoratedBox` terluar, hapus properti `boxShadow: [...]` seluruhnya (baris ~42-48 di versi saat ini). Biarkan `clipBehavior: Clip.antiAlias` di `Material` di bawahnya tetap ada (itu fix ink-splash yang benar, tidak berhubungan dengan shadow).

## 2. Fix gap keyboard Search  root cause sudah presisi ditemukan

File: `lib/screens/search/search_screen.dart`.

**Root cause**: `resultsBottomPadding` (baris ~51-53) di-set ke angka tetap kecil (`AppSpacing.sm`) saat keyboard terbuka, tidak proporsional ke tinggi keyboard asli (`MediaQuery.viewInsets.bottom`, bisa ratusan pixel tergantung device/keyboard). Ini kenapa list panjang (banyak hasil) tetap kelihatan ada gap besar  padding-nya cuma ~8px, jauh dari cukup menutupi tinggi keyboard asli.

**Fix persis**:

1. Tambahkan `resizeToAvoidBottomInset: false` eksplisit ke `Scaffold` di `SearchScreen` (saat ini tidak di-set, jadi pakai default `true`  nested Scaffold di dalam `MainShell` yang sudah `resizeToAvoidBottomInset: false` itu rawan resize tidak konsisten, jangan andalkan auto-resize implisit).
2. Ubah baris:
   ```dart
   final resultsBottomPadding = keyboardOpen ? AppSpacing.sm : AppSpacing.xxxl;
   ```
   jadi proporsional ke tinggi keyboard asli:
   ```dart
   final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
   final resultsBottomPadding = viewInsetsBottom > 0
       ? viewInsetsBottom + AppSpacing.sm
       : AppSpacing.xxxl;
   ```
   (variabel `keyboardOpen` yang lama boleh dihapus kalau sudah tidak dipakai di tempat lain di file yang sama, cek dulu.)

## QC (ringan, karena fix ini presisi bukan eksploratif)

- Build & install, buka Search, ketik query yang hasilnya BANYAK (list panjang, situ yang paling tahu query apa di device situ yang hasilnya banyak)  konfirmasi list sekarang nempel pas ke atas keyboard, TIDAK ada gap hitam kosong.
- Screenshot bottom nav + mini player, konfirmasi tidak ada shadow/gelap di sekitar pill sama sekali  betul-betul polos, cuma bentuk pill-nya saja yang terlihat.
- Kalau setelah fix ini masih ada sisa gap (harusnya tidak, tapi kalau ada), laporkan ukuran gap-nya + `viewInsetsBottom` value yang ke-print (boleh tambah `debugPrint` sementara buat cek)  supaya kalau ada masalah lagi, sudah ada data pasti, bukan tebakan lagi dari kedua sisi.
