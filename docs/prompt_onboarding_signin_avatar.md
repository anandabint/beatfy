# Prompt Claude Code  Onboarding Flow + Fix Popup Sign-In + Foto Profil Asli

Baca ulang dulu bagian yang diupdate hari ini: `Architecture.md` § 4b (Onboarding Flow), § 4c (aturan sign-in tidak boleh auto-prompt), `Design.md` § 7 (4 row baru: Onboarding slides, Permission screen, Sign-in screen, Avatar/foto profil), `Schema.md` (`AppPreferences` typeId 11), `PRD.md` § 7 item 8 & § 11 (2 keputusan baru).

## 1. Onboarding flow (cuma muncul sekali)

Route awal app dicek dari `AppPreferences.hasSeenOnboarding` (Hive, default `false`):

1. **3 slide intro** (`PageView` + dot indicator lime aktif)  konten sesuai `Design.md` § 7 "Onboarding slides": (1) perkenalan singkat Beatfy, (2) prinsip offline-first, (3) preview singkat cloud backup. Tombol "Lanjut"/"Lewati intro" kecil.
2. **Permission screen**  jelasin singkat kenapa butuh izin media, tombol "Izinkan" trigger permission dialog Android (`READ_MEDIA_AUDIO` Android 13+ / storage permission di bawahnya, sudah ada logic-nya dari v1, reuse).
3. **Sign-in screen**  headline + 2-3 baris benefit login Google, tombol "Lanjut dengan Google" (lime, dominan) + "Lewati" (text button, kurang menonjol). Baik login sukses maupun skip, keduanya lanjut ke `MainShell` dan set `AppPreferences.hasSeenOnboarding = true`.

Kalau `hasSeenOnboarding == true`, skip semua ini, langsung ke `MainShell` seperti biasa.

## 2. Fix bug: popup sign-in otomatis tiap buka app

**Repro yang dilaporkan Pann**: tiap app dibuka (setelah sebelumnya ditutup), selalu muncul popup/bottom-sheet kecil di bawah minta login Google  padahal user tidak menyentuh apapun. Ini melanggar prinsip "tidak memaksa".

**Investigasi**: cari di kode tempat manapun yang manggil sign-in check saat startup (`main.dart`, splash logic, provider initialization). Kemungkinan besar penyebabnya: `google_sign_in` versi yang dipakai project ini pakai Android Credential Manager di balik layar, dan method yang dikira "silent" (misal `signInSilently()` atau `attemptLightweightAuthentication`) ternyata tetap bisa memicu UI bottom-sheet "Continue as [nama]?" otomatis di Android versi tertentu.

**Fix wajib** (baca `Architecture.md` § 4c buat aturan lengkapnya): status login yang ditampilkan di UI (nama di header Home, isi Settings) **hanya boleh dibaca dari `UserProfileCache`** (cache lokal Hive) saat app start  JANGAN ada call live apapun ke Google di titik ini. Call live ke Google cuma boleh terjadi tepat sebelum operasi yang benar-benar butuh token aktif (upload/restore Drive), dan itu pun errornya di-handle di situ, tidak proaktif dicek di startup. Kalau ada logic lama yang manggil silent-check di startup buat "sinkronisasi status", hapus  cukup percaya cache lokal, update cache-nya cuma saat user eksplisit sign-in/sign-out.

Verifikasi di device: cold-start app berkali-kali (baik sudah login maupun belum/skip), pastikan TIDAK ADA popup apapun muncul tanpa disentuh.

## 3. Foto profil pakai foto Google asli

Baca `Design.md` § 7 "Avatar/foto profil"  3 state:

- Login + akun Google punya foto → load `photoUrl` dari `GoogleSignInAccount` (`NetworkImage`, ada error handler fallback ke state berikutnya kalau gagal load).
- Login + akun Google tidak punya foto → placeholder template netral (icon person generik).
- Belum login → **bukan** placeholder yang mirip foto profil (pakai icon berbeda/netral supaya user tidak salah kira sudah login).

Terapkan di avatar header Home dan Settings screen (dua tempat yang sama-sama nampilin avatar).

**Catatan penting**: `photoUrl` dari Google butuh disimpan juga ke `UserProfileCache` (Hive) saat sign-in sukses, supaya bisa dipakai lagi tanpa call live ke Google (konsisten sama aturan poin 2)  kemungkinan perlu nambah field `photoUrl: String?` ke `UserProfileCache` (typeId 8, sudah ada field `displayName`/`email`, tinggal tambah satu field baru, tidak butuh typeId baru, dokumentasikan penambahan field ini di `Schema.md`).

## QC

Pann yang cek sendiri di device  tidak perlu checklist penuh `Rules.md` § 4, tapi tetap wajib: build sukses, `flutter analyze` bersih, dan minimal sekali coba jalur onboarding penuh dari awal (uninstall+reinstall biar `hasSeenOnboarding` reset) sebelum lapor selesai, supaya tidak lapor sesuatu yang ternyata belum pernah dicoba jalan dari nol.
