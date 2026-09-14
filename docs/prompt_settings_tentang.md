?# Prompt Claude Code  Section "Tentang" di Settings (Sebelum Finalisasi)

Baca `Design.md` § 7 row "Section 'Tentang' (Settings)" dan `PRD.md` § 7 item 10 sebelum mulai. Tujuan: bikin Settings terasa resmi/profesional dan privasi jelas ke user  ini persiapan sebelum sesi finalisasi.

Tambahkan section baru di bagian bawah `SettingsScreen` (di bawah section account/backup yang sudah ada), style list item sederhana (icon kiri + label + chevron kanan, bukan card besar):

## 1. App info

Tambahkan package `package_info_plus`. Tampilkan icon app + "Beatfy" + versi dinamis, format `"v${info.version} (${info.buildNumber})"`  jangan hardcode angka versi di widget, selalu baca dari `PackageInfo.fromPlatform()`.

## 2. Developer

Baris statis: "Developer" → "Ananda Bintang Ramadhan".

## 3. Laporkan Bug / Masukan

Tambahkan package `url_launcher` (kalau belum ada). Baris "Laporkan Bug / Masukan"  tap membuka email client lewat `mailto:anandabramadhan@gmail.com?subject=Beatfy%20-%20Feedback`. Handle kasus tidak ada email client terpasang (`canLaunchUrl` check, snackbar fallback kalau gagal, jangan crash).

## 4. Privasi

Baris "Privasi"  tap buka bottom sheet atau dialog (bukan halaman/route terpisah, cukup ringan) berisi teks ini persis (boleh dirapikan formatting-nya, jangan ubah maknanya):

> "Beatfy tidak mengumpulkan data pengguna, tidak ada iklan atau analytics pihak ketiga. Satu-satunya data yang keluar dari perangkat adalah file musik yang di-backup ke Google Drive akun kamu sendiri, hanya kalau fitur backup diaktifkan  Beatfy tidak punya server sendiri yang menyimpan data apapun."

## 5. Lisensi Open Source

Baris "Lisensi Open Source"  tap panggil `showLicensePage(context: context, applicationName: 'Beatfy', applicationVersion: info.version)` (bawaan Flutter, `LicenseRegistry` otomatis collect semua lisensi package dependency, tidak perlu maintain manual).

## QC

Tidak perlu checklist device penuh  cukup: build sukses, `flutter analyze` bersih, cek versi yang tampil beneran cocok sama `pubspec.yaml` (bukan angka ngasal), cek tombol email + lisensi beneran kebuka saat ditest sekali di device/emulator.
