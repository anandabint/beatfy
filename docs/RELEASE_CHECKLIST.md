# Release Checklist — Beatfy (jalankan sendiri di PowerShell, saya tidak bisa eksekusi ini dari sandbox saya)

## 0. Prasyarat — pastikan ini sudah beres

- [ ] Prompt terakhir (`prompt_fix_shell_scaffold_planly.md`) sudah dijalankan Claude Code dan diverifikasi di device — kalau belum, kerjakan itu dulu sebelum lanjut. Build final harus dari kode yang sudah final, bukan yang masih ada bug MiniPlayer/Search yang diketahui.
- [ ] Semua perubahan dari sesi-sesi sebelumnya (audio, hardening, dst) sudah di-review, belum ada yang di-commit menurut laporan terakhir Claude Code.

## 1. Generate release keystore (kalau belum ada)

```powershell
cd android/app
keytool -genkey -v -keystore release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias beatfy
```

Ikuti prompt-nya (isi passphrase — **catat baik-baik, jangan sampai lupa**, tidak ada cara recover kalau hilang). Jangan taruh `release-key.jks` di folder yang ke-track git.

## 2. Isi `android/key.properties`

Buat file ini (kalau Claude Code belum buatkan template-nya) dengan isi:

```
storePassword=<passphrase yang tadi>
keyPassword=<passphrase yang tadi>
keyAlias=beatfy
storeFile=release-key.jks
```

Pastikan file ini masuk `.gitignore` (cek dulu, jangan sampai ke-commit).

## 3. Build release APK

```powershell
flutter clean
flutter pub get
flutter build apk --release
```

Output ada di `build\app\outputs\flutter-apk\app-release.apk`.

## 4. WAJIB test APK release ini di device — bukan cuma build debug/profile

Release build pakai minification (R8/ProGuard) yang bisa munculin bug BARU yang tidak ada di semua testing sebelumnya (biasanya seputar reflection — Hive adapter, dsb). Install manual:

```powershell
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

Test cepat tapi cakup semua area kritis: buka app, scan library, play lagu, minimize→buka lagi (posisi tidak reset), sign-in Google, backup manual, buka Now Playing, cek semua 4 tab. Kalau ada yang crash/beda dari build debug, itu bug baru khusus release — jangan diabaikan.

## 5. Generate SHA-256 fingerprint (buat README)

```powershell
keytool -list -v -keystore android/app/release-key.jks -alias beatfy
```

Cari baris `SHA256:`, copy ke bagian README yang sudah disiapkan Claude Code.

## 6. Push ke GitHub

Kalau repo GitHub belum dibuat: buat repo baru (public) di github.com dulu, jangan initialize dengan README (biar tidak konflik dengan yang sudah ada).

```powershell
cd <folder-project-beatfy>
git add .
git commit -m "chore: release v1.0.0"
git remote add origin https://github.com/<username>/<nama-repo>.git
git branch -M main
git push -u origin main
```

Kalau remote sudah ada sebelumnya, skip `git remote add`, langsung `git push`.

## 7. (Opsional, disarankan) Buat GitHub Release + attach APK

Di halaman repo GitHub → Releases → Draft a new release → upload `app-release.apk` sebagai asset. Ini penting supaya user lain bisa **download APK jadi langsung**, tidak perlu build sendiri dari source — jauh lebih ramah buat non-developer yang mau install Beatfy.

## 8. Terakhir — cek ulang tidak ada yang bocor

```powershell
git log --all --full-history -- "*.jks" "*.keystore" "key.properties"
```

Kalau command ini nampilin sesuatu, ada file sensitif yang pernah ke-commit di history — lapor ke saya sebelum push, jangan langsung push kalau ketemu.
