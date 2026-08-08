# Prompt Claude Code — Build Release + Push GitHub (Eksekusi Penuh)

Pann sudah generate `android/app/release-key.jks` manual (keytool, alias `beatfy`). Repo GitHub baru sudah dibuat, kosong: `https://github.com/anandabint/beatfy.git`. Kerjakan seluruh alur ini sendiri lewat terminal — jangan minta Pann jalankan manual lagi kecuali memang butuh input dari Pann (password keystore, konfirmasi sebelum push).

Urutan wajib, jangan skip/reorder:

## 0. Pastikan sesi sebelumnya sudah beres

Cek `prompt_fix_shell_scaffold_planly.md` sudah dieksekusi (MainShell pakai `Scaffold.bottomNavigationBar` + `extendBody`, bukan `Column` manual). Kalau belum, kerjakan itu DULU, verifikasi di device, baru lanjut ke bawah — jangan build release dari kode yang masih ada bug yang sudah diketahui.

## 1. Setup `android/key.properties`

File ini belum ada isinya (cuma template dari sesi hardening kemarin). **Tanya Pann langsung di terminal/chat untuk passphrase keystore** (yang tadi diinput saat `keytool -genkey`) — jangan asumsi/tebak, dan jangan pernah tulis passphrase itu ke file log/laporan/commit manapun. Isi:

```
storePassword=<dari Pann>
keyPassword=<dari Pann>
keyAlias=beatfy
storeFile=release-key.jks
```

Pastikan `android/key.properties` dan `android/app/release-key.jks` ada di `.gitignore` — cek dulu sebelum lanjut, kalau belum ada tambahkan.

## 2. Build release APK

```
flutter clean
flutter pub get
flutter build apk --release
```

Kalau build gagal (error signing config/R8/minify), diagnosis dan fix — jangan lapor "gagal" begitu saja, cari akar masalahnya dulu.

## 3. Test APK release di device nyata Pann (WAJIB, beda dari debug/profile)

```
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

Test manual cakupan minimal: buka app (onboarding kalau fresh install), scan library, play lagu, minimize→buka lagi (posisi tidak reset), sign-in Google, tap "Backup Sekarang", buka Now Playing (cek slider, dynamic color), semua 4 tab + grouping Album/Artist/Folder, long-press context menu. Release build pakai minification — kalau ada crash/behavior beda dari build sebelumnya, itu bug baru khusus release, cari dan fix sebelum lanjut ke langkah berikut. Cek `adb logcat` selama testing.

## 4. Generate SHA-256 fingerprint, lengkapi README

```
keytool -list -v -keystore android/app/release-key.jks -alias beatfy
```

Ambil baris `SHA256:`, masukkan ke bagian README yang sudah disiapkan sesi hardening kemarin (placeholder fingerprint).

## 5. Audit final sebelum push — ulangi, jangan percaya audit lama

```
git log --all --full-history -- "*.jks" "*.keystore" "key.properties"
git status
```

Pastikan tidak ada file sensitif ke-track (`release-key.jks`, `key.properties`, `debug.keystore` kalau ada). Kalau `git status` nunjukin file-file itu sebagai "untracked" itu OK (berarti memang di-gitignore dan belum pernah ke-add) — yang masalah kalau muncul di `git log` history atau `git status` sebagai "staged"/"tracked".

## 6. Commit & push ke GitHub

```
git init   # kalau belum pernah di-init
git add .
git commit -m "chore: release v1.0.0 — Beatfy offline music player"
git remote add origin https://github.com/anandabint/beatfy.git
git branch -M main
git push -u origin main
```

Kalau remote `origin` sudah pernah di-set sebelumnya ke URL lain, update dulu (`git remote set-url origin https://github.com/anandabint/beatfy.git`) sebelum push. Kalau push gagal karena auth, minta Pann login lewat `gh auth login` atau kasih tau apa yang perlu Pann lakukan — jangan coba simpan/handle credential GitHub apapun sendiri.

## 7. GitHub Release + attach APK (kalau `gh` CLI tersedia)

```
gh release create v1.0.0 build\app\outputs\flutter-apk\app-release.apk --title "Beatfy v1.0.0" --notes "Rilis pertama Beatfy — offline music player."
```

Kalau `gh` tidak terinstall/tidak login, skip langkah ini dan kasih tau Pann untuk upload manual APK-nya ke GitHub Releases lewat web (Releases → Draft new release → upload `app-release.apk` sebagai asset) — jangan install/setup `gh` CLI sendiri tanpa Pann tahu.

## Laporan akhir

Wajib laporkan: apakah semua langkah di atas sukses sampai push, link commit/release GitHub kalau berhasil, dan detail apapun yang butuh tindakan manual Pann (misal step 7 kalau `gh` tidak tersedia).
