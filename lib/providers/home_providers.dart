import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/play_stats_repository.dart';
import '../models/song.dart';
import 'library_providers.dart';

/// Di-override di main()  instance yang sama dipakai `AudioHandler` untuk
/// `recordPlay` (Architecture.md § 2).
final playStatsRepositoryProvider = Provider<PlayStatsRepository>((ref) {
  throw UnimplementedError(
    'playStatsRepositoryProvider must be overridden in main()',
  );
});

final _playStatsChangesProvider = StreamProvider<void>((ref) {
  return ref.watch(playStatsRepositoryProvider).watchChanges();
});

/// Home tab § Recently Added  20 lagu terbaru ditambahkan.
final recentlyAddedProvider = Provider<AsyncValue<List<Song>>>((ref) {
  final songsAsync = ref.watch(librarySongsProvider);
  return songsAsync.whenData((songs) {
    final sorted = [...songs]
      ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    return sorted.take(20).toList();
  });
});

/// Home tab § Top 10  berdasar play count. Watch `_playStatsChangesProvider`
/// supaya tetap reaktif walau `recordPlay` dipanggil dari AudioHandler,
/// di luar alur provider biasa.
final topPlayedProvider = Provider<AsyncValue<List<Song>>>((ref) {
  ref.watch(_playStatsChangesProvider);
  final songsAsync = ref.watch(librarySongsProvider);
  final statsRepository = ref.watch(playStatsRepositoryProvider);
  return songsAsync.whenData((songs) {
    final songsById = {for (final song in songs) song.id: song};
    final topIds = statsRepository.topPlayedSongIds(limit: 10);
    return topIds.map((id) => songsById[id]).whereType<Song>().toList();
  });
});
