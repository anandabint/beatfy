# Prompt Claude Code — Tambah Splash Screen, Lanjut Release Flow

Sebelum push ke GitHub (lanjutan dari `prompt_release_final_push.md` — status terakhir: build+test release APK selesai, commit/push belum jalan), Pann minta satu tambahan: splash screen native. File gambar sudah saya siapkan di `assets/splash/splash_screen.png` (1254×1254, RGB).

## Catatan update (setelah screenshot Pann)

`assets/splash/splash_screen.png` sudah saya proses ulang — background hitam solid di file PNG-nya sudah dihapus (diganti alpha channel berbasis luminance), jadi cuma logo putih+titik hijau yang render, tanpa kotak/rounded-rect hitam sendiri. Tidak perlu edit gambar lagi, langsung lanjut generate splash seperti biasa (`dart run flutter_native_splash:create`) — sekarang harusnya menyatu sempurna ke background `#141414` tanpa terlihat seperti gambar ditempel.

## 1. Implementasi splash screen

Pakai package `flutter_native_splash` (standar, generate splash native Android dari config, bukan widget Flutter custom yang keliatan delay/flash). Baca `Design.md` § 7 "Splash screen" untuk spec:

1. Tambah `flutter_native_splash` ke `dev_dependencies` di `pubspec.yaml`.
2. Konfigurasi (`flutter_native_splash.yaml` atau section di `pubspec.yaml`):
   ```yaml
   flutter_native_splash:
     color: "#141414"
     image: assets/splash/splash_screen.png
     android_12:
       color: "#141414"
       image: assets/splash/splash_screen.png
   ```
3. Jalankan generator: `dart run flutter_native_splash:create`.
4. **Penting**: default Android splash background sering putih kalau tidak di-override dengan benar — verifikasi visual di device, pastikan TIDAK ada flash putih sekilas sebelum splash gambar muncul (transisi cold-start harus langsung ke `#141414`, bukan putih→gelap).
5. Cek juga splash tidak konflik dengan flow Onboarding (splash native muncul duluan sebentar saat app benar-benar cold-start, BARU habis itu baca `AppPreferences.hasSeenOnboarding` buat nentuin ke Onboarding atau langsung MainShell — splash bukan pengganti Onboarding, ini beda lapisan, splash cuma nutup loading time app init).

## 2. Lanjutkan release flow yang sempat terhenti

Setelah splash screen ini jadi (dan diverifikasi visual di device), lanjutkan sisa langkah dari `prompt_release_final_push.md` yang belum selesai:

- Build ulang release APK (`flutter build apk --release`) — WAJIB rebuild karena ada perubahan baru (splash), jangan push APK lama yang belum termasuk splash.
- Test ulang APK release ini di device (minimal cek splash-nya + smoke test biasa, tidak perlu selengkap testing pertama karena fitur lain sudah diverifikasi Pann manual).
- Lanjut commit + push ke `https://github.com/anandabint/beatfy.git` + GitHub Release (langkah 5-7 di prompt sebelumnya) yang belum sempat jalan.

## Laporan akhir

Konfirmasi: splash tanpa flash putih, build release baru berhasil, dan status akhir push+release GitHub.
