# Prompt Claude Code — Home Screen Widget (Mini Player)

Baca `Architecture.md` § 1 (tech stack), § 2 prinsip 2 (AudioHandler = satu-satunya sumber kebenaran playback state), dan § 4 (Playback Architecture) sebelum mulai. Widget ini **tidak boleh** punya logic playback sendiri — dia cuma tampilan + pengirim command ke `AudioHandler` yang sudah ada, sama seperti UI Flutter (mini player, Now Playing) memperlakukannya.

## Kenapa fitur ini

Semua kompetitor utama (Musicolet, Pulsar, Retro Music) punya widget kontrol playback di homescreen — ini salah satu fitur yang paling sering dipakai harian di kategori music player, dan belum ada di scope Beatfy manapun (v1/v2). Sifatnya opt-in (user pasang sendiri kalau mau), jadi tidak melanggar prinsip minimalist.

## Langkah 1 — Riset package (wajib sebelum coding)

Cek package `home_widget` (bridge Flutter ↔ native App Widget, dipakai luas untuk kasus persis seperti ini) — versi terbaru, status maintenance, dan apakah masih kompatibel dengan versi Flutter/Android yang dipakai project ini. Kalau ada alternatif yang lebih baik/lebih terawat saat ini, **lapor dulu ke Pann dengan alasan sebelum ganti**, sama seperti aturan Architecture.md § 1 penutup.

## Langkah 2 — Desain widget (klarifikasi soal Material 3 — baca ini dulu)

Widget Android dirender lewat `RemoteViews`/`GlanceAppWidget` di proses launcher, **bukan** lewat widget tree Flutter — artinya font custom (Inter/Outfit) dan sebagian styling di `Design.md` **tidak bisa** dipakai 1:1 di sana, itu keterbatasan platform, bukan pilihan. Keputusan untuk widget ini:

- **Background**: pakai warna brand `AppColors.canvas` (`#141414`) fixed — **jangan** ikut Material You dynamic color (warna dari wallpaper user). Alasan: widget harus tetap terlihat seperti Beatfy secara konsisten sebagai identitas, bukan berubah-ubah ikut tema sistem tiap device.
- **Aksen aktif** (tombol play, indikator sedang main): `AppColors.primary` (lime `#C8F135`), konsisten dengan seluruh app.
- **Artwork**: pakai artwork asli lagu; kalau tidak ada, reuse logic `ArtworkFallback` yang sudah ada (Architecture.md § 7b) — jangan bikin fallback gradient baru yang beda dari yang dipakai song row/Now Playing.
- **Bentuk**: circular untuk artwork kecil di widget, konsisten dengan geometri lingkaran di seluruh Design.md (album art, avatar semua circular).
- Kalau `home_widget`/`GlanceAppWidget` di versi yang dipakai ternyata **tidak** bisa render circular clip atau font custom sama sekali (keterbatasan API level tertentu), gunakan idiom native Android biasa (Material 3 default shape/typography sistem) sebagai fallback — ini bukan kompromi kualitas, tapi konsekuensi wajar surface yang dikontrol sistem, bukan sesuatu yang perlu dipaksa sama persis dengan in-app UI.

Layout minimal (1 ukuran dulu, cukup ~4x1 grid cell): artwork kecil (circular) di kiri, judul+artis (truncate ellipsis, 1-2 baris) di tengah, tombol prev/play-pause/next di kanan.

## Langkah 3 — Update data widget

- Widget update **hanya** saat ada perubahan `PlaybackState`/`MediaItem` yang sudah di-broadcast `AudioHandler` (Architecture.md § 4) — subscribe ke stream yang sama yang dipakai provider Flutter, **jangan** bikin polling terpisah atau sumber data kedua.
- Push data baru ke widget lewat `HomeWidget.saveWidgetData` + `HomeWidget.updateWidget()` (atau API setara di versi package final) tiap kali title/artist/artwork/status playing berubah.

## Langkah 4 — Tombol aksi widget

Tiap tombol (prev/play-pause/next) kirim command lewat `PendingIntent`/broadcast ke `AudioHandler` yang sedang aktif (foreground service yang sudah ada untuk notification/lock-screen control, Architecture.md § 4) — **pakai jalur command yang sama** dengan yang dipakai notification media control, jangan buat action handler kedua yang terpisah. Tombol wajib berfungsi walau app di-swipe dari recent apps (selama foreground service masih hidup), sama seperti kontrol dari notification/lock-screen sudah berfungsi sekarang.

## QC (wajib device nyata)

1. Pasang widget di homescreen device Pann, play lagu dari app, pastikan artwork+judul+artis widget update real-time.
2. Tap prev/play-pause/next langsung dari widget saat app di **background** dan saat app sudah **di-swipe dari recent apps** (service masih foreground) — pastikan tetap responsif, bukan cuma saat app foreground.
3. Ganti lagu dari dalam app (bukan dari widget) — pastikan widget ikut update tanpa perlu re-tap apapun.
4. Restart device / widget dihapus-pasang ulang — pastikan tidak crash, tampil state kosong/wajar (bukan crash) kalau belum ada lagu yang pernah diputar.

Laporkan di akhir: package final yang dipakai + alasan, screenshot widget di homescreen device nyata, hasil test kontrol dari kondisi background/killed.
