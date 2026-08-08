import 'package:hive_ce/hive_ce.dart';

part 'play_stats.g.dart';

/// Statistik pemutaran lagu — Schema.md § 3. Box key = [songId].
/// `playCount` di-increment tiap lagu selesai diputar >50% durasi.
@HiveType(typeId: 4)
class PlayStats extends HiveObject {
  PlayStats({
    required this.songId,
    required this.playCount,
    required this.lastPlayedAt,
  });

  @HiveField(0)
  final int songId;

  @HiveField(1)
  final int playCount;

  @HiveField(2)
  final DateTime lastPlayedAt;
}
