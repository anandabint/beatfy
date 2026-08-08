import 'package:hive_ce/hive_ce.dart';
import 'package:uuid/uuid.dart';

import '../../models/playlist.dart';
import '../local/hive/hive_setup.dart';

/// Playlist CRUD + reorder — Schema.md § 3, PRD.md § 7 poin 1.
class PlaylistRepository {
  PlaylistRepository({Box<Playlist>? box, Uuid? uuid})
    : _box = box ?? Hive.box<Playlist>(HiveBoxes.playlists),
      _uuid = uuid ?? const Uuid();

  final Box<Playlist> _box;
  final Uuid _uuid;

  List<Playlist> getAll() {
    final playlists = _box.values.toList();
    playlists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return playlists;
  }

  Playlist? getById(String id) => _box.get(id);

  Future<Playlist> create(String name) async {
    final playlist = Playlist(
      id: _uuid.v4(),
      name: name.trim(),
      songIds: const [],
      createdAt: DateTime.now(),
    );
    await _box.put(playlist.id, playlist);
    return playlist;
  }

  Future<void> rename(String id, String newName) async {
    final playlist = _box.get(id);
    if (playlist == null) return;
    await _box.put(
      id,
      Playlist(
        id: playlist.id,
        name: newName.trim(),
        songIds: playlist.songIds,
        createdAt: playlist.createdAt,
        coverSongId: playlist.coverSongId,
      ),
    );
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> addSong(String id, int songId) async {
    final playlist = _box.get(id);
    if (playlist == null || playlist.songIds.contains(songId)) return;
    await _box.put(
      id,
      Playlist(
        id: playlist.id,
        name: playlist.name,
        songIds: [...playlist.songIds, songId],
        createdAt: playlist.createdAt,
        coverSongId: playlist.coverSongId ?? songId,
      ),
    );
  }

  Future<void> removeSong(String id, int songId) async {
    final playlist = _box.get(id);
    if (playlist == null) return;
    final songIds = playlist.songIds.where((s) => s != songId).toList();
    final coverSongId = playlist.coverSongId == songId
        ? (songIds.isNotEmpty ? songIds.first : null)
        : playlist.coverSongId;
    await _box.put(
      id,
      Playlist(
        id: playlist.id,
        name: playlist.name,
        songIds: songIds,
        createdAt: playlist.createdAt,
        coverSongId: coverSongId,
      ),
    );
  }

  /// Dipakai saat song dihapus dari device (Architecture.md § 4a) — beda
  /// dari [removeSong] karena harus menyapu SEMUA playlist sekaligus, bukan
  /// satu playlist spesifik.
  Future<void> removeSongFromAllPlaylists(int songId) async {
    for (final playlist in _box.values.toList()) {
      if (!playlist.songIds.contains(songId)) continue;
      final songIds = playlist.songIds.where((s) => s != songId).toList();
      final coverSongId = playlist.coverSongId == songId
          ? (songIds.isNotEmpty ? songIds.first : null)
          : playlist.coverSongId;
      await _box.put(
        playlist.id,
        Playlist(
          id: playlist.id,
          name: playlist.name,
          songIds: songIds,
          createdAt: playlist.createdAt,
          coverSongId: coverSongId,
        ),
      );
    }
  }

  /// [newIndex] pakai konvensi `ReorderableListView.onReorderItem` (index
  /// tujuan SUDAH disesuaikan Flutter untuk item yang dibuang di [oldIndex]).
  Future<void> reorder(String id, int oldIndex, int newIndex) async {
    final playlist = _box.get(id);
    if (playlist == null) return;
    final songIds = [...playlist.songIds];
    final item = songIds.removeAt(oldIndex);
    songIds.insert(newIndex, item);
    await _box.put(
      id,
      Playlist(
        id: playlist.id,
        name: playlist.name,
        songIds: songIds,
        createdAt: playlist.createdAt,
        coverSongId: playlist.coverSongId,
      ),
    );
  }
}
