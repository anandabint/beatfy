import 'package:hive_ce/hive_ce.dart';
import 'package:path/path.dart' as p;

import '../../models/library_group.dart';
import '../../models/song.dart';
import '../library/audio_query_service.dart';
import '../library/title_cleaner.dart';
import '../local/hive/hive_setup.dart';

/// Sumber kebenaran library lagu — UI selalu lewat sini, tidak pernah baca
/// Hive/MediaStore langsung (Architecture.md § 2).
class LibraryRepository {
  LibraryRepository({AudioQueryService? audioQueryService, Box<Song>? songsBox})
    : _audioQueryService = audioQueryService ?? AudioQueryService(),
      _songsBox = songsBox ?? Hive.box<Song>(HiveBoxes.songs);

  final AudioQueryService _audioQueryService;
  final Box<Song> _songsBox;

  /// Lagu hasil scan terakhir, langsung dari cache Hive (tanpa touch MediaStore).
  List<Song> getCachedSongs() {
    final songs = _songsBox.values.toList();
    songs.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return songs;
  }

  Song? getById(int id) => _songsBox.get(id);

  /// Buang satu entry dari cache — dipakai setelah real file delete sukses
  /// (Architecture.md § 4a), bukan bagian dari alur scan biasa.
  Future<void> deleteFromCache(int id) async {
    await _songsBox.delete(id);
  }

  /// Scan MediaStore lalu sinkronkan ke cache Hive. Incremental — lagu yang
  /// `dateModified`-nya sama dengan cache dilewati, tidak diproses ulang
  /// (Architecture.md § 6 poin 5). Lagu yang sudah tidak ada lagi di
  /// MediaStore (file dihapus) dibuang dari cache.
  Future<List<Song>> scan() async {
    final rawSongs = await _audioQueryService.queryAllSongs();

    final seenIds = <int>{};
    for (final raw in rawSongs) {
      if (raw.isMusic == false) continue;

      seenIds.add(raw.id);

      final rawDateModified = raw.dateModified ?? 0;
      final cached = _songsBox.get(raw.id);
      if (cached != null &&
          cached.dateModified == rawDateModified &&
          cached.dataPath != null) {
        continue;
      }

      final cleaned = TitleCleaner.parse(raw.title, raw.artist);
      final song = Song(
        id: raw.id,
        title: cleaned.title,
        artist: cleaned.artist,
        album: raw.album,
        duration: raw.duration ?? 0,
        filePath: raw.uri ?? raw.data,
        dateAdded: DateTime.fromMillisecondsSinceEpoch(
          (raw.dateAdded ?? 0) * 1000,
        ),
        dateModified: rawDateModified,
        albumArtId: raw.albumId,
        dataPath: raw.data.isEmpty ? null : raw.data,
      );
      await _songsBox.put(raw.id, song);
    }

    final staleIds = _songsBox.keys
        .where((id) => !seenIds.contains(id))
        .toList();
    if (staleIds.isNotEmpty) {
      await _songsBox.deleteAll(staleIds);
    }

    return getCachedSongs();
  }

  /// Grouping buat browse Library (PRD.md § 7 poin 6) — dipanggil dari
  /// provider, bukan widget (Rules.md § 5). Group tanpa `albumArtId`
  /// dikumpulkan jadi satu bucket "Unknown Album", bukan grup per-lagu.
  List<LibraryGroup> groupByAlbum(List<Song> songs) {
    final byKey = <String, List<Song>>{};
    final titleByKey = <String, String>{};
    for (final song in songs) {
      final key = song.albumArtId?.toString() ?? '__unknown_album__';
      (byKey[key] ??= []).add(song);
      titleByKey[key] = song.album?.trim().isNotEmpty == true
          ? song.album!.trim()
          : 'Unknown Album';
    }
    final groups = byKey.entries
        .map(
          (entry) => LibraryGroup(
            key: entry.key,
            title: titleByKey[entry.key]!,
            type: LibraryGroupType.album,
            songs: entry.value,
          ),
        )
        .toList();
    groups.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return groups;
  }

  /// Group by [Song.artist] — string yang sudah dibersihkan `TitleCleaner`,
  /// konsisten dengan yang ditampilkan di seluruh UI lain (bukan artist_id
  /// mentah MediaStore, yang bisa beda hasil split-nya).
  List<LibraryGroup> groupByArtist(List<Song> songs) {
    final byKey = <String, List<Song>>{};
    final titleByKey = <String, String>{};
    for (final song in songs) {
      final trimmed = song.artist.trim();
      final key = trimmed.toLowerCase();
      (byKey[key] ??= []).add(song);
      titleByKey[key] = trimmed.isEmpty ? 'Unknown Artist' : trimmed;
    }
    final groups = byKey.entries
        .map(
          (entry) => LibraryGroup(
            key: entry.key,
            title: titleByKey[entry.key]!,
            type: LibraryGroupType.artist,
            songs: entry.value,
          ),
        )
        .toList();
    groups.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return groups;
  }

  /// Group by folder terakhir sebelum nama file, dari [Song.dataPath] (real
  /// filesystem path, bukan `content://` URI — lihat Schema.md § 2). Lagu
  /// tanpa `dataPath` (edge case scoped storage) masuk bucket "Lainnya".
  List<LibraryGroup> groupByFolder(List<Song> songs) {
    final byKey = <String, List<Song>>{};
    final titleByKey = <String, String>{};
    for (final song in songs) {
      final dataPath = song.dataPath;
      final key = dataPath == null || dataPath.isEmpty
          ? '__unknown_folder__'
          : p.dirname(dataPath);
      (byKey[key] ??= []).add(song);
      titleByKey[key] = key == '__unknown_folder__'
          ? 'Lainnya'
          : p.basename(key);
    }
    final groups = byKey.entries
        .map(
          (entry) => LibraryGroup(
            key: entry.key,
            title: titleByKey[entry.key]!,
            type: LibraryGroupType.folder,
            songs: entry.value,
          ),
        )
        .toList();
    groups.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return groups;
  }
}
