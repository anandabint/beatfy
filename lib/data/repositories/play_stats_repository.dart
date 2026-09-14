import 'package:hive_ce/hive_ce.dart';

import '../../models/play_stats.dart';
import '../local/hive/hive_setup.dart';

/// Statistik play count  Schema.md § 3. Dipakai Home tab (Top 10) dan
/// di-increment dari `AudioHandler` saat lagu lewat >50% durasi.
class PlayStatsRepository {
  PlayStatsRepository({Box<PlayStats>? box})
    : _box = box ?? Hive.box<PlayStats>(HiveBoxes.playStats);

  final Box<PlayStats> _box;

  /// `recordPlay` dipanggil dari `AudioHandler`, di luar alur mutasi provider
  /// biasa  expose stream perubahan supaya provider Home tab (Top 10) bisa
  /// tetap reaktif tanpa UI/provider menyentuh Hive langsung.
  Stream<void> watchChanges() => _box.watch().map((_) {});

  Future<void> recordPlay(int songId) async {
    final existing = _box.get(songId);
    await _box.put(
      songId,
      PlayStats(
        songId: songId,
        playCount: (existing?.playCount ?? 0) + 1,
        lastPlayedAt: DateTime.now(),
      ),
    );
  }

  /// Dipakai saat song dihapus dari device (Architecture.md § 4a).
  Future<void> remove(int songId) async {
    if (_box.containsKey(songId)) await _box.delete(songId);
  }

  /// songId terurut playCount tertinggi (turun), dipakai Home tab § Top 10.
  List<int> topPlayedSongIds({int limit = 10}) {
    final entries = _box.values.toList()
      ..sort((a, b) => b.playCount.compareTo(a.playCount));
    return entries.take(limit).map((e) => e.songId).toList();
  }
}
