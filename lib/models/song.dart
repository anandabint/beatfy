import 'package:hive_ce/hive_ce.dart';

part 'song.g.dart';

/// Cache hasil scan MediaStore  Schema.md § 2.
@HiveType(typeId: 0)
class Song extends HiveObject {
  Song({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    required this.duration,
    required this.filePath,
    required this.dateAdded,
    required this.dateModified,
    this.albumArtId,
    this.source = SongSource.mediaStoreScan,
    this.dataPath,
  });

  /// MediaStore audio id  primary key.
  @HiveField(0)
  final int id;

  /// Judul sudah dibersihkan (TitleCleaner).
  @HiveField(1)
  final String title;

  /// Artis, hasil split kalau tag kosong.
  @HiveField(2)
  final String artist;

  @HiveField(3)
  final String? album;

  /// Milliseconds.
  @HiveField(4)
  final int duration;

  /// URI/path MediaStore, untuk load ke just_audio.
  @HiveField(5)
  final String filePath;

  @HiveField(6)
  final DateTime dateAdded;

  /// Timestamp MediaStore, dipakai deteksi incremental scan.
  @HiveField(7)
  final int dateModified;

  /// Reference artwork (album id), di-load via on_audio_query artwork API.
  @HiveField(8)
  final int? albumArtId;

  @HiveField(9)
  final SongSource source;

  /// Real filesystem path (MediaStore `_data`), beda dari [filePath] yang
  /// selalu `content://` URI. Best-effort  bisa null di beberapa kasus
  /// scoped storage. Dipakai untuk folder grouping (Schema.md § 2), bukan
  /// untuk load ke just_audio (itu tetap lewat [filePath]).
  @HiveField(10)
  final String? dataPath;
}

@HiveType(typeId: 6)
enum SongSource {
  @HiveField(0)
  mediaStoreScan,
}
