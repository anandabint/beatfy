import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_theme.dart';
import '../../models/song.dart';
import '../../providers/playback_providers.dart';
import '../../providers/playlist_providers.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/song_actions_sheet.dart';
import '../../widgets/common/song_row.dart';
import 'add_songs_to_playlist_screen.dart';

/// Detail playlist — list lagu, reorder (drag handle), hapus (swipe),
/// tambah lagu (PRD.md § 7 poin 1).
class PlaylistDetailScreen extends ConsumerWidget {
  const PlaylistDetailScreen({super.key, required this.playlistId});

  final String playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlist = ref.watch(playlistByIdProvider(playlistId));
    final songs = ref.watch(playlistSongsProvider(playlistId));
    final currentSongId = ref.watch(currentMediaItemProvider).value?.id;

    if (playlist == null) {
      // Playlist dihapus (mis. dari list screen) saat detail masih terbuka.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return const Scaffold(
        backgroundColor: AppColors.canvas,
        body: SizedBox.shrink(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          playlist.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextTheme.titleMedium.copyWith(color: AppColors.ink),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Tambah lagu',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    AddSongsToPlaylistScreen(playlistId: playlistId),
              ),
            ),
          ),
        ],
      ),
      body: songs.isEmpty
          ? const EmptyState(
              icon: Icons.queue_music_rounded,
              message: 'Belum ada lagu. Tap ikon + di atas untuk menambahkan.',
            )
          : ReorderableListView.builder(
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
              itemCount: songs.length,
              onReorderItem: (oldIndex, newIndex) => ref
                  .read(playlistsProvider.notifier)
                  .reorder(playlistId, oldIndex, newIndex),
              itemBuilder: (context, index) {
                final song = songs[index];
                return Dismissible(
                  key: ValueKey(song.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: AppColors.danger,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) => _confirmRemoveSong(context, song),
                  onDismissed: (_) => ref
                      .read(playlistsProvider.notifier)
                      .removeSong(playlistId, song.id),
                  child: SongRow(
                    song: song,
                    active: song.id.toString() == currentSongId,
                    onTap: () => ref
                        .read(audioHandlerProvider)
                        .playFromSongs(songs, index),
                    onLongPress: () => showSongActionsSheet(context, song),
                    trailing: Listener(
                      // Haptic di-fire saat handle mulai disentuh (proxy untuk
                      // "grab start" — `ReorderableDragStartListener` sendiri
                      // tidak expose callback awal drag).
                      onPointerDown: (_) => HapticFeedback.lightImpact(),
                      child: ReorderableDragStartListener(
                        index: index,
                        // Icon telanjang cuma ~24px — perbesar area sentuh ke
                        // minimum 44x44 (Design.md § 9) sekalian mempermudah
                        // gesture drag-nya kena.
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            Icons.drag_handle,
                            color: AppColors.stone,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  /// Konfirmasi sebelum lagu benar-benar hilang dari playlist — swipe saja
  /// tidak boleh langsung menghapus data (Design.md § 12).
  Future<bool?> _confirmRemoveSong(BuildContext context, Song song) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Hapus dari playlist?',
          style: AppTextTheme.titleMedium.copyWith(color: AppColors.ink),
        ),
        content: Text(
          '"${song.title}" akan dihapus dari playlist ini. Lagu tidak ikut terhapus dari HP.',
          style: AppTextTheme.bodySmall.copyWith(color: AppColors.ash),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
