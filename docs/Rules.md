# Rules — Beatfy

Aturan kerja untuk Claude Code (eksekutor) dan alur kolaborasi dengan Pann (mandor). Dibaca di awal **setiap sesi**, sebelum menyentuh kode.

## 1. Rantai Komando

- **Claude (chat ini)**: olah logika/plan, generate prompt vibe-coding untuk Claude Code, tidak menulis kode Flutter langsung.
- **Claude Code (VSCode)**: eksekutor kode. Baca 5 dokumen di `docs/` sebagai konteks wajib sebelum implementasi apapun.
- **Pann**: approve/reject keputusan, jalankan/copas prompt, sumber kebenaran final kalau ada konflik antar dokumen.

Kalau Claude Code menemukan keputusan di luar cakupan 5 dokumen ini (ambiguous case), **berhenti dan tanya**, jangan asumsi sepihak.

## 2. Definition of Done (berlaku tiap task/sesi)

Sebuah task **tidak selesai** sampai:

1. Build sukses tanpa warning baru yang relevan (`flutter analyze` bersih untuk file yang disentuh).
2. Ter-install dan dites di device fisik Pann via `adb` — bukan cuma "seharusnya jalan" dari baca kode.
3. `adb logcat` dicek selama testing manual — tidak ada crash/exception baru yang muncul akibat perubahan.
4. Skenario kritis terkait area yang diubah dites manual (lihat § 4 checklist QC).
5. Kalau ditemukan bug **apapun** selama testing — walau di luar scope task saat itu — wajib diperbaiki dulu atau minimal dilaporkan eksplisit ke Pann dengan tingkat urgensi, bukan diabaikan/dilewati diam-diam.

## 3. Prioritas Kualitas (urutan, kalau harus trade-off)

1. Playback tidak pernah glitch/reset posisi.
2. Tidak crash.
3. **Kualitas output audio setara aplikasi besar (YouTube/Spotify/Telegram)** — tidak memendam di Bluetooth manapun, volume+bass sepadan di speaker internal, tanpa perlu konfigurasi apapun dari user. Ditambahkan 2026-08-08 setelah ditemukan gap nyata — ini bukan "nice to have", ini inti value sebuah music player.
4. UI smooth (60fps/refresh rate device terasa, tidak ada jank saat scroll/transisi).
5. Sesuai Design.md (visual konsisten).
6. Fitur lengkap sesuai PRD scope.

Kalau harus pilih antara "fitur baru selesai cepat tapi ada rasa tidak smooth" vs "fitur mundur tapi playback+UI sempurna" — pilih yang kedua. Ini prinsip eksplisit dari Pann: minimalist tapi powerful, bukan buru-buru lengkap.

## 4. Checklist QC Wajib per Sesi (device nyata via adb)

- [ ] `adb devices` — konfirmasi device Pann terdeteksi sebelum mulai.
- [ ] `flutter run` atau `adb install` build terbaru ke device.
- [ ] Play lagu → minimize app (home button) → buka lagi → posisi & status playback harus identik.
- [ ] Play lagu → kill app dari recent apps (bukan cuma minimize) → buka lagi → queue & posisi harus ter-restore dari Hive.
- [ ] Sambungkan/putuskan Bluetooth audio saat sedang playing → auto-pause saat disconnect harus terjadi.
- [ ] Navigasi antar screen yang disentuh sesi ini → rasakan langsung ada jank/patah atau tidak (bukan cuma lihat kode).
- [ ] Cek `adb logcat` untuk exception/ANR selama seluruh proses testing di atas.
- [ ] Screenshot (`adb shell screencap`) untuk perubahan UI signifikan, lampirkan/rujuk di ringkasan sesi ke Pann.
- [ ] **(2026-08-07, wajib sampai lolos)** Scroll Library tab langsung di device nyata, perhatikan warna overscroll glow di ujung atas/bawah — sesi sebelumnya "fix" ini tanpa akses device dan Pann konfirmasi masih coklat/olive di device asli. Jangan tandai selesai hanya dari baca kode/`flutter analyze` bersih.
- [ ] Kalau ada fitur delete file asli (PRD § 7.7): test di lagu yang **benar-benar boleh hilang** (bukan lagu penting Pann) dulu sebelum dianggap lolos QC — sifatnya permanen/tidak bisa di-undo.

## 5. Konvensi Kode

- Ikuti `flutter_lints` (sudah jadi dev dependency standar, sama seperti Planly) — tidak ada rule di-disable tanpa alasan tertulis di komentar.
- Nama file: `snake_case.dart`. Nama class: `PascalCase`. Provider: akhiran `Provider` (`libraryProvider`, `playbackStateProvider`).
- Satu file = satu tanggung jawab jelas. Widget besar dipecah, bukan satu file 500+ baris.
- Tidak ada logic bisnis di `build()` method widget — pindah ke provider/repository (lihat Architecture.md § 2).
- Semua akses Hive lewat repository, tidak pernah widget/provider baca box Hive langsung.
- Komentar Dart doc (`///`) untuk public method di repository/service — bukan untuk hal yang sudah jelas dari nama.

## 6. Git & Commit

- Commit kecil, per unit kerja logis — bukan satu commit raksasa per sesi.
- Format pesan commit: Conventional Commits (`feat:`, `fix:`, `refactor:`, `chore:`) + subjek jelas dalam bahasa Indonesia atau Inggris konsisten (pilih satu, sarankan Inggris untuk konsistensi tooling).
- Tidak commit file build/generated (`*.g.dart` hasil build_runner boleh commit — konsisten dengan Planly — tapi `build/`, `.dart_tool/` tidak).
- `keystore.properties`/credential apapun **tidak pernah** commit (sama aturan seperti README versi lama).

## 7. Permission & Android Manifest

- Runtime permission diminta dengan konteks jelas (bukan saat app pertama buka langsung minta semua) — minta `READ_MEDIA_AUDIO` saat proses scan library dijalankan pertama kali, minta notification permission saat foreground service pertama kali mau start.
- Foreground service untuk playback wajib pakai `mediaPlayback` type (Android 14+ requirement) — bukan generic foreground service, supaya tidak kena restriction OS.

## 8. Kapan Boleh Berimprovisasi vs Wajib Tanya

**Boleh improvisasi tanpa tanya**: pilihan implementasi detail yang tidak mengubah keputusan di PRD/Architecture/Design/Schema (misal: nama variabel, struktur internal satu file, urutan helper function).

**Wajib tanya/lapor dulu**: ganti package/library inti dari yang sudah ditetapkan di Architecture.md, ubah struktur Hive/typeId di Schema.md, ubah scope v1/v2 di PRD.md, ubah token warna/tipografi di Design.md, atau keputusan apapun yang berdampak ke pengalaman pakai harian Pann.

## 9. Update Dokumen

Kalau selama implementasi ternyata ada bagian dari 5 dokumen ini yang perlu direvisi (karena ternyata tidak feasible/ada cara lebih baik), **dokumen diupdate dulu** (dengan alasan tertulis) sebelum kode ditulis mengikuti perubahan itu — dokumen tidak boleh basi/tidak sinkron dengan kode aktual.
