# Design — Beatfy

**Revisi besar (2026-08-06)**: Design.md versi sebelumnya (achromatic, hijau Spotify `#1ED760`, album art kotak) di-supersede total. Sumbernya bukan tebakan lagi — Pann generate desain di Figma Make (`figma.com/make/V7gHzXA50sCsgMVv6XKm3T`) dengan prompt struktur dari saya, lalu minta Figma Make menyesuaikan visual ke gambar referensi pribadi Pann sampai Version 3, dan **approve hasilnya**. Dokumen ini ditulis ulang berdasar source code React asli (`index.css`, `HomeScreen.tsx`, dst) dan screenshot live preview Figma Make Version 3 — bukan interpretasi visual, tapi baca token/kode langsung. Ini sumber kebenaran baru, menggantikan semua token warna/tipografi/shape di versi Design.md sebelumnya. Fungsi, layout, dan struktur tab (Architecture.md § 3a) **tidak berubah** — ini murni re-skin visual total.

## 1. Filosofi

Dark canvas tetap jadi dasar, tapi bukan achromatic lagi. Ada dua sumber warna dekoratif tambahan yang sengaja dipakai: (a) **gradient blob ungu-pink** sebagai elemen atmosferik di layar Home dan Now Playing (radial gradient blur, bukan flat fill), dan (b) **lime green** sebagai aksen fungsional tunggal (bukan hijau Spotify). Geometri didominasi **lingkaran** — album art, avatar, playlist cover semua circular, bukan square-rounded seperti versi sebelumnya. Header lebih personal (greeting + avatar user), bukan cuma judul tab generik.

## 2. Color Tokens → Flutter `ColorScheme`

```dart
// core/theme/app_colors.dart
abstract final class AppColors {
  // Brand — lime, bukan hijau Spotify
  static const primary = Color(0xFFC8F135);         // lime accent — fungsional only (play button, active state, progress, dot indicator)
  static const primaryDeep = Color(0xFFB0D62A);      // pressed state (perkiraan shade lebih gelap, verifikasi visual saat implementasi)

  // Canvas
  static const canvas = Color(0xFF141414);           // scaffold background, persis dari index.css
  static const surface = Color(0xFF1C1C1C);          // card/sheet (derivasi sedikit lebih terang dari canvas, verifikasi kontras saat implementasi)
  static const surfaceMuted = Color(0xFF242424);      // input, secondary pill bg
  static const surfaceHover = Color(0xFF2A2A2A);      // press-feedback highlight (§12) — ditambahkan sesi re-skin, tidak ada di referensi Figma Make asli

  // Text
  static const ink = Color(0xFFF0F0F0);              // primary text, persis dari index.css (bukan pure white)
  static const ash = Color(0xFFB3B3B3);               // secondary text
  static const stone = Color(0xFF7C7C7C);             // muted/metadata

  // Gradient blob dekoratif (Home + Now Playing background)
  static const blobPurple = Color.fromRGBO(150, 80, 220, 0.55);
  static const blobPink = Color.fromRGBO(200, 60, 160, 0.3);
  // radial-gradient(circle, blobPurple 0%, blobPink 45%, transparent 70%), blur ~40px, posisi absolute di belakang konten, pointer-events none

  // Semantic (dipertahankan dari versi sebelumnya, belum ada referensi baru)
  static const success = Color(0xFF2B9A66);
  static const warning = Color(0xFFFFA42B);
  static const danger = Color(0xFFF3727F);
  static const info = Color(0xFF539DF5);

  static const hairline = Color(0xFF2A2A2A);
}
```

Aturan pemakaian lime (`primary`): play/pause button, active tab (dot indicator + icon color), progress bar fill, active sort pill, ring di sekitar art yang sedang playing, favorite icon saat active. Gradient blob (`blobPurple`/`blobPink`) **hanya** dekoratif atmosferik di Home dan Now Playing — tidak dipakai sebagai warna fungsional/CTA.

## 3. Typography

Dua font family, bukan satu seperti sebelumnya:

- **Outfit** — semua display text: judul screen, angka rank (Top 10), heading. Geometric, bold, jadi identitas visual utama.
- **Inter** — body text, label, metadata, caption.

```dart
// pubspec.yaml fonts, atau google_fonts package kalau tersedia offline-cache
displayLarge:  Outfit, 24px, weight 700   // judul screen (Home, Library, dst)
titleMedium:   Outfit, 18px, weight 600   // section heading, nama lagu di Now Playing
rankNumber:    Outfit, 28-32px, weight 800 // angka rank 1-3 di Top 10 (oversized, sesuai temuan Figma Make)
bodyMedium:    Inter, 16px, weight 400    // body text
bodySmall:     Inter, 14px, weight 400    // metadata, artist name
labelMedium:   Inter, 14px, weight 600    // button label, pill text
caption:       Inter, 12px, weight 400    // timestamp, fine print
```

## 4. Spacing

Dipertahankan dari versi sebelumnya (8px base unit) — belum ada bukti perlu berubah dari referensi baru:

```dart
abstract final class AppSpacing {
  static const xxs = 2.0; static const xs = 4.0; static const sm = 8.0;
  static const md = 12.0; static const lg = 16.0; static const xl = 24.0;
  static const xxl = 32.0; static const xxxl = 48.0;
}
```

Home tab lebih lega (referensi Figma Make punya banyak whitespace + gradient blob bernapas), Library/Search tetap padat karena scannable list.

## 5. Shape / Radius — circular-first

Perubahan besar dari versi sebelumnya: **semua thumbnail/art/avatar sekarang circular**, bukan rounded-square (`radius sm`). Ini konsisten di semua screen (Home, Search, Library, Playlist) sesuai temuan langsung dari source Figma Make ("Search & Playlist — thumbnail circular konsisten di seluruh screen").

```dart
abstract final class AppRadius {
  static const xs = 4.0;      // input, alert
  static const pill = 999.0;  // filter pill, sort pill, button, search input
  // Circle: BorderRadius.circular(size/2) atau CircleBorder() — dipakai untuk SEMUA album art/avatar/playlist cover, bukan cuma play button
}
```

Featured card ("Discover weekly" style di Home) tetap rounded-rect (~16px), bukan circular — itu satu-satunya elemen besar yang boleh kotak-membulat.

## 6. Elevation / Shadow

Dipertahankan dari versi sebelumnya (shadow berat di dark background). Now Playing album art dapat shadow dalam/berat ("deep shadow" sesuai temuan) untuk kesan mengambang di atas gradient blob.

## 7. Komponen Kunci (update sesuai Figma Make Version 3)

| Komponen | Spesifikasi | Catatan |
|----------|-------------|---------|
| Header Home | **Revisi 2026-08-07**: satu baris teks saja "Hi, [nama depan]" (bold, Outfit) — tanpa baris sapaan waktu terpisah di atasnya (logic sapaan pagi/siang/malam dihapus total, bukan disembunyikan). Avatar bulat kecil kiri-atas, search icon + favorite icon kanan-atas. Fallback saat belum/tidak sign-in: teks statis "Hi there" (bukan lagi sapaan waktu). | Supersede versi 2-baris sebelumnya |
| Context menu song (long-press) | **Baru 2026-08-07**: long-press di song row (semua tab) buka bottom sheet. Item minimal: "Hapus dari perangkat" (danger style — icon+teks merah `AppColors.danger`, paling bawah/terpisah dari item lain), "Tambah ke playlist", toggle "Favorite"/"Hapus dari favorite", "Bagikan". Ini pengganti utama swipe-to-delete untuk aksi hapus — swipe-to-delete di-deprecate untuk song row (tetap dipakai untuk playlist-level delete di Playlist tab, itu beda konteks dan tetap aman/reversible dalam app). | Menggantikan pola swipe pada song row karena kurang discoverable + sekarang aksi hapusnya destructive (real file) jadi butuh tempat yang lebih eksplisit |
| Filter pill row | Horizontal scroll pill (All / New Release / Trending / Top Charts di Home; All / Playlists / Liked Songs / Downloads di Library), active pill filled lime | Pengganti dropdown sort lama |
| Featured card | Card besar rounded-rect, gradient/warna ungu, judul + subtitle + play button + gambar di sisi kanan | Baru, elemen hero di Home |
| Song row | Circular art kiri, judul+artis tengah, circular play button lime di kanan (bukan icon play kecil polos) | Update dari flat row sebelumnya |
| Top 10 list | Angka rank oversized (Outfit 800, lime untuk rank 1-3), circular art kecil, judul+artis | Baru secara visual, fungsi sama PRD |
| Bottom nav | **Revisi 2026-08-07**: floating pill/kapsul (rounded-full, margin dari tepi layar kiri-kanan, bukan bar full-width nempel edge), tab aktif = lingkaran solid lime membungkus icon (bukan dot di atas icon), **tanpa label teks**, icon-only, 4 icon (Home/Search/Library/Playlist). **Revisi 2026-08-08 (final)**: `boxShadow` pada `_BottomNavBar` **dihapus total** — Pann konfirmasi lebih suka pill berdiri sendiri tanpa shadow gelap di sekitarnya sama sekali, bukan cuma dikecilkan. | Ganti lagi dari dot-indicator (yang itu sendiri gantian dari pill-highlight versi paling awal) — referensi: mockup pribadi Pann |
| Mini player | Pill floating (bukan full-width bar), art circular, tombol shuffle tambahan, play/pause lime. **Revisi 2026-08-08 (final)**: `boxShadow` dihapus juga (sama alasan dengan Bottom nav), `clipBehavior: Clip.antiAlias` pada `Material` tetap dipertahankan (hardening ink-splash yang sudah benar, independen dari soal shadow). | Update dari bar persisten kotak |
| Now Playing | Art circular besar dengan deep shadow, gradient blob purple di background, baris lirik transparan di bawah judul (opsional/dekoratif — cek ketersediaan data lirik saat implementasi), progress bar, tombol play lime 76px dominan, prev/next di kiri-kanan. **Revisi 2026-08-07**: art dinaikkan posisinya (kurangi top padding sebelum art) + ukuran diperbesar sedikit (~+8-10% dari implementasi sekarang), jarak art→judul lagu ditambah (gunakan `AppSpacing.xl`/32px, bukan `lg`/16px yang dipakai sekarang). Tambahkan volume slider (horizontal, lime fill sama style progress bar, icon speaker kecil di kiri-kanan sebagai min/max) di bawah baris tombol transport (shuffle-prev-play-next-repeat), mengisi ruang kosong di bagian bawah layar yang sebelumnya terasa "mengambang". | Update besar dari square-art version |
| Playlist card | Dashed border "New Playlist" card yang expand jadi form inline saat di-tap | Baru, ganti FAB circular dari sesi sebelumnya |
| Playlist detail | Drag-to-reorder (native drag), tombol remove per-item | Sama fungsinya, gaya interaksi tetap dipertahankan dari Design.md § 12 (confirm dialog sebelum delete tetap wajib) |
| Library grouping (Album/Artist/Folder) | **Baru 2026-08-07**: filter pill row Library ditambah 3 pill baru — "Albums" / "Artists" / "Folders" (di samping All/Playlists/Liked Songs/Downloads yang sudah ada, scroll horizontal kalau kepanjangan). Pilih salah satu → list berubah jadi grouped row (circular art representatif + nama grup + jumlah lagu), tap satu grup → detail screen list lagu di dalamnya (reuse song row component biasa). | Row detail sama style dengan Library flat list, cuma sumber datanya beda |
| Settings screen | **Baru 2026-08-07, direvisi 2026-08-07**: diakses dari tap avatar di header Home (bukan tab/icon terpisah). Isi: foto+nama+email akun (atau tombol "Sign in with Google" kalau belum login), ringkasan status backup ("X dari Y lagu ter-backup"), tombol **"Backup Sekarang"** eksplisit (bukan lagi toggle auto-backup — trigger otomatis dihapus, lihat Architecture.md § 4c), tombol sign out. Style flat dark konsisten Library/Search (tanpa gradient blob). **Tambahan section "Tentang" (lihat § 7 row baru di bawah)** ditambahkan sebelum eksekusi finalisasi. | |
| Restore screen (first login device baru) | **Baru 2026-08-07**: full-screen progress saat Hive lokal kosong tapi akun Drive punya folder backup — progress bar + counter "X/Y file terdownload", tidak bisa di-skip/dismiss sampai selesai (mencegah user masuk ke app dengan library kosong padahal ada backup). | |
| Onboarding slides | **Baru 2026-08-07**: 3 slide (`PageView` + dot indicator lime di slide aktif), style flat dark konsisten (tanpa gradient blob — itu ciri khas Home/Now Playing saja). Slide 1: perkenalan singkat Beatfy (satu kalimat + ilustrasi/icon musik simple). Slide 2: prinsip offline-first ("musik kamu tetap di HP, tidak perlu internet buat dengar"). Slide 3: preview singkat cloud backup sebagai jaring pengaman (transisi ke halaman sign-in). Tombol "Lanjut"/"Lewati intro" kecil di pojok. | |
| Permission screen | **Baru 2026-08-07**: layar sederhana jelasin kenapa butuh akses media/audio (satu kalimat jujur, bukan boilerplate sistem), tombol "Izinkan" memicu system permission dialog Android. | |
| Sign-in screen (akhir onboarding) | **Baru 2026-08-07**: headline singkat + 2-3 baris benefit login Google (auto-backup, aman kalau HP reset/ganti — bukan wall of text), tombol "Lanjut dengan Google" (lime, filled, dominan) dan "Lewati" (text button, di bawahnya, kurang menonjol secara visual supaya login jadi pilihan yang lebih natural tapi skip tetap gampang ditemukan). | Sama komponen dipakai ulang untuk tombol login di Settings |
| Artwork fallback gradient | **Revisi 2026-08-08**: lagu tanpa embedded artwork tampil gradient berbeda per-lagu (hash dari judul+artis → pilih dari palet gradient yang dikurasi, bukan warna acak/hijau seragam). Berlaku di semua tempat art dirender (song row semua tab, Now Playing, mini player, playlist cover). | Fix — sebelumnya cuma hijau flat, tidak sesuai spec lama yang sudah ada di dokumen ini |
| Ikon status backup | **Baru 2026-08-08**: ikon kecil subtle di song row (cloud-check kalau sudah ter-backup, kosong/cloud-outline tipis kalau belum) — bukan penanda "streaming vs lokal" (app ini tidak streaming), murni status backup. | |
| Now Playing — ambient color dinamis | **Revisi 2026-08-08**: blob background Now Playing tidak lagi selalu ungu-pink statis — warna diambil dari dominant color artwork lagu yang sedang main (`palette_generator`). Fallback ke ungu-pink default kalau tidak ada artwork/ekstraksi gagal. | Update dari § 1/§ 7 Now Playing sebelumnya |
| Splash screen | **Baru 2026-08-09**: native splash screen (bukan custom Flutter widget — pakai `flutter_native_splash`) muncul sebelum app fully loaded/sebelum `SplashScreen`/onboarding-check jalan. Background `AppColors.canvas` (#141414), logo dari `assets/splash/splash_screen.png` di-center, tanpa teks tambahan. Konsisten warna dengan app icon/tema, transisi ke app tanpa flash warna putih (default Android splash kalau tidak dikonfigurasi biasanya putih — pastikan background di-override). | |
| App icon | **Baru 2026-08-08**: pakai `assets/icon/logo.png` (custom, dari Pann) via `flutter_launcher_icons`, generate adaptive+legacy icon, ganti dari default Flutter icon. | |
| Section "Tentang" (Settings) | **Baru 2026-08-07**: section terpisah di bagian bawah Settings screen (di bawah section Account/backup), style flat konsisten. Isi urut: (1) app icon + "Beatfy" + versi dinamis dari `package_info_plus` (format "v1.0.0 (12)"). (2) Developer: "Ananda Bintang Ramadhan". (3) Baris "Laporkan Bug / Masukan" — tap buka email client (`url_launcher`, `mailto:anandabramadhan@gmail.com?subject=Beatfy%20-%20Feedback`). (4) Baris "Privasi" — tap buka bottom sheet/dialog teks ringkas (bukan halaman web): "Beatfy tidak mengumpulkan data pengguna, tidak ada iklan atau analytics pihak ketiga. Satu-satunya data yang keluar dari perangkat adalah file musik yang di-backup ke Google Drive akun kamu sendiri, hanya kalau fitur backup diaktifkan — Beatfy tidak punya server sendiri yang menyimpan data apapun." (5) Baris "Lisensi Open Source" — tap buka `showLicensePage()` bawaan Flutter (auto-list semua package dependency). | Semua baris pakai style list item sederhana (icon kiri + label + chevron kanan), bukan card besar — biar terasa ringkas/minimalist konsisten prinsip app |
| Avatar/foto profil | **Baru 2026-08-07**: 3 state — (a) sudah login + akun Google punya foto → tampilkan foto asli (`NetworkImage` dari `photoUrl`, ada loading/error fallback ke state c). (b) sudah login tapi akun Google tidak punya foto → placeholder template (icon person generik, bukan foto). (c) belum login → **tidak** tampilkan elemen yang terlihat seperti foto profil sama sekali (icon berbeda/netral, misal outline person tanpa background bulat solid) — supaya user tidak salah kira sudah login. | Berlaku di avatar header Home dan Settings |

## 8. Album Art & Imagery

**Circular, bukan square** — ini perubahan paling signifikan dari versi sebelumnya. Berlaku di semua tempat: song row, Now Playing hero, playlist cover, mini player. Placeholder gradient (§ Design.md lama, hash-based per artist/album) tetap dipakai sebagai fallback saat artwork tidak ada, tapi di-crop circular.

## 9. Touch Target

Tidak berubah — minimum 44×44, kontrol Now Playing minimum 48×48 (tombol play utama sekarang 76px, jauh di atas minimum).

## 10. Motion / Transisi

Tidak berubah dari versi sebelumnya — custom page transition, Hero mini-player→Now Playing tetap berlaku, sekarang dengan circular art jadi shared element yang lebih natural secara visual.

## 11. Do's & Don'ts (revisi)

**Do**: canvas `#141414`, lime `#C8F135` hanya untuk elemen fungsional, circular untuk semua art/avatar, gradient blob purple-pink sebagai atmosfer di Home/Now Playing (bukan di semua screen — Library/Search/Playlist tetap flat dark tanpa blob), Outfit untuk display/angka, Inter untuk body.

**Don't**: jangan pakai hijau Spotify `#1ED760` lagi (sudah diganti lime), jangan square-rounded buat art/avatar (harus circular), jangan taruh gradient blob di Library/Search/Playlist (itu screen padat/scannable, blob akan mengganggu keterbacaan), jangan hilangkan konfirmasi delete di playlist meski gaya interaksinya diperbarui (Design.md § 12 tetap berlaku).

## 12. Interaction & Micro-motion Polish (tetap berlaku, dari revisi sebelumnya)

Semua poin di bawah ini **tidak berubah** — murni soal interaksi/motion, independen dari palet warna:

**Bottom nav indicator** — sekarang berbentuk dot (bukan pill background), tetap harus dianimasikan (`AnimatedContainer`, muncul/hilang smooth ~200ms) saat pindah tab, bukan langsung snap.

**Skeleton loading, swipe-to-delete, tinted leading icon (adaptasi: sekarang circular bukan rounded-square), haptic feedback, snackbar feedback, empty state, card/list-tile press feedback** — semua pola dari revisi sebelumnya tetap berlaku, hanya warnanya mengikuti palet baru (lime, bukan hijau) dan shape icon container mengikuti circular-first (§ 5).

## 13. Sumber & Referensi

Figma Make file: `https://www.figma.com/make/V7gHzXA50sCsgMVv6XKm3T/Beatfy-offline-music-player` (Version 3, approved Pann). Source code React (`index.css`, `src/screens/*.tsx`) dibaca langsung via Figma MCP untuk memastikan token di dokumen ini akurat, bukan interpretasi visual dari screenshot. Kalau ada detail yang belum tercakup di sini saat implementasi Flutter (misal shade pasti untuk `surface`/`primaryDeep` yang saya estimasi), Claude Code boleh ambil keputusan wajar berdasarkan kontras/aksesibilitas, tapi wajib dicocokkan visual ke screenshot Figma Make Version 3 sebagai referensi akhir — bukan re-interpretasi bebas.
