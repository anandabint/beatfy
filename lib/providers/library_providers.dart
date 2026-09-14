import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/repositories/library_repository.dart';
import '../models/library_group.dart';
import '../models/song.dart';
import '../services/permission_service.dart';

export '../services/permission_service.dart' show LibraryPermissionStatus;

/// Di-override di main() dengan instance yang sama dipakai AudioHandler saat
/// restore (Architecture.md § 2  repository sebagai satu-satunya jalur data).
final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  throw UnimplementedError(
    'libraryRepositoryProvider must be overridden in main()',
  );
});

/// Status permission akses audio  dicek begitu provider ini pertama dibaca
/// (dipicu saat LibraryScreen pertama kali dibuka), diminta otomatis kalau
/// belum granted (PRD.md § 6.9, Rules.md § 7).
class LibraryPermissionNotifier extends AsyncNotifier<LibraryPermissionStatus> {
  @override
  Future<LibraryPermissionStatus> build() async {
    final status = await PermissionService.checkStatus();
    if (status == LibraryPermissionStatus.granted) return status;
    return PermissionService.request();
  }

  Future<void> requestAgain() async {
    state = const AsyncLoading();
    state = AsyncData(await PermissionService.request());
  }

  Future<void> openSettings() => PermissionService.openSettings();
}

final libraryPermissionProvider =
    AsyncNotifierProvider<LibraryPermissionNotifier, LibraryPermissionStatus>(
      LibraryPermissionNotifier.new,
    );

/// Daftar lagu. Kalau cache Hive sudah ada langsung tampil dari situ; kalau
/// kosong (buka pertama kali) langsung scan (Architecture.md § 6).
class LibrarySongsNotifier extends AsyncNotifier<List<Song>> {
  @override
  Future<List<Song>> build() async {
    final permission = await ref.watch(libraryPermissionProvider.future);
    if (permission != LibraryPermissionStatus.granted) return const [];

    final repository = ref.watch(libraryRepositoryProvider);
    final cached = repository.getCachedSongs();
    // Rescan sekali kalau ada entry lama tanpa `dataPath` (migrasi
    // self-healing setelah field itu ditambah  Schema.md § 2)  murni
    // MediaStore query lokal, bukan network, jadi aman dijalankan otomatis.
    final needsBackfill = cached.any((song) => song.dataPath == null);
    if (cached.isNotEmpty && !needsBackfill) return cached;
    return repository.scan();
  }

  /// Manual refresh trigger (Architecture.md § 6 poin 1).
  Future<void> rescan() async {
    final repository = ref.read(libraryRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(repository.scan);
  }

  /// Buang satu lagu dari state lokal tanpa re-scan MediaStore  dipakai
  /// setelah real file delete sukses (Architecture.md § 4a). Update instan
  /// lewat state di sini (bukan nunggu rescan) supaya tidak race dengan
  /// jeda index MediaStore setelah delete request.
  void removeLocally(int songId) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.where((song) => song.id != songId).toList());
  }
}

final librarySongsProvider =
    AsyncNotifierProvider<LibrarySongsNotifier, List<Song>>(
      LibrarySongsNotifier.new,
    );

/// Opsi sort library  PRD.md § 6.8 ("Sort by title/artist/tanggal ditambahkan").
enum LibrarySortOption { title, artist, dateAdded }

final librarySortOptionProvider = StateProvider<LibrarySortOption>(
  (ref) => LibrarySortOption.title,
);

/// [librarySongsProvider] yang sudah diurutkan sesuai [librarySortOptionProvider].
/// Sort murni di memori  tidak menyentuh Hive/MediaStore lagi.
final sortedLibrarySongsProvider = Provider<AsyncValue<List<Song>>>((ref) {
  final songsAsync = ref.watch(librarySongsProvider);
  final sortOption = ref.watch(librarySortOptionProvider);
  return songsAsync.whenData((songs) => _sortSongs(songs, sortOption));
});

/// Filter Library tab  section/filter Favorites di dalam tab (bukan tab
/// terpisah), PRD.md § 7 poin 2. Empat opsi visual sesuai Design.md § 7
/// (revisi 2026-08-06), tapi cuma dua yang punya filtering nyata: `all` dan
/// `downloads` (semua file memang sudah lokal, jadi "downloads" == semua)
/// menampilkan seluruh lagu; `playlists` juga menampilkan semua lagu untuk
/// saat ini (grouping per-playlist di Library adalah kandidat sesi
/// browse-by-album/artist/folder berikutnya, bukan scope re-skin ini);
/// `likedSongs` menampilkan favorit saja (pengganti nama `favorites` lama).
enum LibraryFilter {
  all,
  playlists,
  likedSongs,
  downloads,
  albums,
  artists,
  folders,
}

/// Filter yang mengubah tampilan jadi grouped row (PRD.md § 7 poin 6),
/// bukan filter lagu flat biasa.
bool isGroupingFilter(LibraryFilter filter) =>
    filter == LibraryFilter.albums ||
    filter == LibraryFilter.artists ||
    filter == LibraryFilter.folders;

final libraryFilterProvider = StateProvider<LibraryFilter>(
  (ref) => LibraryFilter.all,
);

/// Grouped rows buat filter Albums/Artists/Folders  hanya dihitung kalau
/// filter aktif memang salah satu dari itu (Rules.md § 5  grouping logic
/// tetap di repository, provider ini cuma nyambungin).
final libraryGroupsProvider = Provider<AsyncValue<List<LibraryGroup>>>((ref) {
  final songsAsync = ref.watch(librarySongsProvider);
  final filter = ref.watch(libraryFilterProvider);
  final repository = ref.watch(libraryRepositoryProvider);

  return songsAsync.whenData((songs) {
    switch (filter) {
      case LibraryFilter.albums:
        return repository.groupByAlbum(songs);
      case LibraryFilter.artists:
        return repository.groupByArtist(songs);
      case LibraryFilter.folders:
        return repository.groupByFolder(songs);
      case LibraryFilter.all:
      case LibraryFilter.playlists:
      case LibraryFilter.likedSongs:
      case LibraryFilter.downloads:
        return const <LibraryGroup>[];
    }
  });
});

List<Song> _sortSongs(List<Song> songs, LibrarySortOption option) {
  final sorted = [...songs];
  switch (option) {
    case LibrarySortOption.title:
      sorted.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    case LibrarySortOption.artist:
      sorted.sort((a, b) {
        final byArtist = a.artist.toLowerCase().compareTo(
          b.artist.toLowerCase(),
        );
        return byArtist != 0
            ? byArtist
            : a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    case LibrarySortOption.dateAdded:
      sorted.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
  }
  return sorted;
}
