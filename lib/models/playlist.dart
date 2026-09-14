import 'package:hive_ce/hive_ce.dart';

part 'playlist.g.dart';

/// Playlist buatan user  Schema.md § 3.
@HiveType(typeId: 2)
class Playlist extends HiveObject {
  Playlist({
    required this.id,
    required this.name,
    required this.songIds,
    required this.createdAt,
    this.coverSongId,
  });

  /// uuid  sama pola Planly.
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  /// Urutan lagu dalam playlist.
  @HiveField(2)
  final List<int> songIds;

  @HiveField(3)
  final DateTime createdAt;

  /// Lagu yang artwork-nya dipakai sebagai cover playlist.
  @HiveField(4)
  final int? coverSongId;
}
