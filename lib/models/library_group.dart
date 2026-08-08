import 'song.dart';

/// Grouping derivatif (bukan Hive, tidak dipersist) buat browse
/// Album/Artist/Folder di Library tab — PRD.md § 7 poin 6, Design.md § 7.
/// Selalu di-derive live dari [Song] yang sudah di-cache, bukan model
/// tersendiri (Schema.md § 1 — cache vs derived tetap terpisah).
enum LibraryGroupType { album, artist, folder }

class LibraryGroup {
  const LibraryGroup({
    required this.key,
    required this.title,
    required this.type,
    required this.songs,
  });

  /// Identitas grup — `albumArtId`/artist name/folder path, tergantung
  /// [type]. Dipakai buat key widget, bukan ditampilkan.
  final String key;

  final String title;
  final LibraryGroupType type;
  final List<Song> songs;

  int get songCount => songs.length;

  Song? get representativeSong => songs.isEmpty ? null : songs.first;
}
