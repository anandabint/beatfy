# Prompt Claude Code — Fix: Auto-Backup Tidak Pernah Jalan (0 dari 17 Lagu)

Bug: Pann sudah login Google, WiFi connect, akses Drive dikonfirmasi granted — tapi Settings tetap nunjuk "0 dari 17 lagu ter-backup", dan dicek langsung di Google Drive, folder "Beatfy Backup" **tidak ada sama sekali**. Auto-backup tidak pernah benar-benar jalan, bukan cuma masalah tampilan angka.

Cek 3 hipotesis ini urut, jangan cuma tebak satu terus berhenti:

## 1. Lagu existing tidak punya `CloudBackupRecord`

Kalau query buat nentuin "lagu mana yang perlu di-backup" cuma baca box `cloud_backup` langsung (bukan iterasi semua `songs` lalu cek satu-satu apakah punya record atau belum), maka 17 lagu yang sudah ada dari sebelum fitur ini dibuat tidak akan pernah masuk antrian — box `cloud_backup` masih kosong dari awal, tidak ada yang di-loop. Perbaiki logic supaya "belum punya record" dianggap `pending` (sesuai spek asli), pastikan itu benar-benar diimplementasikan sebagai loop atas `songs`, bukan cuma baca `cloud_backup` box kosong.

## 2. Trigger WiFi cuma dengar "perubahan", bukan cek status sekarang

Cek apakah listener connectivity cuma pakai `onConnectivityChanged` stream tanpa ada pengecekan status SAAT INI (`Connectivity().checkConnectivity()`) di titik app start / provider initialization. Kalau WiFi Pann sudah nyambung SEBELUM buka app, tidak ada "perubahan status" yang terjadi, jadi trigger tidak pernah nyala. Tambahkan pengecekan status awal, bukan cuma listen ke perubahan.

## 3. `connectivity_plus` return type mismatch

Cek versi `connectivity_plus` di `pubspec.yaml`. Versi 5.0+ mengubah return type jadi `List<ConnectivityResult>` (bukan `ConnectivityResult` tunggal seperti versi lama). Kalau kode masih bandingin langsung `result == ConnectivityResult.wifi`, itu akan selalu `false` untuk versi baru (harus `result.contains(ConnectivityResult.wifi)`), gagal diam-diam tanpa exception yang kelihatan.

## Setelah fix

Tambahkan logging sementara (`debugPrint`/`log`) di titik-titik kunci alur backup (trigger terpicu, jumlah lagu masuk antrian, tiap upload mulai/selesai/gagal) supaya kalau ada masalah lagi ke depan, gampang di-diagnosis dari `adb logcat` tanpa harus buka Drive manual tiap kali.

## QC — wajib device+internet asli kali ini (beda dari sesi kemarin)

- Build & install, konfirmasi 17 lagu existing Pann langsung masuk antrian backup begitu WiFi aktif (tanpa perlu restart app kalau memungkinkan, minimal begitu app dibuka dengan WiFi sudah aktif).
- Tunggu sampai selesai, buka Google Drive Pann langsung (browser/app), konfirmasi folder "Beatfy Backup" muncul dan berisi file — jangan cuma percaya angka di Settings.
- Cek Settings menunjukkan "17 dari 17" setelah proses selesai.
- Cek `adb logcat` selama proses, pastikan tidak ada exception yang sebelumnya ke-swallow diam-diam.

Laporkan hipotesis mana dari 3 di atas yang benar-benar jadi penyebabnya (bisa lebih dari satu).
