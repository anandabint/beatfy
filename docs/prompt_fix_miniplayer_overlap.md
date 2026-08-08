# Prompt Claude Code — Fix Presisi: MiniPlayer Menutupi Baris Terakhir List

Saya sudah baca `song_row.dart`, `library_screen.dart`, `mini_player.dart`, `home_screen.dart` langsung. Ini bukan bug "row aktif" seperti kelihatannya di screenshot Pann — `SongRow` saat `active: true` cuma ganti warna teks, tidak ada pill/shuffle/tombol play. Yang Pann lihat overlap itu **`MiniPlayer`** (elemen persisten yang muncul begitu ada lagu ter-load) menutupi baris terakhir yang terlihat di list Library.

**Root cause presisi**: `Library` (`library_screen.dart` baris ~108) dan `Home` (`home_screen.dart` baris ~60) sama-sama pakai `padding: EdgeInsets.only(bottom: AppSpacing.xxxl)` untuk `ListView`, dan `AppSpacing.xxxl` cuma **48px**. Sementara `MiniPlayer` (`mini_player.dart`) + `_BottomNavBar` (`main_shell.dart`) yang keduanya floating di atas list, kalau digabung tinggi totalnya sekitar 150-160px (MiniPlayer ~80px + BottomNavBar ~68px + gap). 48px jauh dari cukup — makanya baris terakhir list ketutup separuh badan tiap ada lagu aktif (MiniPlayer nambah ~80px yang tidak pernah diperhitungkan di padding).

## Fix

1. Tambah konstanta baru di `lib/core/theme/app_spacing.dart`, misal `floatingNavClearance` — nilai awal ~160.0 (perkiraan saya dari estimasi tinggi MiniPlayer+BottomNavBar+gap, **wajib diverifikasi/dikalibrasi ulang oleh Claude Code** dengan ukur tinggi asli kedua widget itu di device nyata, jangan cuma percaya angka perkiraan saya).
2. Ganti `AppSpacing.xxxl` jadi `AppSpacing.floatingNavClearance` untuk bottom padding `ListView` di:
   - `library_screen.dart` (`_SongList`, dan cek juga `_GroupList` buat filter Albums/Artists/Folders — kemungkinan bug sama di situ).
   - `home_screen.dart` (list mana pun yang sama-sama duduk di belakang MiniPlayer+BottomNavBar).
3. Cek `playlist_list_screen.dart` juga — pakai variabel `bottomInset` yang beda (baris ~295), audit apakah itu sudah benar menghitung clearance MiniPlayer+BottomNavBar juga atau cuma untuk kasus lain (misal keyboard). Samakan pendekatannya kalau ternyata clearance-nya juga kurang.
4. Reserve clearance ini **selalu** (tidak usah dibedakan ada lagu aktif atau tidak) — lebih simpel dan robust daripada watch provider buat tau MiniPlayer nongol atau tidak, konsekuensinya cuma sedikit whitespace ekstra di bawah list saat belum ada lagu diputar, itu trade-off yang wajar.

## QC

Device nyata wajib: scroll Library sampai baris paling akhir SAAT ada lagu sedang diputar (MiniPlayer showing) — pastikan baris terakhir terlihat utuh, tidak ketutup MiniPlayer/BottomNavBar sama sekali. Ulangi untuk Home. Screenshot before/after.
