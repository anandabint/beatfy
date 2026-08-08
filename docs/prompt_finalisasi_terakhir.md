# Prompt Claude Code — Sesi Finalisasi Terakhir (2026-08-08)

Pann sudah pakai build production beberapa hari dan menandai ini sebagai **sesi update terakhir sebelum rilis**. Baca dulu bagian yang diupdate hari ini: `PRD.md` § 11 (keputusan sesi finalisasi + item yang sengaja ditolak), `Architecture.md` § 7b (polish teknis), § 7c (**BARU, KRITIS** — kualitas output audio), § 9 (hardening rilis publik), § 9a (2 usulan yang ditolak + alasan — jangan diimplementasikan), `Design.md` § 7 (4 row baru/revisi), `Rules.md` § 3 (prioritas kualitas direvisi, kualitas audio sekarang setara prioritas #3, di atas UI smoothness).

Kerjakan urut — **item 0 di bawah ini didahulukan dari semua item lain**, termasuk dari 8 item yang sudah ada sebelumnya di prompt ini. Kalau waktu terbatas, item 0 tidak boleh dikorbankan demi item lain.

## 0. [PRIORITAS TERTINGGI] Kualitas output audio — Bluetooth memendam + volume/bas lemah di speaker

Baca `Architecture.md` § 7c untuk detail lengkap. Ringkas:

**Bluetooth memendam** (di headset manapun): kemungkinan besar audio session tidak eksplisit set `AndroidAudioAttributes` ke `usage: media` + `contentType: music`, menyebabkan Android/Bluetooth stack kadang rute lewat profil suara panggilan (SCO/HFP, mono narrowband) bukan profil media (A2DP, stereo full-bandwidth) — persis gejala "memendam" yang dilaporkan. Cek & perbaiki konfigurasi ini di `audio_handler.dart`/`AudioService.init()`. Verifikasi dengan dengar langsung di headset Bluetooth Pann — harus jernih/full-bandwidth, bukan seperti suara telepon.

**Volume/bas lemah di speaker dibanding YouTube/Telegram, walau volume sudah maksimal**:
1. Audit slider volume custom (dibuat sesi sebelumnya) — pastikan itu kontrol **volume sistem asli** (`AudioManager.STREAM_MUSIC`), bukan cuma `AudioPlayer.setVolume()` (gain software yang mentok di level rekaman asli, tidak bisa melebihi itu). Kalau ternyata cuma software gain, ini kemungkinan besar salah satu penyebab utama.
2. Konfirmasi status nyata Audio Enhancement (`LoudnessEnhancer`/`BassBoost` dari sesi audio enhancement sebelumnya) — apakah benar-benar aktif ter-attach saat playback (bukan cuma ter-kode tapi gagal diam-diam). Kalau aktif tapi presetnya terlalu konservatif, **naikkan intensitasnya** (loudness + bass boost lebih terasa) sampai sepadan dengan app pembanding saat didengar langsung — tetap jaga jangan sampai distorsi di file bitrate rendah.

**QC wajib khusus item ini**: dengar langsung perbandingan A/B — putar lagu yang sama di Beatfy vs YouTube Music/aplikasi pemutar musik lain di speaker device yang sama, volume sistem sama, konfirmasi levelnya sekarang sepadan (tidak harus identik persis, tapi tidak boleh terasa jomplang seperti sekarang). Sama juga untuk Bluetooth — pasang headset yang sama, bandingkan kejernihan.

## 1. Slider sensitivity (volume + progress)

Bug: setelah thumb dihilangkan sesi sebelumnya, slider jadi sulit di-drag presisi — user harus sangat tepat menyentuh area kecil. Fix: perbesar area sentuh interaktif TANPA memunculkan bulatan/thumb visual lagi (itu tetap dipertahankan). Pendekatan: pastikan `Slider`/`SliderTheme` punya tinggi hit-area yang nyaman (bungkus dengan `SizedBox(height: ~44-48)` kalau perlu), naikkan `trackHeight` sedikit dari yang sekarang (supaya target visual+sentuh lebih jelas, coba mulai dari 6-8px lalu adjust berdasar rasa), dan pastikan Slider mengisi lebar penuh yang tersedia (tidak ada padding horizontal yang mencuri area drag). Test dengan drag jari asli di device, bukan cuma lihat kode — sensitivitas ini soal rasa, bukan cuma angka benar/salah.

## 2. Fix gap kosong di Search saat keyboard muncul

Repro (lihat screenshot Pann): buka Search, ketik, keyboard muncul — ada ruang kosong antara list hasil pencarian dan keyboard, seharusnya list nempel langsung ke keyboard. Dugaan kuat: list hasil search punya bottom padding yang dicadangkan buat bottom-nav/mini-player (supaya konten tidak ketutup nav pill saat normal), tapi padding itu tidak collapse saat keyboard muncul (padahal nav-nya sendiri sudah ketutup keyboard, jadi paddingnya jadi ruang kosong tak berguna). Fix: buat padding bawah list itu dinamis — kecilkan/hilangkan saat `MediaQuery.of(context).viewInsets.bottom > 0` (keyboard terbuka).

## 3. Artwork fallback gradient dinamis (ganti hijau seragam)

Baca `Architecture.md` § 7b. Bikin satu widget/helper reusable yang generate gradient dari hash string (judul+artis lagu) → mapping ke palet gradient yang dikurasi (beberapa pasangan warna yang cocok tema gelap `#141414` + aksen lime, BUKAN hue acak penuh spektrum yang bisa jadi norak/tidak match tema). Terapkan di SEMUA tempat art dirender: song row (Home/Search/Library/Playlist), Now Playing, mini player, playlist cover — pastikan lagu berbeda dapat gradient berbeda (bukan berulang ke warna sama untuk semua lagu tanpa artwork, itu bug yang dilaporkan Pann).

## 4. Ikon status backup per song row

Ikon kecil subtle (cloud-check kalau `CloudBackupRecord.backupStatus == BackupStatus.done`, kosong/cloud-outline tipis kalau belum) di song row. Data sudah ada dari fitur backup sebelumnya, ini murni tambahan visual — jangan bikin row jadi ramai, kecil dan halus saja.

## 5. Dynamic ambient color Now Playing

Tambah package `palette_generator`. Saat lagu diputar, ekstrak dominant color dari artwork-nya (kalau ada artwork — kalau fallback gradient dari poin 3 yang dipakai, skip ekstraksi, langsung pakai default blob ungu-pink). Ganti warna blob background Now Playing (yang sekarang statis ungu-pink) jadi mengikuti warna dominan itu. Cache hasil ekstraksi di memory per `songId` (tidak perlu Hive) biar tidak re-compute berulang untuk lagu yang sama dalam satu sesi. Fallback ke ungu-pink default kalau ekstraksi gagal/error — jangan sampai crash atau blank kalau `palette_generator` gagal proses gambar tertentu.

## 6. Verifikasi gapless playback

Cek `queue_manager.dart` — pastikan queue memakai `ConcatenatingAudioSource` (atau API setara di versi `just_audio` yang dipakai) secara konsisten untuk semua lagu, tanpa membedakan asal lagu (lokal asli vs hasil restore Drive — di titik playback keduanya sama-sama file lokal, tidak perlu logic beda). Test dengar langsung pergantian lagu di device (skip antar lagu di dalam 1 playlist/queue), pastikan tidak ada jeda/klik terdengar. Kalau ternyata sudah gapless dari implementasi sebelumnya, cukup konfirmasi di laporan — tidak perlu ubah apapun.

## 7. App icon custom

File `logo.png` sudah saya taruh di `assets/icon/logo.png` (1254×1254, RGB tanpa alpha). Tambah package `flutter_launcher_icons`, konfigurasi di `pubspec.yaml` untuk generate adaptive icon (Android 8+) dan legacy icon dari file ini, jalankan generator, ganti icon default Flutter yang masih terpasang.

## 8. Hardening rilis publik (baca Architecture.md § 9)

Beatfy akan di-hosting di GitHub untuk diinstall orang lain. Checklist:

- Audit seluruh repo: pastikan tidak ada yang ke-commit selain OAuth **Client ID** (public-safe) — cek tidak ada Client Secret, API key lain, `keystore.properties`, file `.jks`/`.keystore` ter-commit. Kalau ketemu, hapus dari tracking (dan history kalau memungkinkan, tapi itu di luar scope kalau butuh rewrite history — cukup laporkan ke Pann kalau ketemu di history lama).
- Setup **release keystore** asli (bukan debug keystore) untuk build APK yang didistribusikan — buat kalau belum ada, jangan commit file keystore-nya sendiri, cuma catat cara generate-nya.
- Generate SHA-256 fingerprint dari APK release, siapkan teks buat README (isinya nanti Pann lengkapi sendiri, cukup siapkan command/hasil fingerprint-nya).
- **JANGAN implementasikan** 2 hal di `Architecture.md` § 9a (native AudioTrack flag custom, AutoEQ+FIR per headset) — itu sengaja ditolak, dokumentasikan alasannya kalau ditanya, jangan dikerjakan.

## QC

Device nyata wajib untuk: item 1 (rasa drag slider), item 2 (visual keyboard), item 3-4 (visual, screenshot beberapa lagu berbeda buktikan gradient/ikon beda-beda sesuai datanya), item 5 (dengar+lihat warna berubah antar lagu), item 6 (dengar transisi lagu). Item 7-8 cukup verifikasi build sukses + `flutter analyze` bersih, tidak perlu uji visual khusus.

Laporkan di akhir: hasil audit secret (ketemu apa tidak), dan kalau ada yang dari 8 poin ini ternyata tidak bisa selesai sepenuhnya, sebutkan eksplisit apa yang masih kurang — ini sesi terakhir sebelum Pann anggap final, jangan ada yang "sepertinya sudah" tanpa diverifikasi.
