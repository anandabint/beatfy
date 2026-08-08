import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/song.dart';
import '../services/media_delete_service.dart';
import 'favorite_providers.dart';
import 'home_providers.dart' show playStatsRepositoryProvider;
import 'library_providers.dart';
import 'playback_providers.dart';
import 'playlist_providers.dart';

/// Orkestrasi real file delete (PRD.md § 7.7, Architecture.md § 4a) — satu
/// tempat yang menyapu semua Hive box terkait (`songs`, `favorites`,
/// `play_stats`, referensi di `playlists`) setelah file fisik sukses
/// dihapus, plus auto-skip kalau lagu itu sedang di queue. Provider murni
/// orkestrasi (Architecture.md § 2) — tidak ada widget yang bicara ke Hive
/// langsung.
final songDeleterProvider = Provider<SongDeleter>(SongDeleter.new);

class SongDeleter {
  SongDeleter(this._ref);

  final Ref _ref;

  /// `true` kalau file sukses dihapus dari device. `false` kalau user
  /// membatalkan dialog konfirmasi sistem Android — bukan error, UI cukup
  /// diam/kasih tahu batal, bukan tampilkan pesan gagal.
  Future<bool> deleteFromDevice(Song song) async {
    final success = await MediaDeleteService.deleteFiles([song.filePath]);
    if (!success) return false;

    await _ref.read(libraryRepositoryProvider).deleteFromCache(song.id);
    await _ref.read(favoriteRepositoryProvider).remove(song.id);
    await _ref.read(playStatsRepositoryProvider).remove(song.id);
    await _ref
        .read(playlistRepositoryProvider)
        .removeSongFromAllPlaylists(song.id);

    _ref.read(librarySongsProvider.notifier).removeLocally(song.id);
    _ref.invalidate(favoriteIdsProvider);
    _ref.invalidate(playlistsProvider);

    await _ref.read(audioHandlerProvider).handleSongDeleted(song.id);

    return true;
  }
}
