# Setup Google Cloud Console — Cloud Backup (Wajib Dilakukan Manual oleh Pann)

Ini bagian yang tidak bisa saya/Claude Code kerjakan — perlu login akun Google situ sendiri. Ikuti urut, kirim hasilnya ke saya/Claude Code setelah selesai.

## 1. Buat project + enable Drive API

1. Buka `console.cloud.google.com`, login pakai akun Google yang mau dipakai buat backup MP3.
2. Buat project baru, nama bebas (saran: "Beatfy").
3. Menu **APIs & Services → Library** → cari "Google Drive API" → **Enable**.

## 2. OAuth consent screen

1. **APIs & Services → OAuth consent screen**.
2. User Type: **External**.
3. App name: "Beatfy". Support email + developer contact email: `arifandixx@gmail.com`.
4. Scopes: tambahkan `https://www.googleapis.com/auth/drive.file` (bukan full Drive access — cuma file yang dibuat app sendiri, sesuai Architecture.md § 7).
5. **Penting**: setelah selesai isi form, klik **Publish App** (pindah dari status "Testing" ke "Production"). Kalau dibiarkan di "Testing", refresh token expired tiap 7 hari — artinya harus login ulang tiap minggu, ganggu buat auto-backup harian. `drive.file` termasuk scope "sensitive" bukan "restricted", jadi publish tidak butuh proses verifikasi Google yang lama — cuma nanti pas login pertama situ bakal lihat warning "Google hasn't verified this app", klik **Advanced → Go to Beatfy (unsafe)** buat lanjut. Aman, itu app situ sendiri.

## 3. Buat 2 OAuth Client ID (bukan cuma 1)

**Credentials → Create Credentials → OAuth client ID**, buat DUA:

**a. Tipe "Web application"** (ini yang dipakai di kode, buat `serverClientId`):
- Nama bebas, misal "Beatfy Web Client".
- Authorized redirect URI boleh kosong/skip kalau tidak diminta wajib.
- Setelah dibuat, **copy Client ID-nya** (bentuknya `xxxxx.apps.googleusercontent.com`) — ini yang saya/Claude Code perlu buat isi `TODO(Pann)` di `auth_service.dart`.

**b. Tipe "Android"** (ini bukan buat di-input ke kode, tapi wajib ada supaya Google verifikasi signature app):
- Package name: `com.anandabint.beatfy`
- SHA-1 certificate fingerprint: dari debug keystore. Jalankan di PowerShell:
  ```
  keytool -list -v -keystore $env:USERPROFILE\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
  ```
  Cari baris `SHA1:`, copy nilainya, paste ke form Google Cloud Console.

## 4. Kirim ke saya

Setelah selesai, kirim **Client ID dari Web application (poin 3a)** — itu satu-satunya value yang perlu masuk ke kode. Client ID Android tidak perlu dikirim, dia cuma perlu ada dan cocok di Google Cloud Console.

Kalau nanti ganti ke release keystore (bukan debug) buat rilis beneran, harus tambah Client ID Android baru lagi dengan SHA-1 dari release keystore — dicatat sebagai reminder buat nanti, belum relevan sekarang.
