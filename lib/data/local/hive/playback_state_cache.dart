import 'package:hive_ce/hive_ce.dart';

part 'playback_state_cache.g.dart';

/// Single-entry cache (key `'current'`) — kunci fix bug pause-resume.
/// Ditulis setiap event penting (Architecture.md § 4), bukan hanya saat app pause.
/// Schema.md § 2.
@HiveType(typeId: 1)
class PlaybackStateCache extends HiveObject {
  PlaybackStateCache({
    this.currentSongId,
    required this.positionMs,
    required this.queueSongIds,
    required this.queueIndex,
    required this.shuffleEnabled,
    required this.repeatMode,
    required this.isPlaying,
    required this.updatedAt,
  });

  /// Null kalau tidak ada sesi aktif.
  @HiveField(0)
  final int? currentSongId;

  @HiveField(1)
  final int positionMs;

  @HiveField(2)
  final List<int> queueSongIds;

  @HiveField(3)
  final int queueIndex;

  @HiveField(4)
  final bool shuffleEnabled;

  @HiveField(5)
  final RepeatMode repeatMode;

  /// Status terakhir — dipakai untuk keputusan auto-resume atau tidak saat app dibuka.
  @HiveField(6)
  final bool isPlaying;

  /// Untuk debug/validasi staleness.
  @HiveField(7)
  final DateTime updatedAt;
}

@HiveType(typeId: 7)
enum RepeatMode {
  @HiveField(0)
  off,
  @HiveField(1)
  one,
  @HiveField(2)
  all,
}
