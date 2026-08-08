# PRD — Beatfy

Product Requirements Document. Sumber kebenaran tentang **apa** yang dibangun dan **kenapa**. Architecture.md, Design.md, Rules.md, Schema.md adalah turunan teknis dari dokumen ini.

## 1. Latar Belakang

Pann sebelumnya membangun music player offline (native Kotlin/Compose, nama sama: Beatfy) dan sudah dipakai harian. Masalah bukan pada konsep, tapi eksekusi:

- Bug fungsional: posisi playback reset ke awal lagu setiap app di-minimize lalu dibuka kembali.
- Transisi/navigasi terasa patah-patah, tidak native-feel.
- Ada fitur (optimasi headset Sony WI-C100) yang dikerjakan tapi tidak memberi value nyata — effort tidak sebanding hasil.
- Tidak pernah selesai difinalisasi, banyak bug menumpuk tak diperbaiki.

Alasan bikin ulang dari nol: aplikasi musik bawaan Android (di luar ekosistem Samsung) tidak cocok, aplikasi Play Store (seperti Musicolet) terlalu banyak setting/fitur yang bikin berat dipakai. Beatfy dibuat untuk mengisi celah itu — **minimalist tapi powerful**: hanya fitur inti yang benar dipakai tiap hari, dieksekusi sampai benar-benar mulus, bukan sekadar checklist fitur.

Rujukan front-end/arsitektur kode yang sudah terbukti nyaman dipakai: **Planly** (aplikasi keuangan pribadi Pann, Flutter + Riverpod + Hive) — pola folder dan state management-nya dipakai ulang.

## 2. Tujuan Produk

Music player Android pribadi yang:

1. Memutar file MP3 yang sudah ada di HP dengan playback yang **sempurna** — tidak ada glitch, tidak ada reset posisi, kontrol lock-screen/Bluetooth berfungsi penuh.
2. Terasa **smooth dan native**, level yang sebelumnya gagal dicapai di versi Kotlin.
3. Tampilan **dark, minimalist, terinspirasi Spotify** — album art jadi sumber warna utama, UI sendiri achromatic.
4. File musik **tidak pernah hilang** meski HP di-reset/ganti — lewat backup otomatis ke cloud (v2), mirip pengalaman Telegram: otomatis, silent, tanpa langkah manual seperti WhatsApp.

## 3. Target Pengguna

Single-user personal project. Dipakai oleh Pann sendiri di Android miliknya. Tidak dirancang untuk publish massal di v1/v2 — tapi kode ditulis rapi seolah-olah suatu saat bisa di-generalize.

## 4. Non-Goals (sengaja tidak dikerjakan)

- Tidak streaming musik dari internet (Spotify/YouTube Music style). Sumber selalu file lokal.
- Tidak ada equalizer/optimasi khusus per-merek perangkat Bluetooth (fitur Sony lama di-drop). Yang dikerjakan adalah deteksi & handling output Bluetooth/wired yang **general dan benar-benar berfungsi**, bukan gimmick kosmetik.
- Tidak multi-user/sharing/social feature.
- Tidak streaming dari cloud saat playback — cloud (v2) murni untuk backup/restore, bukan sumber putar harian. Playback selalu dari cache lokal.
- Tidak iOS. Android-only.

## 5. Prinsip Produk

- **Minimalist**: kalau sebuah fitur tidak dipakai setiap minggu, tidak masuk v1.
- **Powerful lewat eksekusi, bukan jumlah fitur**: playback engine, state restore, dan smoothness UI adalah prioritas nomor satu di atas segala fitur tambahan.
- **Offline-first buat pemakaian harian**: cloud (v2) adalah jaring pengaman, bukan dependency untuk denger musik sehari-hari.
- **Tidak ada fitur setengah jadi**: fitur baru dianggap selesai hanya setelah diuji langsung di device nyata (lihat Rules.md — QC wajib tiap sesi Claude Code).

## 6. Scope — v1 (Player Inti)

Target: aplikasi yang sudah bisa dipakai harian menggantikan versi lama, meski fiturnya lebih sedikit.

| # | Fitur | Detail |
|---|-------|--------|
| 1 | Auto-scan library | Scan MediaStore Audio collection + folder Downloads. Filename cleanup: strip "Official Audio"/tag bitrate, split pola "Artist - Title" kalau metadata artist kosong (perilaku sama seperti versi lama). |
| 2 | Playback inti | Play/pause/seek/next/prev/shuffle/repeat (off/one/all). Queue dinamis. |
| 3 | Now Playing screen | Album art besar, progress bar (scrubbing), kontrol utama, info lagu. |
| 4 | Mini player | Bar persisten di bawah, tap untuk expand ke Now Playing. |
| 5 | State restore yang benar | App di-minimize/kill lalu dibuka lagi → posisi, lagu, queue **persis seperti terakhir**. Status play/pause **selalu direstore sebagai paused** (keputusan final, lihat § 11) — user tap play sendiri untuk lanjut, mencegah audio auto-blast tak terduga. Ini fix eksplisit untuk bug utama versi lama. |
| 6 | Lock-screen & notification control | MediaSession penuh: play/pause/skip dari notification, lock screen, Bluetooth media button (tombol fisik headset). |
| 7 | Output detection fungsional | Deteksi Bluetooth/wired connect-disconnect, auto pause saat device audio disconnect (standard Android behavior), volume handling yang benar per-output — real functionality, bukan UI kosmetik. |
| 8 | Library browse dasar | List semua lagu (judul, artis, durasi, artwork). Sort by title/artist/tanggal ditambahkan. |
| 9 | Permission handling | Runtime permission READ_MEDIA_AUDIO (Android 13+) / storage permission (di bawahnya), notification permission (Android 13+) untuk foreground service. |

**Definition of Done v1**: Pann pakai app ini sebagai pengganti harian tanpa balik ke app lama, minimal 1 minggu tanpa crash/bug mengganggu.

## 7. Scope — v2 (Setelah v1 Stabil)

Dikerjakan hanya setelah v1 lolos QC dan dipakai stabil.

**Klarifikasi penting (2026-08-06)**: v1 sengaja single-screen (library list + now playing) tanpa shell navigasi — itu scope minimal yang dipilih di awal, bukan keputusan visual final. v2 adalah tempat **struktur navigasi utuh** dibangun: shell 4-tab bottom navigation, identik dengan `Destinations.kt`/`BottomNavItem` di beatfy-main lama (Home, Search, Library, Playlist), dieksekusi mengikuti pola struktural `main_shell.dart` Planly (`IndexedStack` + `BottomNavigationBar`, active tab dapat pill highlight) — **hanya polanya** yang dicontek dari Planly (state preservation per tab, motion, kerapian shell), bukan warna/tema Planly (navy/teal, light). Semua warna/token tetap 100% ikut Design.md (dark, hijau Spotify).

| # | Fitur | Detail |
|---|-------|--------|
| 0 | **Navigation shell 4-tab** | `MainShell` (nama beda, pola sama Planly): `IndexedStack` menampung 4 tab — Home, Search, Library, Playlist — state per tab terjaga saat pindah-pindah. `BottomNavigationBar` bertema Design.md (bg `surface`/`canvas`, active tab pill hijau `primary`, bukan teal). Library screen v1 yang sudah ada dipindah jadi salah satu tab, bukan lagi root tunggal. |
| 1 | Playlist tab | Buat/hapus/rename playlist, tambah-hapus lagu, reorder. Layar list playlist + detail playlist. |
| 2 | Favorite | Tandai lagu favorit. Ditampilkan sebagai section/filter di dalam Library tab (bukan tab terpisah — beatfy lama juga tidak punya tab favorite sendiri). |
| 3 | Search tab | Cari across judul/artis/album, real-time filter. |
| 4 | Home tab | Recently added, Top 10 (berdasar play count) — persis fitur versi lama, sekarang jadi tab pertama/default sesuai pola lama. |
| 5 | Cloud backup (Google Drive) | Upload MP3 ke folder khusus di Google Drive akun Pann. Login via Google Sign-In (sudah jalan, 2026-08-07). Restore penuh (download semua file) saat login pertama di device baru/abis reset — mirip Telegram: otomatis, tanpa langkah manual. **Entry point Settings difinalisasi (2026-08-07): tap avatar di header Home** membuka `SettingsScreen` — bukan tab bottom nav terpisah (nav tetap 4 tab, keputusan sebelumnya tidak berubah). **Revisi trigger upload (2026-08-07)**: bukan lagi otomatis saat WiFi tersambung — dihapus karena di device dengan 2+ akun Google memicu popup pemilihan akun yang tidak bisa dihindari (keterbatasan Android Credential Manager, bukan bug app, lihat Architecture.md § 4c). Diganti tombol "Backup Sekarang" eksplisit di Settings — konsekuensinya user perlu buka Settings sesekali dan tap manual, bukan sepenuhnya silent seperti Telegram. Restore tetap otomatis (itu jalan sekali di cold-start, bukan berulang, jadi tidak kena masalah yang sama). |
| 6 | Browse by album/artist/folder | Grouping tambahan di dalam Library tab, di atas list flat v1 (album detail, artist detail, folder detail — persis rute `album/{albumId}`, `artist/{artistName}`, `folder/{folderPath}` di beatfy-main lama). |
| 7 | Hapus lagu dari device (real file delete) | Long-press pada song row (semua tab: Home/Search/Library/Playlist) membuka context menu (bottom sheet). Salah satu aksi: "Hapus dari perangkat" — menghapus file MP3 **asli** dari storage Android, bukan cuma dari tampilan app. Wajib pakai jalur resmi scoped-storage Android 11+ (`MediaStore.createDeleteRequest`), disertai dialog konfirmasi eksplisit yang menyebutkan sifatnya permanen dan tidak bisa dibatalkan. Setelah sukses, entry terkait dibersihkan juga dari Hive (`songs`, `favorites`, `play_stats`, referensi di `playlists`). Menggantikan swipe-to-delete sebagai jalur utama hapus per-lagu (ditambahkan 2026-08-07, detail lengkap di Design.md § 7 & Architecture.md § 4a). |
| 8 | Onboarding (first launch) | Slide perkenalan singkat (3 slide) → permission storage/media → halaman Google Sign-In dengan penjelasan benefit ("kenapa login Google") + opsi "Lanjut dengan Google" atau "Lewati". Hanya muncul sekali (flag di Hive), tidak muncul lagi setelah itu meski user belum/tidak login. Ditambahkan 2026-08-07. |
| 9 | Audio enhancement otomatis | Peningkatan kualitas audio bawaan (loudness/EQ ringan/bass boost ringan via Android native audio effects) supaya MP3 kualitas biasa tetap terdengar baik — otomatis aktif, tanpa UI equalizer manual (tetap minimalist). Best-effort, tergantung feasibility teknis `just_audio`. Ditambahkan 2026-08-07. |
| 10 | Section "Tentang" (Settings) | App version, developer ("Ananda Bintang Ramadhan"), kontak/lapor bug (email `anandabramadhan@gmail.com`), pernyataan privasi ringkas in-app, halaman lisensi open source bawaan Flutter. Tujuan: app terasa resmi/profesional dan privasi jelas ke user, meski masih personal project. Ditambahkan 2026-08-07, detail di Design.md § 7. |

## 8. Metric Keberhasilan (kualitatif, personal project)

- Zero bug pause/resume reset posisi.
- Tidak ada frame drop/stutter terasa saat navigasi antar screen (dites langsung di device Pann, bukan emulator).
- Recovery state 100% akurat setelah app di-kill oleh sistem (low memory) — bukan cuma di-minimize biasa.
- v2: file yang di-backup bisa direstore penuh di device lain/abis reset tanpa langkah manual selain login.

## 9. Risiko & Mitigasi

| Risiko | Mitigasi |
|--------|----------|
| Background service Android kena kill agresif oleh OEM battery optimizer | Foreground service dengan notification persisten (wajib untuk media playback), dokumentasikan di Rules.md cara test battery-optimization exemption. |
| Scan MediaStore lambat kalau library besar | Async scan + cache hasil di Hive, jangan re-scan penuh tiap buka app — index incremental. |
| Google Drive quota (v2) kepenuhan kalau library MP3 besar | Bukan masalah teknis kita untuk diselesaikan (tanggung jawab user soal kuota akun), tapi UI harus kasih warning jelas kalau upload gagal karena kuota. |
| Kompleksitas auth+sync numpuk bareng bug player inti | Sudah dimitigasi lewat sequencing v1/v2 — cloud baru masuk setelah player teruji. |

## 10. Keputusan Final (referensi cepat)

- Package: `com.anandabint.beatfy`
- minSdk 24, target SDK Flutter stable terbaru
- Tema: dark-only
- State management: Riverpod
- Local storage: Hive (via `hive_ce`/`hive_ce_flutter` — lihat Architecture.md § 1)
- Audio engine: just_audio + audio_service
- Cloud (v2): Google Drive API, akun Google Sign-In milik user sendiri
- Trigger backup (v2): manual, tombol "Backup Sekarang" di Settings (direvisi 2026-08-07 dari rencana awal otomatis-saat-WiFi, lihat § 7 item 5 & Architecture.md § 4c)
- Restore (v2): full-download saat login pertama

## 11. Keputusan Tambahan (post-implementasi v1)

**Restore playback state — always paused (2026-08-06)**: Awalnya PRD § 6 menyebut status play/pause direstore "persis seperti terakhir" (termasuk auto-resume kalau terakhir playing). Setelah diimplementasikan dan diuji nyata, keputusan direvisi: posisi/queue tetap direstore akurat, tapi status selalu **paused** saat app dibuka kembali — mencegah audio auto-blast tak terduga (misal HP baru diambil dari kantong). User tap play manual untuk lanjut. Ini keputusan final Pann, berlaku untuk semua kasus (minimize maupun kill-app).

**Header greeting disederhanakan (2026-08-07)**: Header Home tidak lagi dua baris (teks "Selamat pagi/siang/malam" terpisah + nama). Sekarang satu baris saja: "Hi, [nama depan]" saat sudah sign-in Google. Saat belum/tidak sign-in, tampilkan fallback statis "Hi there" — bukan lagi fallback teks sapaan waktu, karena logic sapaan-waktu itu sendiri yang dihapus, bukan cuma disembunyikan.

**Notification tap → buka Now Playing (2026-08-07)**: Tap notification media playback (status bar/lock screen) harus langsung navigasi ke `NowPlayingScreen`, bukan cuma membuka app ke state terakhir/Home. Detail teknis di Architecture.md § 4a.

**Delete lagu dari device dimajukan sebagian dari v2 (2026-08-07)**: Item § 7.7 (hapus file asli via long-press) mulai dikerjakan bareng sesi polish ini, tidak menunggu urutan v2 penuh — karena menggantikan pola swipe-to-delete yang sudah ada, bukan fitur berdiri sendiri yang independen.

**Sign-in tidak boleh auto-prompt UI (2026-08-07)**: Ditemukan bug — app menampilkan popup/bottom-sheet Google sign-in otomatis tiap kali dibuka (kemungkinan dari Android Credential Manager), padahal user tidak menyentuh apapun. Ini melanggar prinsip UX yang diinginkan Pann: status login (sudah/belum) hanya boleh dibaca dari cache lokal (`UserProfileCache`) saat app dibuka — **tidak ada call ke Google yang bisa memunculkan UI apapun** kecuali user eksplisit tap tombol "Login dengan Google" (baik di Onboarding maupun di Settings). Berlaku permanen, bukan cuma untuk background/auto-backup context yang sudah difix sebelumnya.

**Performance gate sebelum rilis final (2026-08-07)**: Sebelum Beatfy dianggap final untuk dipakai sehari-hari, wajib ada sesi audit performa khusus (profile mode, DevTools) — target: tidak ada jank/frame-drop terasa di scroll manapun (Home/Library/Search/Playlist), transisi antar screen mulus, khususnya di layar dengan gradient blob (Home, Now Playing) yang berisiko berat. Ini gate kualitatif tambahan di luar § 8 Metric Keberhasilan yang sudah ada. **Termasuk**: app wajib render di refresh rate maksimum yang didukung device (device 120Hz → app jalan 120Hz, bukan default 60Hz) — pakai `flutter_displaymode`, lihat Architecture.md.

**Audio enhancement — best-effort, bukan janji pasti (2026-08-07)**: Fitur § 7.9 boleh disederhanakan/dibatalkan implementasinya kalau ternyata `just_audio`/ExoPlayer tidak expose audio session ID dengan cara yang stabil untuk dipasangi Android native audio effects — Claude Code wajib riset dan lapor feasibility dulu sebelum coding penuh, jangan paksa kalau ternyata butuh workaround berisiko (misal fork plugin).

**Sesi finalisasi terakhir (2026-08-08)** — ditambahkan setelah pemakaian harian beberapa hari di build production:

- Item baru: artwork fallback gradient dinamis (per-lagu, bukan warna seragam), ikon status backup per song row (reuse `CloudBackupRecord`, bukan konsep "streaming vs cached" — app ini tidak streaming dari cloud sama sekali), dynamic ambient color Now Playing dari dominant color artwork (`palette_generator`), verifikasi gapless playback, app icon custom, hardening rilis publik (lihat Architecture.md § 9).
- **Ditolak secara sadar, didokumentasikan supaya tidak diusulkan ulang tanpa alasan baru**: native `AUDIO_OUTPUT_FLAG_FAST`/`DEEP_BUFFER` via method channel, dan AutoEQ database + FIR filter per model headset kabel. Alasan lengkap di Architecture.md § 9a. Kalau Pann suatu saat ingin dorong ini beneran, itu scope terpisah besar (semacam "v3"), bukan polish akhir.
- Sesi ini eksplisit ditandai Pann sebagai **update terakhir** sebelum rilis — setelah ini, gate-nya bukan lagi "tambah fitur", tapi § 11 "Performance gate" + QC menyeluruh.
