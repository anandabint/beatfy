# Prompt Claude Code — Dukungan Android Auto

Baca `Architecture.md` § 2 prinsip 1 & 2 (separation of concerns ketat, `AudioHandler` = satu-satunya sumber kebenaran playback) dan § 4 sebelum mulai. Android Auto **wajib** memutar lewat `AudioHandler` yang sama persis dengan yang dipakai UI Flutter — tidak ada instance/queue kedua, tidak ada logic playback terpisah untuk "mode mobil".

## Kenapa fitur ini sekarang

Google baru redesign besar-besaran Android Auto (I/O 2026 — Material 3 Expressive, widget baru, UI music app baru). Momentumnya bagus karena kompetitor sekelas Beatfy (minimalist, personal project) jarang yang sudah polish di sini — biasanya cuma app streaming besar (Spotify/YouTube Music) yang duluan dapat perhatian redesign ini. Karena project ini sudah pakai `audio_service`, dukungan dasar Android Auto **built-in** di package tersebut (dia implement `MediaBrowserService` Android secara native) — potensial "hampir gratis" dibanding dibuat dari nol.

## Langkah 1 — Riset feasibility (wajib sebelum coding penuh)

Cek dokumentasi resmi package `audio_service` versi yang dipakai project ini:
1. Apakah `BaseAudioHandler` expose method yang perlu di-override untuk browsable media (`getChildren(parentMediaId)`, `playFromMediaId(mediaId)`, opsional `search`).
2. Requirement `AndroidManifest.xml`: intent-filter `android.media.browse.MediaBrowserService` di service yang sudah didaftarkan `audio_service`, plus meta-data `com.google.android.gms.car.application` yang menunjuk ke file resource `automotive_app_desc.xml` (declare `<uses name="media"/>`).

Kalau versi `audio_service` yang dipakai project **tidak** expose ini dengan stabil, atau butuh upgrade major version yang berisiko breaking change ke playback inti yang sudah stabil — **berhenti, laporkan ke Pann** dengan opsi yang ada (upgrade dengan risiko X, atau tunda fitur ini) sebelum lanjut. Playback inti yang sudah teruji stabil **tidak boleh** dikorbankan demi fitur ini.

## Langkah 2 — Implementasi minimal viable (scope kecil dulu)

1. **Manifest**: tambahkan meta-data + intent-filter sesuai temuan Langkah 1.
2. **`getChildren`**: expose **flat list semua lagu** di library sebagai root browsable — ambil dari repository yang sama yang dipakai Library tab Flutter (`library_repository.dart`), **jangan** bikin query MediaStore kedua yang terpisah. Grouping (album/artist/playlist) untuk Android Auto **belum perlu** di versi pertama ini — itu iterasi lanjutan kalau versi flat-list sudah jalan baik.
3. **`playFromMediaId`**: set queue + mulai putar lagu yang dipilih dari head unit lewat `AudioHandler` yang sama — perilaku (persist posisi, restore, dst) harus konsisten dengan yang sudah ada di Architecture.md § 4, tidak ada pengecualian khusus "mode Android Auto".
4. **`MediaItem` metadata** (title, artist, artwork `Uri`) ambil dari sumber yang sama dipakai Now Playing screen — termasuk fallback artwork (`ArtworkFallback`, § 7b) kalau lagu tidak punya artwork asli, supaya konsisten dengan tampilan di HP.

## Langkah 3 — Soal desain visual (klarifikasi Material 3 — baca ini dulu)

**Tidak perlu khawatir menyesuaikan Design.md ke sini.** Layar Android Auto sepenuhnya dirender & dikontrol oleh template sistem Google (mengikuti Material 3 Expressive per update 2026), bukan oleh widget tree Flutter app — app cuma **supply data** (judul, artis, artwork, daftar lagu, status playing), bukan layout/warna. Satu-satunya titik yang mungkin bisa disentuh (tergantung API yang di-expose `audio_service`) adalah warna aksen notification channel — kalau ada opsinya, boleh pakai `AppColors.primary` (lime) di situ; kalau tidak ada, skip saja, itu bukan blocker fitur ini.

## Langkah 4 — QC

Device fisik dengan Android Auto (kabel/wireless ke unit mobil) kemungkinan tidak tersedia — **Android Studio menyediakan Desktop Head Unit (DHU)**, simulator resmi Android Auto yang jalan di laptop tanpa perlu mobil sungguhan, sambungkan ke device/emulator lewat `adb`. Pakai ini untuk QC:

1. Buka Beatfy dari layar DHU, pastikan muncul di app launcher Android Auto.
2. Browse daftar lagu (flat list dari Langkah 2), pilih satu, pastikan mulai main.
3. Kontrol play/pause/next/prev dari layar DHU — cek balik ke HP: status playback di app Flutter (mini player/Now Playing) harus **konsisten real-time** dengan yang dikontrol dari DHU (bukti `AudioHandler` benar-benar satu sumber kebenaran, bukan dua state terpisah).
4. Cek metadata (judul, artis, artwork) tampil benar di layar DHU, termasuk kasus lagu tanpa artwork asli (fallback harus muncul, bukan blank/crash).
5. Putar lagu dari HP langsung (bukan dari DHU) sambil masih terhubung — pastikan DHU ikut ter-update tanpa perlu reconnect.

Laporkan di akhir: hasil riset Langkah 1 (versi `audio_service` + fitur yang tersedia), keputusan scope grouping (flat-list saja untuk sekarang), dan hasil test DHU (screenshot kalau bisa capture layarnya).
