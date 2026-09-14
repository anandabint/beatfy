# Architecture  Beatfy

Dokumen ini menjelaskan **bagaimana** sistem dibangun. Turunan teknis dari PRD.md. Wajib dibaca Claude Code sebelum menulis kode struktural apapun.

## 1. Tech Stack

| Layer | Pilihan | Alasan |
|-------|---------|--------|
| Framework | Flutter (Dart), Android-only target | Sesuai keputusan Pann, single codebase modern dibanding native Kotlin sebelumnya. |
| State management | Riverpod (`flutter_riverpod`) | Sama pola dengan Planly  familiar, testable, tidak butuh BuildContext untuk akses state. |
| Local storage | Hive, via `hive_ce` + `hive_ce_flutter` | Sama pola dengan Planly. Cukup untuk data non-relational (playlist, favorite, play-stats, cache metadata lagu). **Update (scaffold session, 2026-08-05)**: `hive`/`hive_flutter` asli terakhir publish 4 tahun lalu; dipakai `hive_ce`/`hive_ce_flutter` (continuation komunitas, aktif, drop-in compatible)  dilaporkan & disetujui Pann sebelum dipakai. API dan konsep pemakaian identik dengan `hive` original, hanya nama import beda. |
| Audio playback | `just_audio` | Engine playback utama  gapless, format luas, kontrol precise. |
| Background/session | `audio_service` | Wajib untuk foreground service, MediaSession, notification, lock-screen control, Bluetooth media button. `just_audio` + `audio_service` adalah kombinasi standar Flutter untuk music player. |
| Library scan | `on_audio_query` (atau `photo_manager`-equivalent khusus audio) | Akses MediaStore Audio collection + Downloads. Evaluasi versi terbaru saat implementasi  kalau ada package lebih baru/lebih terawat, Claude Code wajib info ke Pann sebelum ganti. |
| Artwork | Embedded artwork dari `on_audio_query` / fallback `id3` tag reader | Tidak pakai network image loader (beda dari Coil di versi lama  semua lokal). |
| Cloud (v2) | `google_sign_in` + Google Drive REST API (`googleapis` package) | Backup/restore file ke Drive akun user sendiri. |
| Routing | `go_router` atau `Navigator 2.0` sederhana | Pola transisi halus, hindari default MaterialPageRoute yang terasa kaku (ini salah satu penyebab "patah-patah" di versi lama). |
| Refresh rate | `flutter_displaymode` | Android default cap render di 60Hz meski device support lebih tinggi  package ini set preferred display mode ke Hz maksimum device saat app start. Wajib untuk device 90/120Hz+ Pann, ditambahkan sesi audit performa 2026-08-07. |

Semua pilihan package di atas **default**, bukan mengikat mati  kalau saat implementasi Claude Code menemukan versi/library lebih baik (lebih maintained, performa lebih baik), **wajib lapor ke Pann dengan alasan jelas sebelum ganti**, bukan diam-diam ganti.

## 2. Prinsip Arsitektur

1. **Separation of concerns ketat**: UI tidak pernah bicara langsung ke Hive/MediaStore/audio_service. Selalu lewat repository → provider → UI.
2. **Single source of truth untuk playback state**: satu `AudioHandler` (audio_service) jadi otoritas tunggal status playback. UI hanya observe, tidak pernah punya state playback duplikat lokal.
3. **State restore adalah fitur kelas satu**, bukan side-effect. Posisi playback, queue, dan status disimpan setiap ada perubahan berarti (bukan hanya saat app di-pause), supaya proses di-kill sistem pun bisa direstore.
4. **Tidak ada logic bisnis di widget**. Widget murni presentational, terima state dari provider.

## 3. Struktur Folder

```
lib/
  main.dart
  app.dart                       # MaterialApp/root widget, theme, router
  core/
    theme/                       # ColorScheme, TextTheme, spacing, shape (dari Design.md)
    constants/
    utils/
  data/
    local/
      hive/                      # Hive box setup, adapters (lihat Schema.md)
    library/
      audio_query_service.dart   # wrapper on_audio_query, scan + cleanup filename
      title_cleaner.dart         # port logic dari TitleCleaner.kt versi lama
    repositories/
      library_repository.dart
      playlist_repository.dart   # v2
      favorite_repository.dart   # v2
      play_stats_repository.dart # v2
  playback/
    audio_handler.dart           # implementasi BaseAudioHandler (audio_service)
    queue_manager.dart
    output_detector.dart         # deteksi Bluetooth/wired connect-disconnect
  models/
    song.dart
    playlist.dart                # v2
    favorite.dart                # v2
    play_stats.dart              # v2
  providers/
    library_providers.dart
    playback_providers.dart
    playlist_providers.dart      # v2
  screens/
    shell/
      main_shell.dart            # v2  root shell, lihat § 3a
    home/                        # v2  tab 1
    search/                      # v2  tab 2
    library/                     # tab 3 (sudah ada di v1, dipindah jadi child shell di v2)
    playlist/                    # v2  tab 4 (list + detail)
    now_playing/                 # diakses dari mini player, di luar 4 tab (full-screen overlay)
    settings/                    # v2  entry point cloud backup
  widgets/
    common/                      # button, card, song row, dst  reusable
    now_playing/
  services/
    permission_service.dart
    cloud_backup_service.dart    # v2, Google Drive
docs/
  Architecture.md
  Design.md
  PRD.md
  Rules.md
  Schema.md
```

Pola ini paralel dengan Planly (`controllers/providers/repositories/models` terpisah rapi), disesuaikan nama folder untuk domain musik (`playback/` adalah tambahan khas music player, tidak ada di Planly).

### 3a. Navigation Shell (v2  klarifikasi wajib baca)

v1 sengaja single-screen (langsung buka ke Library)  scope minimal yang dipilih di awal PRD, bukan keputusan visual final. **v2 membangun shell navigasi 4-tab**, referensi struktural ganda:

- **Fitur/tab per beatfy-main lama** (`ui/navigation/Destinations.kt`): 4 tab persis  Home, Search, Library, Playlist. Konten tiap tab mengikuti fitur yang sudah ada di kode Kotlin lama (Home = recently added + top 10, Search = cari judul/artis/album, Library = list/browse yang sudah dibangun di v1, Playlist = list + detail playlist).
- **Pola struktural shell dari Planly** (`lib/screens/main_shell.dart`): `IndexedStack` menampung 4 tab (state per tab terjaga saat pindah  tidak rebuild/reset scroll position tiap ganti tab), `BottomNavigationBar` dengan active-tab diberi pill highlight. **Hanya pola/motion-nya** yang dicontek  warna WAJIB ikut Design.md (dark canvas, active pill hijau `AppColors.primary`), bukan navy/teal Planly.

`NowPlayingScreen` tetap terpisah dari 4 tab ini  diakses lewat mini player (persistent di atas bottom nav), bukan salah satu tab, sama seperti pola umum music player (Spotify juga begitu).

**Revisi arsitektural 2026-08-08  pakai slot `Scaffold.bottomNavigationBar`, bukan `Column` manual**: implementasi awal `MainShell` pakai `Scaffold(body: SafeArea(child: Column([Expanded(IndexedStack), MiniPlayer(), _BottomNavBar()])))`  MiniPlayer+NavBar jadi sibling manual di `Column`. Ini sumber bug berulang (list ketutup, padding harus dikalibrasi manual per-screen) karena tidak memanfaatkan mekanisme Scaffold yang sudah teruji. Planly (`main_shell.dart`) pakai pola benar: `Scaffold(body: ..., bottomNavigationBar: BottomNavigationBar(...))`  slot bawaan yang otomatis mengatur ruang body dengan benar, tanpa developer perlu hitung clearance manual.

**Fix**: restrukturisasi `MainShell` jadi `Scaffold(extendBody: true, body: IndexedStack(...), bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [MiniPlayer(), _BottomNavBar()]))`. `extendBody: true` bikin `body` (list di tiap tab) bisa scroll penuh sampai bawah layar (transparan di balik area bottomNavigationBar), sementara `MiniPlayer`+`_BottomNavBar` (yang sudah transparent-background, cuma pill-nya yang solid, per revisi shadow/background 2026-08-08 sebelumnya) tetap "timbul" mengambang di atas konten. Konsekuensi: **semua padding manual (`AppSpacing.xxxl`, atau `floatingNavClearance` yang sempat diusulkan) di Library/Home/Playlist untuk clearance MiniPlayer+NavBar dihapus**  tidak dibutuhkan lagi, Scaffold yang urus otomatis. Padding kecil buat estetika (jarak visual biasa, bukan clearance fungsional) boleh tetap ada dengan nilai kecil wajar (`AppSpacing.md`/`lg`), bukan nilai besar yang coba menebak tinggi elemen lain.

**Fix regresi + frosted glass (2026-09-14)**: ditemukan `extendBody` di kode aktual sempat balik ke `false` (tidak sinkron dengan fix di atas, kemungkinan regresi sesi lain)  dikembalikan ke `true`. Ini jadi prasyarat wajib untuk fitur baru sesi ini: `MiniPlayer`+`_BottomNavBar` sekarang pakai `BackdropFilter` blur (frosted glass, lihat Design.md § 7) supaya konten tab yang discroll di baliknya kelihatan blur lewat pill  butuh `extendBody: true` supaya ada konten asli di balik pill untuk di-blur (kalau `false`, `BackdropFilter` cuma nge-blur canvas kosong, tidak ada efek).

**Koreksi klaim di atas (2026-09-14)**: paragraf "Fix" di atas bilang "Scaffold yang urus otomatis" soal clearance body vs MiniPlayer+NavBar saat `extendBody: true`  ini **keliru**, kemungkinan besar akar kenapa bug "baris terakhir ketutup dock" berulang kali muncul lagi di sesi-sesi berikutnya. Faktanya: `Scaffold` dengan `extendBody: true` **tidak** meneruskan tinggi `bottomNavigationBar` ke `MediaQuery.padding.bottom` milik `body`  tidak ada sinyal otomatis yang bisa dikonsumsi widget di dalamnya. Tanpa padding bawah manual yang presisi, baris/item terakhir list permanen tersembunyi (dan tidak bisa di-tap) di balik pill saat discroll mentok.

**Percobaan pertama (konstanta ditebak, dicabut)**: sempat dicoba `DockMetrics.clearance()`  konstanta statis (72+68) + `MediaQuery.padding.bottom` manual, dipakai tiap tab. Hasilnya gap terlalu besar dari kondisi nyata (dilaporkan Pann, dibandingkan dengan kalibrasi final `docs/prompt_fix_miniplayer_overlap.md` sesi sebelumnya)  angka ditebak/dijumlah manual begini persis pola yang berulang kali meleset, konsisten dengan pelajaran § 7e.

**Fix final (2026-09-14, presisi via pengukuran layout nyata)**: `_DockMeasurer` (`main_shell.dart`) membungkus `Column([MiniPlayer(), _BottomNavBar()])` di slot `bottomNavigationBar`, ukur tinggi render asli-nya (`RenderBox.size.height`, sudah termasuk safe-area dari `SafeArea(top:false)` di dalamnya) lewat `GlobalKey` + `addPostFrameCallback`, simpan ke `dockHeightProvider` (`providers/layout_providers.dart`). Diukur ulang tiap kali `MiniPlayer` muncul/hilang (`ref.listen(currentMediaItemProvider, ...)`, bukan tiap frame  boros). Tiap tab (`Home`/`Search`/`Library`/`Playlist`) tinggal `ref.watch(dockHeightProvider)` buat `padding.bottom` list-nya (+ sedikit `AppSpacing` buat jarak estetika). `DockMetrics` (`core/theme/dock_metrics.dart`) sekarang cuma nilai awal (seed) sebelum pengukuran pertama selesai, bukan sumber kebenaran akhir. Ini BEDA dari anti-pattern yang ditolak di § 7e (`AppSpacing.floatingNavClearance` per-screen ditebak manual)  di sini nilainya diukur otomatis dari layout asli, bukan angka tebakan/kalkulasi manual yang gampang meleset dari device ke device. **Jangan ganti balik ke konstanta manual**  itu sudah dicoba dua kali (§ 7e lama, dan percobaan pertama sesi ini), dua-duanya meleset.

## 4. Playback Architecture (Kritis)

Ini bagian paling penting  sumber bug terbesar di versi lama.

```
┌─────────────┐      ┌──────────────────┐      ┌───────────────┐
│   UI Layer  │◄────►│  Riverpod Provider │◄───►│  AudioHandler  │
│ (widgets)   │ watch│  (playback_state)  │listen│ (audio_service)│
└─────────────┘      └──────────────────┘      └───────┬───────┘
                                                          │ wraps
                                                    ┌─────▼─────┐
                                                    │ just_audio │
                                                    │  Player    │
                                                    └───────────┘
```

- `AudioHandler` adalah **satu-satunya** yang boleh memanggil method play/pause/seek pada `just_audio` player.
- Setiap perubahan state (`playing`, `position`, `queue index`) di-broadcast lewat `PlaybackState` stream milik `audio_service`  UI subscribe lewat provider, tidak polling.
- **Persist posisi**: simpan `songId + position + queueIndex` ke Hive setiap event pause, setiap perpindahan track, dan periodik (misal tiap 5 detik saat playing)  bukan hanya saat app lifecycle `paused`. Ini kunci fix bug "balik ke awal lagu".
- Saat app restart (termasuk setelah di-kill sistem), `AudioHandler` baca state terakhir dari Hive saat inisialisasi, restore queue + posisi sebelum UI pertama kali render Now Playing screen.
- Foreground service notification wajib aktif selama ada sesi playback (walau paused), sesuai requirement Android untuk background audio.

## 4a. Notification Tap & Real File Delete (ditambahkan 2026-08-07)

**Notification tap-to-Now-Playing**: `audio_service` menyediakan `androidNotificationClickStartsActivity`  pastikan `true`, lalu handle intent masuk (baik app belum jalan/background/foreground) supaya route awal yang dibuka selalu `NowPlayingScreen`, bukan default `initialRoute` shell. Kalau `audio_service` versi yang dipakai tidak expose hook langsung untuk custom target screen dari notification tap, fallback: cek `AudioService.running`/current media item di `main.dart`/router redirect logic saat app diluncurkan dari notification (bedakan dari cold-launch biasa via icon launcher).

**Hapus lagu asli dari device (real file delete, PRD § 7.7)**: Ini **bukan** operasi Hive biasa  perlu hapus file fisik di storage Android yang **tidak dimiliki app** (di-scan via MediaStore, bukan disalin ke app-private storage). Di Android 11+ (scoped storage), satu-satunya jalur resmi adalah `MediaStore.createDeleteRequest(contentResolver, uris)` yang mengembalikan `IntentSender`, dijalankan lewat `startIntentSenderForResult` dari `Activity`, lalu user approve system dialog (ini system-level confirmation dari Android sendiri, **di luar** dan **tambahan dari** dialog konfirmasi in-app Beatfy). Kemungkinan besar `on_audio_query` **tidak** menyediakan wrapper untuk API ini (dia dibuat untuk query, bukan delete)  Claude Code wajib cek dulu apakah ada plugin Flutter yang sudah wrap `createDeleteRequest` secara stabil; kalau tidak ada yang layak, buat platform channel kecil khusus (`MethodChannel`, native Kotlin di `MainActivity`) yang expose satu method `deleteMediaFiles(List<Uri>)`. Untuk device Android 10 ke bawah (di luar scoped storage penuh), fallback ke `File.delete()` langsung boleh dipakai kalau permission `WRITE_EXTERNAL_STORAGE`/legacy tersedia  tapi ini kasus minor, minSdk project 24 jadi harus tetap dihandle, jangan crash di device lama.

Alur wajib: dialog konfirmasi in-app (jelas bilang "permanen, tidak bisa dibatalkan") → `createDeleteRequest`/delete native → system dialog approve (Android 11+) → on success, hapus entry dari Hive (`songs`, `favorites`, `play_stats`, referensi `songId` di semua `playlists.songIds`) → kalau lagu yang dihapus sedang di queue/now playing, skip ke lagu berikutnya (jangan crash/stuck di lagu yang sudah tidak ada filenya). Ini flow yang secara sifat **irreversible**  QC device wajib jadi bagian Definition of Done sebelum dianggap selesai (lihat Rules.md).

## 4b. Onboarding Flow (v2, ditambahkan 2026-08-07)

Route awal app dicek dari `AppPreferences.hasSeenOnboarding` (Schema.md § "AppPreferences", typeId 11). Kalau `false`:

```
SplashScreen (cek Hive, sebentar) → OnboardingSlides (3 slide, PageView) → PermissionScreen (READ_MEDIA_AUDIO) → SignInScreen (skip/login) → set hasSeenOnboarding = true → MainShell
```

Kalau `true`, langsung ke `MainShell` seperti biasa (baca `UserProfileCache` untuk tahu status login, tidak ada call live ke Google  lihat § 4c).

`SignInScreen` (elemen terakhir onboarding) berisi copy singkat kenapa login Google bermanfaat (auto-backup, aman kalau HP reset) di atas dua aksi: tombol "Lanjut dengan Google" (lime, filled) dan "Lewati" (text button, kurang menonjol). Skip **tidak** menyimpan flag negatif apapun selain `hasSeenOnboarding = true`  user bisa login kapan saja nanti lewat avatar di Settings.

## 4c. Sign-In  Aturan Tidak Boleh Auto-Prompt (ditambahkan 2026-08-07, fix bug)

Bug ditemukan: app menampilkan bottom-sheet/popup Google sign-in otomatis tiap kali dibuka, tanpa user menyentuh apapun  kemungkinan besar dari Android Credential Manager yang dipicu oleh `google_sign_in` versi baru saat app memanggil semacam silent-check di startup. **Aturan tetap ke depan**: status login yang ditampilkan di UI (header Home, Settings) HARUS dibaca murni dari `UserProfileCache` (cache lokal), bukan dari call live ke Google API saat startup. Call live ke Google (`GoogleSignIn().signInSilently()` atau sejenisnya) hanya boleh dipanggil di titik yang benar-benar butuh token aktif (misal tepat sebelum upload/restore Drive), dan errornya di-handle di situ (fallback/retry), bukan proaktif dicek tiap app dibuka untuk sekadar menentukan tampilan UI. Sign-in interaktif (yang boleh menampilkan UI) HANYA boleh terjadi sebagai kelanjutan langsung dari tap eksplisit user di tombol "Lanjut dengan Google" (baik di Onboarding maupun Settings)  tidak pernah otomatis.

**Update (sesi onboarding, 2026-08-07)  sumber kedua ditemukan & diperbaiki**: setelah `UserProfileNotifier.build()` dibersihkan (baca murni cache, lihat di atas), popup masih reproducible di device nyata (Oppo/ColorOS) tiap cold start selagi WiFi nyala. Root cause kedua: `ConnectivityBackupNotifier._triggerUpload()` (`providers/cloud_backup_providers.dart`)  dipicu otomatis tiap app start via `ref.watch(connectivityBackupProvider)` di `_RootGate`  memanggil `CloudBackupService.uploadPending()` → `AuthService.getDriveAuthClient()` → `attemptLightweightAuthentication()` **tanpa pernah cek dulu apakah user sign-in**. Terbukti `attemptLightweightAuthentication()` tidak selalu benar-benar silent di device ini  tetap memunculkan bottom-sheet "Signing you in" walau dipanggil dengan `promptIfNecessary: false`. Fix: `_triggerUpload()` sekarang cek `UserProfileRepository.get()` (cache lokal) dulu  kalau `null` (belum/tidak sign-in), return langsung, tidak pernah coba Drive sama sekali. Diverifikasi: beberapa kali cold-start berturut-turut di device nyata (uninstall+reinstall, WiFi nyala), nol popup, nol `AssistedSignInActivity`/`SignInCredentialChooserActivity` di logcat. **Pelajaran**: path lain manapun yang manggil `getDriveAuthClient`/`attemptLightweightAuthentication` di masa depan wajib guard pakai cache lokal dulu sebelum call  jangan andalkan `promptIfNecessary: false` saja sebagai satu-satunya pertahanan.

**Update (sesi berikutnya, 2026-08-07)  over-correction ditemukan, direvisi lagi**: setelah update di atas, sesi berikutnya (device 2-akun Google) masih menemukan popup "Signing you in" muncul sesekali tiap kill-app→buka lagi, padahal guard `UserProfileRepository.get()` sudah ada dan user memang sign-in (guard itu cuma menolong kasus belum sign-in, tidak menolong kasus ini). Fix waktu itu: `ConnectivityBackupNotifier._init()` diubah supaya **sama sekali tidak** cek status WiFi di cold start  cuma listen `onConnectivityChanged`, jadi trigger hanya nyala di transisi disconnected→connected yang genuinely terjadi selama sesi app berjalan. Efek sampingnya baru ketahuan sesi setelahnya: karena WiFi rumah/kantor pada umumnya memang **sudah** nyala sebelum app dibuka, transisi itu nyaris tidak pernah terjadi dalam pemakaian normal  auto-backup jadi nyaris tidak pernah jalan sama sekali (folder "Beatfy Backup" tidak pernah dibuat, 0 dari 17 lagu Pann ter-backup meski sudah sign-in + WiFi nyala + izin Drive granted). Analisis ulang: root cause popup yang sebenarnya kemungkinan besar bukan "dicek di cold start"-nya per se, tapi **dua panggilan `attemptLightweightAuthentication` yang jalan nyaris bersamaan** saat cold start  `RestoreGateNotifier.build()` (kalau box `songs` lokal kosong, mis. fresh install) dan `ConnectivityBackupNotifier._triggerUpload()` bisa sama-sama memanggil `AuthService.getDriveAuthClient()` di window waktu yang sama, dan Credential Manager di beberapa device tampaknya jatuh ke UI chooser kalau ada request lightweight-auth yang overlap. **Fix final (percobaan)**: `AuthService.getDriveAuthClient` diserialize lewat mutex (`_authLock`, antrian `Future` app-wide)  semua panggilan (WiFi trigger, restore gate, sign-in interaktif) dijamin tidak pernah overlap satu sama lain. Dengan itu, cek status WiFi di cold start (`_init()` di `ConnectivityBackupNotifier`) diaktifkan lagi.

**Update (QC device nyata, sesi sama, 2026-08-07)  teori mutex terbukti salah, keputusan final**: live QC di device Pann (Realme RMX3630, 2 akun Google) langsung setelah fix mutex di atas membuktikan popup "Choose an account for beatfy" (`SignInCredentialChooserActivity`) **tetap** muncul  dan bukan cuma sesekali, tapi di **setiap** cold start selagi WiFi nyala, dikonfirmasi 2x percobaan berturut-turut via `adb logcat`. Log membuktikan popup muncul walau cuma **satu** panggilan `attemptLightweightAuthentication` yang terjadi (bukan race dua panggilan)  jadi teori "concurrency adalah root cause" di update sebelumnya terbukti keliru. Kesimpulan yang benar: di device dengan 2+ akun Google, Android Credential Manager memang akan minta disambiguasi tiap kali ada panggilan `attemptLightweightAuthentication` yang **pertama di proses baru**  ini keterbatasan platform (perilaku native Google Play Services), bukan bug yang bisa diperbaiki dari sisi kode app manapun (mutex, guard sign-in, dsb tidak berpengaruh).

**Keputusan final (didiskusikan dengan Pann)**: trigger otomatis (baik cold-start check maupun listener `onConnectivityChanged`) **dihapus total**. Auto-backup diganti jadi tombol "Backup Sekarang" eksplisit di Settings (`_ManualBackupButton`, `ManualBackupNotifier`/`manualBackupProvider` di `providers/cloud_backup_providers.dart`)  `ConnectivityBackupNotifier`/`connectivityBackupProvider` dihapus dari codebase (termasuk `ref.watch` di `_RootGate`, `app.dart`). Rasionalnya: kalau popup akun memang tidak bisa dihindari di device tertentu, setidaknya biar muncul sebagai kelanjutan wajar dari aksi eksplisit user (tap tombol), bukan interupsi random tiap buka Home. Mutex di `AuthService.getDriveAuthClient` **tetap dipertahankan** (masih relevan buat `RestoreGateNotifier` yang jalan otomatis di cold start untuk kasus restore fresh-install, walau sekarang cuma satu automatic caller yang tersisa). **Pelajaran (revisi kedua)**: sebelum mengasumsikan root cause dari sekadar analisis kode/dokumentasi lama, verifikasi ulang di device nyata  asumsi "sudah pernah diverifikasi sebelumnya" dari sesi lalu bisa jadi tidak lagi berlaku persis sama begitu detail teknisnya (concurrency vs single-call) belum benar-benar diuji ulang.

## 5. Output Detection (Bluetooth/Wired)

Bukan fitur kosmetik  harus benar-benar berfungsi:

- Listen ke `AudioDeviceCallback`/platform channel event untuk connect-disconnect audio output.
- Auto-pause saat output device (headset Bluetooth/wired) disconnect saat sedang playing (standard Android media behavior, mencegah audio tiba-tiba keluar dari speaker HP).
- Info state output aktif (headset/speaker) tersedia di provider untuk ditampilkan di UI kalau relevan (misal indikator kecil di Now Playing).
- Tidak ada logic device-specific (Sony atau merek lain)  general Android AudioManager API saja.

## 6. Data Flow  Library Scan

1. `AudioQueryService.scan()` dipanggil saat app pertama kali dibuka + manual refresh trigger.
2. Ambil raw list dari MediaStore (Audio collection + Downloads folder filter).
3. Tiap item lewat `TitleCleaner`  strip noise text, split "Artist - Title" kalau field artist kosong/"<unknown>".
4. Hasil bersih disimpan sebagai cache di Hive (`songs` box) dengan timestamp scan terakhir.
5. Scan berikutnya: incremental  bandingkan `dateModified`/`id` MediaStore vs cache, jangan proses ulang semua dari nol tiap buka app.

## 7. Cloud Sync Architecture (v2  desain awal, detail difinalisasi saat v2 mulai)

- Auth: Google Sign-In → OAuth token untuk scope Drive (`drive.file`, akses hanya ke file yang dibuat app, bukan full Drive akses).
- **Setup Google Cloud Console (2026-08-07)**: butuh 2 OAuth Client ID  tipe **Web application** (Client ID-nya yang diisi ke `serverClientId` di `auth_service.dart`) dan tipe **Android** (package `com.anandabint.beatfy` + SHA-1 debug keystore, tidak masuk kode, cuma buat verifikasi signature). OAuth consent screen wajib di-**Publish** (status Production, bukan Testing) supaya refresh token tidak expired tiap 7 hari  konsekuensinya user lihat warning "unverified app" sekali saat consent pertama, itu normal untuk app personal belum lolos Google verification, klik lanjut saja. Detail langkah manual di `docs/CloudSetup.md`.
- Upload: file MP3 di-upload ke folder khusus (`Beatfy Backup`) di Drive user. **Revisi final (2026-08-07, lihat § 4c)**: bukan trigger otomatis berbasis WiFi lagi (dihapus karena memicu popup akun yang tidak bisa dihindari di device dengan 2+ akun Google)  sekarang tombol "Backup Sekarang" eksplisit di Settings.
- Restore: saat login pertama kali di device (Hive local kosong tapi akun Drive punya folder Beatfy Backup), tampilkan progress download semua file sebelum user masuk ke library penuh.
- Cloud tetap **bukan** sumber playback  begitu file terdownload ke local cache, playback selalu baca dari local, sama seperti v1.

## 7a. Audio Enhancement (v2, best-effort, ditambahkan 2026-08-07)

Tujuan: MP3 kualitas biasa tetap terdengar baik, tanpa UI equalizer manual (tetap minimalist, § PRD 9 & 11). Pendekatan: Android native `android.media.audiofx`  `LoudnessEnhancer` (normalisasi file yang terasa pelan/lemah), `Equalizer` (preset ringan clarity/warmth, bukan drastis), `BassBoost` (ringan, hindari distorsi di file bitrate rendah). Effect-effect ini nempel ke `audioSessionId` milik player yang aktif.

**Wajib riset dulu sebelum implementasi penuh**: cek apakah `just_audio` (versi yang dipakai project ini) expose `androidAudioSessionId` dengan stabil. Kalau ya, pasang effect lewat platform channel kecil (native Kotlin) yang terima session id dari Dart. Kalau ternyata tidak reliable/butuh workaround berat (fork plugin, dsb), **laporkan dulu ke Pann sebelum lanjut**  fitur ini eksplisit ditandai best-effort di PRD § 11, boleh disederhanakan atau ditunda kalau risikonya tidak sepadan.

Default preset harus konservatif (loudness naik moderat, EQ/bass boost ringan)  file MP3 rendah-bitrate gampang terdengar pecah/distorsi kalau effect terlalu agresif, uji dengan telinga di device nyata, bukan cuma angka default library.

## 9. Hardening Rilis Publik (ditambahkan 2026-08-08)

Beatfy rencana di-hosting di GitHub untuk diinstall orang lain (bukan cuma Pann). Kekhawatiran Pann: integrasi Google bikin user lain curiga/takut soal privasi & keamanan. Analisis: arsitektur sign-in yang dipakai app ini **sudah aman by design**  scope `drive.file` cuma kasih akses ke file yang dibuat app itu sendiri, bukan seluruh Drive user, dan tidak ada server Beatfy yang menyimpan data siapapun (sudah tercermin di teks Privasi § Settings). Yang perlu diperkuat adalah **kepercayaan lewat transparansi**, bukan mengubah arsitektur sign-in:

1. **Audit secret sebelum publish repo**: pastikan tidak ada yang ke-commit selain OAuth **Client ID** (itu memang public-safe by design, bukan secret)  cek tidak ada Client Secret, API key lain, atau file `keystore.properties`/`.jks` ter-commit (sudah ada aturan ini di Rules.md § 6, tapi wajib di-cek ulang eksplisit sebelum repo publik).
2. **Release keystore asli** (bukan debug keystore) untuk APK yang didistribusikan  dokumentasikan SHA-256 fingerprint APK release di README, supaya user yang download bisa verifikasi APK yang mereka install memang genuinely dari build resmi, bukan APK yang sudah dimodifikasi orang lain.
3. **README transparan**: jelaskan singkat data apa yang diakses (mirror teks Privasi di app), bahwa app open source jadi siapapun bisa audit sendiri kodenya, dan bahwa peringatan "Google hasn't verified this app" saat login itu NORMAL untuk app open-source personal yang belum lewat proses verifikasi bisnis Google  bukan indikasi malware.
4. Login Google tetap opsional (skip tersedia sejak Onboarding)  user yang tidak nyaman tetap bisa pakai semua fitur inti (playback offline) tanpa sign-in sama sekali.

## 9a. Keputusan Ditolak  Native Audio Low-Level Tuning (2026-08-08)

Dua usulan berikut dipertimbangkan tapi **ditolak** untuk sesi ini, didokumentasikan supaya tidak diusulkan ulang tanpa konteks baru:

- **`AUDIO_OUTPUT_FLAG_FAST`/`AUDIO_OUTPUT_FLAG_DEEP_BUFFER` via method channel custom**: ExoPlayer (dipakai `just_audio` di balik layar) sudah otomatis memilih `AudioAttributes`/`AudioTrack` flag yang sesuai untuk playback musik standar (termasuk deep-buffer untuk efisiensi baterai). Flag `FAST` ditujukan untuk use-case latency-kritis (game, live audio processing)  tidak relevan untuk pemutar MP3 buffered biasa. Tidak ada gejala nyata (delay/glitch) yang dilaporkan Pann yang membenarkan kompleksitas dan risiko native code tambahan ini.
- **AutoEQ database + FIR filter per model headset kabel**: secara teknis valid (dipakai app seperti Wavelet), tapi scope-nya besar  butuh UI pemilihan model headset (bertentangan dengan keputusan "tanpa UI equalizer manual" yang sudah final di § 7a), bundling database pengukuran ribuan headset, dan implementasi FIR convolution yang tidak difasilitasi langsung oleh `just_audio`. Kalau Pann suatu saat serius ingin fitur ini, perlakukan sebagai proyek terpisah (semacam "v3"), bukan bagian polish akhir.

## 7b. Polish Teknis Sesi Finalisasi (2026-08-08)

- **Artwork fallback gradient dinamis**: Design.md sudah lama menyebut "placeholder gradient hash-based per artist/album" tapi Pann laporkan di Search screen semua lagu tanpa artwork tampil hijau seragam  audit kenapa (kemungkinan logic-nya cuma ada di satu tempat/screen, tidak dipakai konsisten di semua song row). Fix: satu widget/helper reusable (`ArtworkFallback` atau sejenis) yang generate gradient dari hash string (judul+artis) dipetakan ke daftar pasangan warna gradient yang sudah dikurasi supaya tetap cocok tema gelap (bukan hue acak penuh yang bisa jadi norak)  dipakai di SEMUA tempat yang render art (song row semua tab, Now Playing, mini player, playlist cover).
- **Ikon status backup per song row**: ikon kecil (cloud-check untuk `CloudBackupRecord.backupStatus == done`, tanpa ikon/cloud-outline tipis untuk selain itu)  subtle, jangan mendominasi row. Data sudah ada (`CloudBackupRecord`), murni tampilan.
- **Dynamic ambient color Now Playing**: tambah package `palette_generator`, ekstrak dominant color dari artwork lagu yang sedang main, dipakai gantikan warna blob ungu-pink statis (§ Design.md § 1/§ 7 Now Playing)  kalau lagu tidak punya artwork atau ekstraksi gagal, fallback ke blob ungu-pink default seperti sekarang. Cache hasil ekstraksi di memory per `songId` (`Map<int, PaletteGenerator>` atau sejenis, tidak perlu persist ke Hive) supaya tidak re-compute tiap kali lagu yang sama diputar ulang dalam satu sesi app.
- **Gapless playback  verifikasi, bukan fitur baru**: cek queue management (`queue_manager.dart`) sudah pakai `ConcatenatingAudioSource` (atau API `just_audio` versi terbaru yang setara) secara konsisten untuk semua lagu di queue, terlepas dari asal lagu (lokal asli/hasil restore Drive  keduanya sama-sama file lokal biasa di titik playback, tidak ada perlakuan beda). Test dengar langsung transisi antar lagu di device, pastikan tidak ada jeda/klik terdengar.
- **App icon**: pakai `logo.png` (ada di root folder project, 1254×1254, tanpa alpha channel) via package `flutter_launcher_icons`  generate adaptive icon + legacy icon otomatis, jangan resize manual.

## 7c. Kualitas Output Audio  Bluetooth Memendam + Volume/Bas Lemah (KRITIS, ditambahkan 2026-08-08)

Pann laporkan: (a) suara "memendam" di headset Bluetooth manapun, (b) lewat speaker internal HP, volume+bas kalah jauh dari YouTube/Telegram/pemutar musik lain walau volume sudah maksimal. Ini prioritas tertinggi (lihat Rules.md § 3)  masalah kualitas inti, bukan polish.

**Hipotesis A  Bluetooth memendam (kemungkinan besar salah routing profil)**: gejala khas audio kena rute lewat profil suara panggilan (SCO/HFP  mono, ~8kHz bandwidth, terdengar "memendam") bukan profil media (A2DP  stereo, full-bandwidth), biasanya terjadi kalau `AudioAttributes`/`AndroidAudioAttributes` pada audio session (`audio_service`/`just_audio`) tidak eksplisit di-set `usage: media` + `contentType: music`. Cek konfigurasi ini di `audio_handler.dart`/inisialisasi `AudioService.init()` (parameter `androidNotificationChannelId` biasanya sudah benar, tapi `AndroidAudioAttributes` untuk player itu terpisah, sering kelewat di-set eksplisit dan jatuh ke default yang tidak konsisten di semua device). Perbaiki supaya eksplisit di-set ke media/musik, test di headset Bluetooth device Pann, dengarkan langsung apakah full-bandwidth (jernih, ada detail treble) atau masih narrowband (memendam, seperti telepon).

**Hipotesis B  Volume/bas lemah di speaker**:
1. Cek slider volume custom (ditambahkan sesi sebelumnya)  pastikan itu benar-benar kontrol **volume sistem** (`AudioManager.STREAM_MUSIC`, via platform channel atau package volume control yang proper), BUKAN cuma `AudioPlayer.setVolume()` (gain software 0.0-1.0, "1.0" di situ cuma level rekaman asli, tidak bisa melebihi itu  beda konsep total dari volume sistem/hardware). Kalau ternyata cuma software gain, itu salah satu penyebab kenapa "sudah maksimal" tapi masih kalah keras dari app lain.
2. Cek status implementasi Audio Enhancement (`LoudnessEnhancer`/`Equalizer`/`BassBoost`, dari sesi sebelumnya, § 7a)  **konfirmasi eksplisit apakah ini benar-benar ter-attach dan aktif saat playback** (bukan cuma ter-kode tapi gagal diam-diam/exception ke-swallow). Kalau memang aktif tapi preset-nya dibuat sangat konservatif (sengaja, biar tidak distorsi di MP3 rendah), sekarang **naikkan intensitasnya secara terukur** (loudness + bass boost sedikit lebih agresif dari sebelumnya) sampai terasa sepadan dengan app pembanding (YouTube/Telegram) saat didengar langsung di device  tapi tetap uji dengan telinga di beberapa lagu kualitas beda-beda, jangan sampai jadi pecah/distorsi di file bitrate rendah demi mengejar kencang.

**Hasil implementasi (2026-08-08)**: Root cause Bluetooth dikonfirmasi  `AudioSession.instance` tidak pernah dikonfigurasi eksplisit; `just_audio` cuma set attribute secara lazy saat `play()` pertama (race condition, tidak konsisten). Fix: `AudioSessionConfiguration.music()` (usage media, contentType music) di-set eksplisit di `main.dart` sebelum playback apapun dimulai. Volume slider  ternyata **sudah** kontrol `STREAM_MUSIC` asli sejak awal (dugaan hipotesis B.1 tidak terbukti, bukan penyebabnya). Audio enhancement  dikonfirmasi aktif via logcat (`loudness=6dB, bands=5, range=-15..15dB`), preset dinaikkan dari 3dB ke 6dB (loudness & bass). **Belum diverifikasi telinga langsung oleh siapapun** (Claude Code tidak bisa dengar)  A/B test manual Pann terhadap headset Bluetooth & YouTube Music di speaker masih wajib sebelum item ini benar-benar dianggap tuntas.

## 7d. Search Keyboard Gap  Diagnosis Presisi (2026-08-08, round 3)

Round sebelumnya (round 2) sempat disimpulkan "bukan bug, cuma ListView pendek natural kosong" berdasar test dengan query hasil sedikit. Pann buktikan dengan query hasil BANYAK (list panjang)  gap tetap muncul, kesimpulan round 2 itu keliru/prematur. Setelah baca `search_screen.dart` langsung: `resultsBottomPadding` di-set ke angka **tetap** (`AppSpacing.sm`, ~8px) saat keyboard terbuka, bukan proporsional ke `MediaQuery.viewInsets.bottom` (tinggi keyboard asli, bisa ratusan pixel). Ditambah `SearchScreen` punya `Scaffold` sendiri bersarang di dalam `MainShell` yang sudah `resizeToAvoidBottomInset: false`  kombinasi ini rawan bikin resize tidak proporsional konsisten.

**Fix (final, precise)**: (1) `SearchScreen`'s `Scaffold` di-set eksplisit `resizeToAvoidBottomInset: false` juga (konsisten dengan filosofi `MainShell`  jangan andalkan auto-resize implisit dari nested Scaffold, terlalu rawan). (2) `resultsBottomPadding` saat keyboard terbuka diubah dari flat `AppSpacing.sm` jadi `MediaQuery.of(context).viewInsets.bottom + AppSpacing.sm`  proporsional ke tinggi keyboard asli, bukan angka tebakan.

## 7e. MiniPlayer Menutupi Baris Terakhir List (2026-08-08, superseded  lihat § 3a)

Bukan bug "song row aktif" seperti kelihatan sekilas  `SongRow.active` cuma ganti warna teks (lihat `song_row.dart`), tidak ada pill/shuffle/tombol play. Yang tertutup itu `MiniPlayer` (elemen persisten begitu ada lagu ter-load) menimpa baris terakhir Library/Home.

**Pendekatan awal (dibatalkan)**: kalibrasi konstanta `AppSpacing.floatingNavClearance` per-screen. **Diganti (2026-08-08, sama hari)** dengan fix arsitektural yang lebih bersih di § 3a  pakai `Scaffold.bottomNavigationBar` + `extendBody: true` alih-alih `Column` manual, meniru pola Planly yang memang didesain supaya body tidak pernah perlu hitung padding manual buat clearance nav. Kalau fix § 3a sudah jalan, JANGAN tambah konstanta padding manual lagi di Library/Home/Playlist  itu justru gejala arsitektur yang salah, bukan solusinya.

## 8. QC & Device Testing Loop (wajib tiap sesi Claude Code)

1. Build & install ke device nyata Pann via `adb install` (USB debugging).
2. Jalankan `adb logcat` filter package `com.anandabint.beatfy`, cek crash/exception saat testing manual.
3. Ambil `adb shell screencap` untuk verifikasi visual tiap perubahan UI signifikan.
4. Test manual skenario kritis: play → minimize → buka lagi (cek posisi), play → kill app dari recent apps → buka lagi (cek restore), connect/disconnect Bluetooth saat playing.
5. Bug apapun yang ditemukan (bukan cuma yang sudah diketahui) wajib diperbaiki sebelum sesi dianggap selesai  lihat Rules.md § Definition of Done.
