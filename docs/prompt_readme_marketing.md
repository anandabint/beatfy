# Prompt Claude Code — README Marketing + Version Bump + Fix Laporkan Bug + Lisensi

Scope sesi ini lebih luas dari cuma README: (1) restyle `README.md` ala BitChord + changelog, (2) bump versi app ke v1.0.2, (3) fix tombol "Laporkan Bug/Masukan" yang gagal buka email, (4) tambahkan lisensi resmi (GPLv3) ke project + app. Semua keputusan/data di bawah **sudah dikonfirmasi Pann**, tidak perlu ditanya ulang kecuali disebutkan eksplisit "tanya Pann".

## Data terkonfirmasi (pakai langsung, jangan tebak/reuse punya app lain)

- Ko-fi: `https://ko-fi.com/bint29`
- PayPal: `https://paypal.me/anandabint`
- File banner: `/home/anandabint/Downloads/Banner.png` — **copy** (bukan pindah/hapus dari Downloads) ke root project sebagai `Banner.png`, lalu `git add`.
- Lisensi: **GNU GPLv3** (keputusan final, alasan: copyleft mencegah fork closed-source/komersial diam-diam, tetap gratis dipakai siapapun, konsisten dengan genre app FOSS Android personal).
- Versi baru: `1.0.2+2` (versionName 1.0.2, versionCode naik dari 1 ke 2 — praktik standar, versionCode selalu naik tiap rilis baru).

---

## Bagian A — Fix Tombol "Laporkan Bug / Masukan" (prioritas tinggi, sudah ketemu root cause-nya)

**Sudah didiagnosis** (tidak perlu investigasi ulang dari nol, langsung fix): `lib/screens/settings/settings_screen.dart` fungsi `_reportBug` (baris ~119-126) sudah benar — recipient `anandabramadhan@gmail.com` sudah tepat, subject sudah ada. Masalahnya di `android/app/src/main/AndroidManifest.xml`: elemen `<queries>` yang ada saat ini **cuma** declare intent `PROCESS_TEXT`, **tidak ada** declare untuk `mailto:`/`SENDTO` — ini penyebab `canLaunchUrl(uri)` selalu `false` di Android 11+ (package visibility restriction), walau Gmail/app email lain sudah ter-install di device.

**Fix**: tambahkan intent query untuk mailto di dalam `<queries>` yang sudah ada (jangan bikin elemen `<queries>` kedua, gabung ke yang sudah ada):

```xml
<queries>
    <intent>
        <action android:name="android.intent.action.SENDTO"/>
        <data android:scheme="mailto"/>
    </intent>
    <intent>
        <action android:name="android.intent.action.PROCESS_TEXT"/>
        <data android:mimeType="text/plain"/>
    </intent>
</queries>
```

**QC wajib device nyata**: build & install, buka Settings → tap "Laporkan Bug / Masukan", pastikan langsung terbuka app email (Gmail atau app pilihan user via chooser) dengan recipient `anandabramadhan@gmail.com` dan subject "Beatfy - Feedback" sudah terisi. Kalau device test tidak punya app email sama sekali (jarang, tapi mungkin di emulator bersih), sebutkan itu di laporan, jangan anggap fix gagal kalau memang tidak ada app email untuk dites.

---

## Bagian B — Bump Versi ke v1.0.2

1. `pubspec.yaml`: ubah `version: 1.0.0+1` → `version: 1.0.2+2`.
2. Cek tidak ada string versi **hardcoded** di tempat lain yang perlu disinkronkan manual (splash screen, onboarding, dsb) — layar "Tentang" di Settings sudah baca versi secara dinamis lewat `package_info_plus` (`_AppInfoRow`), jadi otomatis ikut berubah, tidak perlu disentuh.
3. **Tidak perlu** membuat git tag `v1.0.2` di sesi ini — itu dilakukan Pann sendiri saat benar-benar publish GitHub Release, di luar scope coding.

---

## Bagian C — Tambahkan Lisensi GPLv3

1. Buat file `LICENSE` di root project berisi teks resmi GNU GPLv3 lengkap (ambil dari sumber resmi/kanonik, misal `curl -s https://www.gnu.org/licenses/gpl-3.0.txt`, atau versi yang sudah tersimpan di training data kalau tidak ada akses network — pastikan teksnya lengkap dan akurat, ini dokumen legal, jangan diringkas/dipotong).
2. Tambahkan header copyright singkat di baris atas file kalau format GPLv3 mensyaratkannya (`Copyright (C) 2026 Ananda Bintang Ramadhan`).
3. Di dalam app: tambahkan baris singkat di Settings (dekat row "Lisensi Open Source" yang sudah ada — itu untuk lisensi *dependency* pihak ketiga, JANGAN dihapus/ditimpa) — tambah row/teks baru terpisah yang menyebutkan lisensi **Beatfy sendiri**, contoh: info text kecil "Beatfy dirilis di bawah GNU GPLv3" di bagian bawah section "Tentang", style menyesuaikan pola `_InfoRow`/`_ActionRow` yang sudah ada di file yang sama.

---

## Bagian D — README (referensi struktur BitChord, isi 100% soal Beatfy)

Referensi struktur (sudah saya baca penuh, tidak perlu buka repo lain):

```
<div align="center">
  <img src="assets/icon/logo.png" width="200" />
  # Beatfy
  ### Tagline pendek
  [badge release] [badge license: GPLv3] [badge downloads]
  [Download](#download) · [Features](#features) · [What's New](#whats-new) · [Support](#support)
</div>

---
<div align="center">
  <img src="Banner.png" width="100%" />
  <h1 id="features">Features</h1>
  <table><tr><td width="50%">...</td><td width="50%">...</td></tr></table>
</div>
---
<div align="center"><h1 id="download">Download</h1> ... (pertahankan konten Installing/Building from source yang sudah ada) </div>
---
<div align="center"><h1 id="whats-new">What's New</h1> ... </div>
---
<div align="center"><h1 id="support">Support</h1> [ko-fi badge] [PayPal badge] </div>
---
<div align="center"><h1 id="privacy">Privacy</h1> ... (pertahankan isi Privacy yang sudah ada, restyle visual saja) </div>
```

**Tidak perlu** section "Disclaimer & Legal" gaya BitChord (soal tidak berafiliasi YouTube/Google) — tidak relevan untuk Beatfy, skip sepenuhnya.

Badge Support (link sudah final, pakai langsung):
```
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/bint29)
[![PayPal](https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/anandabint)
```

Badge license:
```
[![License](https://img.shields.io/github/license/anandabint/beatfy?style=for-the-badge&labelColor=0d1117)](https://github.com/anandabint/beatfy/blob/main/LICENSE)
```

### Features section

Ambil dari `docs/PRD.md` § 6 (v1) dan § 7 (v2) — jangan mengarang, jangan masukkan item yang statusnya belum selesai/belum QC (cek `Architecture.md` § 4a-9 untuk status tiap item). Kelompokkan 2 kolom sesuai tema (contoh: "Playback" vs "Library & Organisasi"), format sama seperti tabel BitChord.

### What's New section (changelog sejak commit terakhir)

Commit terakhir repo: `e4d3f47` ("chore: release v1.0.0", 2026-08-09) — semua yang dikerjakan setelah itu belum pernah masuk changelog. Compile bullet list **user-facing** (bahasa fitur, bukan bahasa commit internal) dari:
1. `docs/PRD.md` § 7 + § 11 — fitur v2 yang sudah selesai.
2. `docs/prompt_home_widget.md` dan `docs/prompt_android_auto.md` — **cek dulu status QC di kedua file/laporan sesi sebelumnya sebelum memasukkan ke changelog**. Kalau QC device nyata (widget) atau test DHU/head-unit (Android Auto) belum benar-benar dituntaskan, **jangan** klaim fitur ini "sudah bisa dipakai" di README publik — kalau perlu, tulis dengan kualifier jujur seperti "Android Auto support (in testing)" daripada diam-diam disebut selesai, atau tunda masuk changelog sampai QC beres (tanya Pann preferensinya kalau ragu).
3. Fix tombol Laporkan Bug (Bagian A) juga masuk changelog sebagai bug fix, bukan fitur baru.

### Privacy section

Pertahankan isi yang sudah ada di README saat ini (scope `drive.file`, tidak ada server sendiri, dst) — restyle visual saja (bungkus `<div align="center"><h1 id="privacy">`). Cek apakah widget/Android Auto menambah permission baru di `AndroidManifest.xml` yang perlu disebut transparan di sini juga.

---

## QC akhir (semua bagian)

1. Build APK debug, install ke device nyata, verifikasi Bagian A (tombol email) benar-benar berfungsi — ini yang paling penting untuk dicek fungsional, bukan cuma baca kode.
2. Cek versi yang tampil di Settings → Tentang sudah `1.0.2` (bukan `1.0.0`).
3. Preview `README.md` (VSCode markdown preview) — pastikan semua badge, link anchor (`#features`, `#whats-new`, dst), dan gambar (`Banner.png`, `assets/icon/logo.png`) tampil benar, tidak ada broken image/link.
4. Baca `LICENSE` — pastikan teks GPLv3 lengkap, tidak terpotong.
5. Baca ulang seluruh README sebagai orang awam yang baru lihat repo pertama kali — pastikan tidak ada sisa teks/klaim/link milik BitChord yang ke-bawa tanpa sengaja.

Laporkan di akhir: ringkasan tiap bagian (A-D) status selesai/ada kendala, dan hasil test tombol email di device nyata (yang paling wajib dibuktikan, bukan diasumsikan).
