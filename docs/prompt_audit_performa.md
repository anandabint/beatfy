# Prompt Claude Code — Audit Performa/Smoothness (Gate Sebelum Rilis Final)

Bukan fix bug spesifik — ini sesi audit terstruktur, sesuai `PRD.md` § 11 "Performance gate sebelum rilis final". Tujuan: pastikan tidak ada jank/frame-drop terasa di scroll manapun, transisi antar screen mulus, sebelum Beatfy dianggap final dipakai harian.

## 0. Refresh rate — lock ke Hz tertinggi device (wajib, bukan observasi)

Android secara default sering cap rendering app di 60Hz meski device support 90/120/144Hz, kecuali app eksplisit minta refresh rate tertinggi. Tambahkan package `flutter_displaymode`, panggil `FlutterDisplayMode.setHighRefreshRate()` sedini mungkin di `main()` (setelah `WidgetsFlutterBinding.ensureInitialized()`, sebelum `runApp()`). Ini bikin app otomatis render di Hz maksimum yang didukung device Pann (device 120Hz → app jalan di 120Hz), tidak perlu setting manual per-device.

Verifikasi di device: cek lewat Developer Options → "Show refresh rate" (overlay kecil pojok layar nunjuk Hz aktual saat ini) atau `adb shell dumpsys SurfaceFlinger | grep -i "refresh-rate"` — pastikan angkanya sesuai Hz maksimum device Pann saat app dibuka, bukan default 60.

## Metodologi (jangan cuma "coba lihat rasanya")

1. Jalankan `flutter run --profile` (bukan debug — debug mode Flutter secara natural lebih lambat, tidak representatif) ke device nyata Pann.
2. Aktifkan **Performance Overlay** (`PerformanceOverlay` atau via Flutter DevTools "Performance" tab) — cek grafik UI thread + Raster thread, cari spike/bar merah (indikasi frame >16ms/8ms tergantung refresh rate device).
3. Skenario yang wajib diuji, satu-satu, catat hasil tiap skenario:
   - Scroll cepat di Library (list panjang, 100+ lagu kalau ada).
   - Scroll di Home (termasuk area gradient blob — ini paling berisiko berat karena blur/gradient rendering).
   - Buka Now Playing dari mini player (Hero transition) — cek drop frame saat animasi.
   - Pindah antar tab bottom nav (4 tab) bolak-balik cepat.
   - Buka context menu long-press (bottom sheet animation).
   - Scroll di grouping Album/Artist/Folder (kalau sudah diimplementasikan).

## Area yang wajib dicek kalau ketemu jank (root cause umum di Flutter)

- Widget besar yang rebuild berlebihan — pakai `const` constructor di mana pun bisa, cek `RepaintBoundary` di area yang sering repaint sendiri (misal gradient blob animasi, kalau ada) supaya tidak ikut nge-repaint widget lain di sekitarnya.
- `ListView`/`GridView` tanpa `itemExtent`/`prototypeItem` di list dengan item seragam (Library, grouping) — kalau belum ada, tambahkan supaya Flutter tidak perlu re-layout tiap item saat scroll.
- Image/artwork decoding blocking main thread — pastikan artwork loading (`on_audio_query` artwork API) sudah async dan ada cache in-memory (jangan decode ulang tiap kali widget rebuild/scroll balik ke posisi sama).
- Gradient blob (Home/Now Playing) — kalau pakai `BackdropFilter`/blur berat, itu mahal secara GPU, apalagi kalau area blur besar dan ikut ke-repaint tiap frame scroll. Pertimbangkan cache jadi image statis (`RepaintBoundary` + `toImage`) kalau posisi blob tidak animasi real-time, atau kurangi radius blur kalau memang harus dinamis.
- `AnimationController` yang tidak di-dispose atau terus jalan di background (skeleton loader, dsb) padahal screen sudah tidak visible.

## Yang TIDAK perlu dikerjakan sesi ini

Ini murni audit + fix performa, bukan fitur baru — kalau nemu bug fungsional yang tidak berhubungan sama performa, catat/lapor sesuai `Rules.md` § 2.5 seperti biasa, tapi jangan diperbaiki di sesi ini kecuali kecil sekali (di luar scope, biar tidak campur aduk).

## Laporan akhir

Wajib sertakan: skenario mana yang tadinya jank + fix apa yang diterapkan, dan skenario mana (kalau ada) yang masih terasa kurang smooth meski sudah dicoba fix — jangan diklaim selesai kalau sebenarnya masih ada yang mengganjal, laporkan jujur supaya bisa diputuskan trade-off-nya bareng Pann.
