# Schema — Beatfy

Struktur data lokal (Hive) dan model. Turunan dari Architecture.md § 3, § 6.

## 1. Prinsip

- Hive box per entity, typeId unik per adapter — jangan reuse/overlap typeId antar model (bug klasik Hive kalau sembarangan).
- Semua model pakai `@HiveType`/`@HiveField` (code-gen via `hive_generator` + `build_runner`, sama pola dengan Planly `.g.dart`).
- Field yang sifatnya cache (hasil scan MediaStore) dipisah dari field yang sifatnya data user-generated (favorite, playlist, play stats) — supaya re-scan tidak pernah menghapus data user.

## 2. v1 — Model Wajib

### `Song` (typeId: 0) — box `songs`

Cache hasil scan MediaStore, sumber: `on_audio_query` + `TitleCleaner`.

| Field | Tipe | Keterangan |
|-------|------|------------|
| `id` | `int` | MediaStore audio id — primary key |
| `title` | `String` | Judul sudah dibersihkan (TitleCleaner) |
| `artist` | `String` | Artis, hasil split kalau tag kosong |
| `album` | `String?` | Nullable — bisa kosong |
| `duration` | `int` | Milliseconds |
| `filePath` | `String` | URI/path MediaStore, untuk load ke just_audio |
| `dateAdded` | `DateTime` | Dari MediaStore, dipakai sort "recently added" (v2) |
| `dateModified` | `int` | Timestamp MediaStore, dipakai deteksi incremental scan |
| `albumArtId` | `int?` | Reference artwork, di-load via `on_audio_query` artwork API |
| `source` | `enum SongSource { mediaStoreScan }` | v2 nanti nambah `cloudRestored` |
| `dataPath` | `String?` | **Ditambahkan sesi browse Album/Artist/Folder (2026-08-07)**: real filesystem path (MediaStore `_data`), beda dari `filePath` yang selalu `content://` URI. Dibutuhkan buat folder grouping (ambil folder terakhir sebelum nama file) — `filePath` tidak bisa dipakai karena bukan path asli. Best-effort/nullable (bisa kosong di beberapa kasus scoped storage), lagu tanpa `dataPath` masuk bucket "Lainnya" saat grouping folder. Field baru (`@HiveField(10)`, additive, bukan reindex) — cache lama otomatis di-backfill lewat rescan sekali (lihat `LibrarySongsNotifier`), tidak butuh migrasi manual. |

### `PlaybackStateCache` (typeId: 1) — box `playback_state` (single entry, key `'current'`)

Ini yang jadi kunci fix bug pause-resume. Ditulis setiap event penting (lihat Architecture.md § 4), bukan hanya saat app pause.

| Field | Tipe | Keterangan |
|-------|------|------------|
| `currentSongId` | `int?` | Null kalau tidak ada sesi aktif |
| `positionMs` | `int` | Posisi playback terakhir |
| `queueSongIds` | `List<int>` | Urutan queue saat ini |
| `queueIndex` | `int` | Index lagu aktif dalam queue |
| `shuffleEnabled` | `bool` | |
| `repeatMode` | `enum RepeatMode { off, one, all }` | |
| `isPlaying` | `bool` | Status playing terakhir saat persist — **bukan** dipakai untuk auto-resume (restore selalu paused, keputusan final PRD.md § 11). Disimpan untuk akurasi data; di-reset ke `false` juga saat restore supaya konsisten dengan status nyata. |
| `updatedAt` | `DateTime` | Untuk debug/validasi staleness |

## 3. v2 — Model Tambahan (dibangun setelah v1 stabil, didaftarkan di sini agar typeId sudah dialokasikan sejak awal)

### `Playlist` (typeId: 2) — box `playlists`

| Field | Tipe | Keterangan |
|-------|------|------------|
| `id` | `String` (uuid) | Sama pola Planly (pakai package `uuid`) |
| `name` | `String` | |
| `songIds` | `List<int>` | Urutan lagu dalam playlist |
| `createdAt` | `DateTime` | |
| `coverSongId` | `int?` | Lagu yang artwork-nya dipakai sebagai cover playlist |

### `Favorite` (typeId: 3) — box `favorites`

| Field | Tipe | Keterangan |
|-------|------|------------|
| `songId` | `int` | Key = songId, cukup Set-like box |
| `addedAt` | `DateTime` | |

### `PlayStats` (typeId: 4) — box `play_stats`

| Field | Tipe | Keterangan |
|-------|------|------------|
| `songId` | `int` | Key |
| `playCount` | `int` | Increment tiap lagu selesai diputar >50% durasi (definisi "played" — final saat implementasi v2) |
| `lastPlayedAt` | `DateTime` | |

### `CloudBackupRecord` (typeId: 5) — box `cloud_backup`

**Diimplementasikan sesi cloud backup (2026-08-07).** Key box = `songId` (satu record per lagu, bukan list).

| Field | Tipe | Keterangan |
|-------|------|------------|
| `songId` | `int` | |
| `driveFileId` | `String?` | Null = belum ter-upload |
| `backupStatus` | `enum BackupStatus { pending, uploading, done, failed }` (typeId 9) | |
| `lastAttemptAt` | `DateTime?` | |

### `CloudBackupMeta` (typeId: 10) — box `cloud_backup_meta` (single entry, key `'current'`)

**Baru, sesi cloud backup (2026-08-07).** Sama pola single-entry dengan `PlaybackStateCache`/`UserProfileCache`.

| Field | Tipe | Keterangan |
|-------|------|------------|
| `driveFolderId` | `String?` | Id folder "Beatfy Backup" di Drive user, di-cache supaya tidak query pencarian folder tiap upload |
| `autoBackupEnabled` | `bool` | Toggle di Settings screen, default `true` |

### `UserProfileCache` (typeId: 8) — box `user_profile` (single entry, key `'current'`)

Cache lokal akun Google, ditulis Claude Code sesi 2026-08-07 saat memajukan sign-in dari scope v2 (dikonfirmasi Pann) — dipakai murni untuk personalisasi greeting Home ("Hi, [nama]"), belum untuk auth Drive backup (itu tetap menyusul di v2 penuh). Box kosong = user belum/tidak sign-in, bukan error state.

| Field | Tipe | Keterangan |
|-------|------|------------|
| `displayName` | `String?` | Nama lengkap dari akun Google, kata pertamanya dipakai sebagai nama panggilan di Home header |
| `email` | `String` | |
| `photoUrl` | `String?` | **Ditambahkan sesi onboarding (2026-08-07)**: dari `GoogleSignInAccount.photoUrl`, dipakai untuk avatar asli (Design.md § 7 "Avatar/foto profil"). Nullable — sebagian akun Google tidak punya foto. Field baru (`@HiveField(2)`, additive, bukan reindex), disimpan cuma saat sign-in eksplisit sukses, konsisten dengan aturan no-live-call-at-startup (Architecture.md § 4c). |

### `AppPreferences` (typeId: 11) — box `app_preferences` (single entry, key `'current'`)

Ditambahkan 2026-08-07 untuk flag onboarding.

| Field | Tipe | Keterangan |
|-------|------|------------|
| `hasSeenOnboarding` | `bool` | Default `false`. Set `true` setelah user selesai atau tap "Lewati" di halaman sign-in akhir onboarding. Onboarding tidak tampil lagi setelah ini, terlepas status login. |

## 4. Alokasi typeId (wajib dicek sebelum tambah model baru)

| typeId | Model | Versi |
|--------|-------|-------|
| 0 | Song | v1 |
| 1 | PlaybackStateCache | v1 |
| 2 | Playlist | v2 |
| 3 | Favorite | v2 |
| 4 | PlayStats | v2 |
| 5 | CloudBackupRecord | v2 — diimplementasikan 2026-08-07 |
| 6 | `SongSource` (enum, field `Song.source`) | v1 |
| 7 | `RepeatMode` (enum, field `PlaybackStateCache.repeatMode`) | v1 |
| 8 | UserProfileCache | v2 (sign-in dimajukan, sesi 2026-08-07) |
| 9 | `BackupStatus` (enum, field `CloudBackupRecord.backupStatus`) | v2 — 2026-08-07 |
| 10 | CloudBackupMeta | v2 — 2026-08-07 |
| 11 | AppPreferences | v2 — flag onboarding, ditambahkan 2026-08-07 |

**Update (playback session, 2026-08-05)**: Hive butuh typeId sendiri untuk setiap `@HiveType`, termasuk enum yang dipakai sebagai field type (`SongSource`, `RepeatMode`) — bukan cuma class model. Dialokasikan 6 dan 7, lanjut setelah jatah v2 (2–5) supaya tidak tabrakan kalau model v2 mulai diimplementasikan nanti.

**Update (2026-08-07)**: `UserProfileCache` dialokasikan typeId 8 (lanjut urut setelah 7, sesuai aturan § 4) untuk cache akun Google — ditambahkan lebih awal dari rencana v2 penuh karena Pann minta greeting personal dimajukan (bukan cloud backup-nya, itu masih nunggu v2).

**Update (cloud backup session, 2026-08-07)**: `CloudBackupRecord` (typeId 5, reserved sejak awal) diimplementasikan, plus 2 typeId baru: 9 (`BackupStatus` enum) dan 10 (`CloudBackupMeta`, cache id folder Drive + toggle auto-backup). `Song` juga dapat field baru (`dataPath`, lihat § 2) tapi itu tidak butuh typeId baru (field tambahan pada typeId yang sudah ada, bukan model baru).

Model baru di luar daftar ini pakai typeId 11 ke atas, urut, dicatat di tabel ini juga — jangan pernah reuse typeId yang sudah pernah dipakai meski modelnya sudah dihapus (breaking change untuk data existing user).

## 5. Non-Hive Data

- File MP3 aktual: tetap di storage Android asli (Music/Download folder), **tidak** disalin ke app-private storage di v1 (karena pakai auto-scan MediaStore, bukan import-copy).
- Artwork: tidak disimpan sebagai file terpisah, selalu di-load on-demand dari `on_audio_query` artwork API (embedded tag), di-cache di memory (`CachedNetworkImage`-style tapi lokal) bukan di Hive (Hive bukan tempat yang tepat untuk binary image besar).
- **File hasil restore Drive (2026-08-07, keputusan dilaporkan ke Pann)**: ditulis ke koleksi Audio **publik** (`MediaStore.Audio.Media`, `RELATIVE_PATH = Music/Beatfy`) lewat `ContentResolver.insert` (native channel, sama pola dengan `deleteMediaFiles` di Architecture.md § 4a) — **bukan** app-private storage. Alasan: MediaStore tidak pernah mengindex folder app-private, jadi "jalankan scan lokal biasa" setelah restore (PRD.md § 7 poin 5) hanya bisa menemukan file kalau file itu benar-benar masuk MediaStore. Konsekuensi baiknya: tidak perlu `SongSource.cloudRestored`/id sintetis — begitu file di-insert, `AudioQueryService.scan()` biasa langsung mengenalinya sebagai lagu normal, lewat jalur yang sama persis dengan lagu yang sudah ada dari awal.
