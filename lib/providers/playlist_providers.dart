import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/playlist_repository.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import 'library_providers.dart';

/// Di-override di main() (Architecture.md § 2).
final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  throw UnimplementedError(
    'playlistRepositoryProvider must be overridden in main()',
  );
});

/// Semua playlist, terbaru dulu. Semua mutasi lewat method di notifier ini.
class PlaylistsNotifier extends Notifier<List<Playlist>> {
  @override
  List<Playlist> build() => ref.watch(playlistRepositoryProvider).getAll();

  void _refresh() => state = ref.read(playlistRepositoryProvider).getAll();

  Future<void> create(String name) async {
    if (name.trim().isEmpty) return;
    await ref.read(playlistRepositoryProvider).create(name);
    _refresh();
  }

  Future<void> rename(String id, String newName) async {
    if (newName.trim().isEmpty) return;
    await ref.read(playlistRepositoryProvider).rename(id, newName);
    _refresh();
  }

  Future<void> delete(String id) async {
    await ref.read(playlistRepositoryProvider).delete(id);
    _refresh();
  }

  Future<void> addSong(String id, int songId) async {
    await ref.read(playlistRepositoryProvider).addSong(id, songId);
    _refresh();
  }

  /// Tambah banyak lagu sekaligus  dipakai mode pilih-banyak (`GroupDetailScreen`).
  Future<void> addSongs(String id, List<int> songIds) async {
    await ref.read(playlistRepositoryProvider).addSongs(id, songIds);
    _refresh();
  }

  Future<void> removeSong(String id, int songId) async {
    await ref.read(playlistRepositoryProvider).removeSong(id, songId);
    _refresh();
  }

  Future<void> reorder(String id, int oldIndex, int newIndex) async {
    await ref.read(playlistRepositoryProvider).reorder(id, oldIndex, newIndex);
    _refresh();
  }
}

final playlistsProvider = NotifierProvider<PlaylistsNotifier, List<Playlist>>(
  PlaylistsNotifier.new,
);

final playlistByIdProvider = Provider.family<Playlist?, String>((ref, id) {
  final playlists = ref.watch(playlistsProvider);
  for (final playlist in playlists) {
    if (playlist.id == id) return playlist;
  }
  return null;
});

/// Song penuh di dalam playlist [id], urutan sesuai `Playlist.songIds`.
final playlistSongsProvider = Provider.family<List<Song>, String>((ref, id) {
  final playlist = ref.watch(playlistByIdProvider(id));
  if (playlist == null) return const [];
  final repository = ref.watch(libraryRepositoryProvider);
  return playlist.songIds.map(repository.getById).whereType<Song>().toList();
});
