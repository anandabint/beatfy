# Prompt untuk Claude Code — Sesi Final v2: Browse Album/Artist/Folder + Cloud Backup Google Drive

Baca ulang `docs/` sebelum mulai — hari ini diupdate: `PRD.md` § 7 item 5 (entry point Settings difinalisasi), `Architecture.md` § 7 (dua OAuth Client ID, publish ke Production), `Design.md` § 7 (3 row baru: Library grouping, Settings screen, Restore screen), `Schema.md` § 3 (`CloudBackupRecord`, typeId 5, sudah dialokasikan dari awal).

Google Sign-In sudah jalan dan `serverClientId` di `auth_service.dart` sudah terisi (dikonfirmasi Pann) — fondasi auth sudah ada, sesi ini tinggal bangun fitur di atasnya.

Kerjakan 2 fitur besar berikut, urut. Boleh dikerjakan sebagai 2 sesi terpisah kalau kepanjangan buat 1 sesi, tapi urutannya tetap: browse dulu (lebih sederhana, murni lokal), baru cloud backup (lebih kompleks, butuh device+jaringan asli buat QC).

## Bagian 1 — Browse by Album/Artist/Folder

Tambahan grouping di dalam Library tab, di atas list flat yang sudah ada. Referensi fungsi: `beatfy-main` lama punya rute `album/{albumId}`, `artist/{artistName}`, `folder/{folderPath}` — port fungsinya (bukan UI-nya, UI ikut Design.md baru).

1. Filter pill row Library: tambah 3 pill baru — "Albums" / "Artists" / "Folders" — di samping pill yang sudah ada (All/Playlists/Liked Songs/Downloads). Scroll horizontal kalau kepanjangan di 1 layar.
2. Data grouping: derive dari `songs` box yang sudah ada (field `album`, `artist`, `filePath` buat folder) — tidak perlu model Hive baru, cukup query/group di repository layer (`library_repository.dart`), jangan taruh logic grouping di widget.
3. Saat pill "Albums"/"Artists"/"Folders" aktif: list berubah jadi baris grup (art representatif — ambil artwork dari salah satu lagu di grup itu, circular sesuai Design.md § 5 — + nama grup + "X Lagu").
4. Tap satu baris grup → push ke detail screen (`album_detail_screen.dart`/`artist_detail_screen.dart`/`folder_detail_screen.dart` atau 1 screen generic reusable kalau strukturnya identik) — isinya list lagu di grup itu, reuse song row component biasa (termasuk long-press context menu yang sudah ada).
5. Folder grouping: derive dari direktori `filePath` (folder terakhir sebelum nama file), bukan dari MediaStore folder ID — pastikan konsisten sama cara lama.

## Bagian 2 — Cloud Backup Google Drive

Baca `Architecture.md` § 7 buat arsitektur high-level, `Schema.md` § 3 buat model `CloudBackupRecord` yang sudah dialokasikan (typeId 5, box `cloud_backup`).

### 2a. Settings screen (entry point)

- Tap avatar di header Home → push `SettingsScreen`.
- Isi: foto+nama+email dari `UserProfileCache` (atau tombol "Sign in with Google" kalau box kosong), toggle/status auto-backup, ringkasan status backup ("X dari Y lagu ter-backup"), tombol sign out (clear `UserProfileCache`, revoke Google Sign-In session).
- Style flat dark, konsisten Library/Search (tanpa gradient blob dekoratif — itu cuma buat Home & Now Playing sesuai Design.md § 11).

### 2b. Upload otomatis

- Package: `googleapis` (Drive API v3) + scope `drive.file` (sudah dikonfigurasi saat OAuth setup).
- Trigger: `connectivity_plus` listener — begitu status jadi `ConnectivityResult.wifi` DAN ada lagu dengan `CloudBackupRecord.backupStatus == pending` (atau belum punya record sama sekali = anggap pending), mulai upload antrian.
- Folder tujuan di Drive: buat folder "Beatfy Backup" di root Drive user (bukan `appDataFolder` tersembunyi — biar Pann bisa lihat langsung filenya di Drive-nya kalau perlu), cek dulu apakah folder sudah ada (simpan folder ID di local biar tidak query berulang).
- Update `CloudBackupRecord` tiap tahap: `pending` → `uploading` → `done` (simpan `driveFileId`) atau `failed` (simpan `lastAttemptAt`, retry logic sederhana: coba lagi di trigger WiFi berikutnya, jangan infinite-retry-loop tanpa jeda).
- Upload jangan blocking UI/playback — jalankan di background (isolate/compute kalau perlu buat file besar, atau cukup async biasa kalau `googleapis` client sudah non-blocking).

### 2c. Restore penuh (login pertama di device baru)

- Deteksi: `songs` box Hive kosong (device baru/abis reset) TAPI user berhasil sign-in dan ketemu folder "Beatfy Backup" berisi file di Drive-nya.
- Tampilkan `RestoreScreen` full-screen (tidak bisa di-skip) — progress bar + counter "X/Y file terdownload" — download semua file dari folder Drive ke local storage app (atau ke folder Music standar Android, sesuaikan dengan constraint scoped storage — kalau app-private storage lebih aman/simple secara permission, boleh pakai itu, tapi laporkan pilihannya ke saya karena ini keputusan yang mempengaruhi § Non-Hive Data di Schema.md).
- Setelah selesai, jalankan scan lokal biasa (`AudioQueryService.scan()`) supaya file yang baru didownload masuk ke `songs` box seperti lagu biasa.
- Kalau user sign-in tapi TIDAK ada folder backup di Drive-nya (akun baru/belum pernah backup) — skip restore screen, langsung masuk app normal seperti biasa.

## QC (device nyata, wajib — beda dari sesi-sesi kemarin)

Fitur ini butuh koneksi internet asli, jadi checklist `Rules.md` § 4 standar TIDAK cukup — tambahan wajib:

- [ ] Sign in Google di device asli, konfirmasi tidak error/stuck.
- [ ] Sambungkan WiFi, tunggu, konfirmasi upload beneran jalan (cek file muncul di Drive lewat browser/app Drive, bukan cuma status "done" di app).
- [ ] Matikan WiFi di tengah upload, konfirmasi tidak crash, status balik ke `pending`/`failed` dengan benar, lanjut lagi saat WiFi nyala lagi.
- [ ] Kalau memungkinkan tanpa reset device beneran: simulasikan restore dengan uninstall+reinstall app (Hive lokal otomatis kosong lagi karena app data ke-clear), sign in ulang, konfirmasi restore screen muncul dan file benar-benar terdownload dan bisa diputar.
- [ ] Cek `adb logcat` selama seluruh proses di atas.

Laporkan di akhir sesi: pendekatan storage yang dipakai buat file hasil restore (app-private vs public Music folder), dan kalau ada blocker dari sisi quota/permission Drive yang perlu Pann tahu.
