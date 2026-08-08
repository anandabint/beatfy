import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_theme.dart';
import '../../providers/library_providers.dart';
import '../../providers/playlist_providers.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeleton_loader.dart';
import '../../widgets/common/song_row.dart';

/// Tambah/hapus lagu dari playlist — tap toggle langsung (PRD.md § 7 poin 1).
class AddSongsToPlaylistScreen extends ConsumerWidget {
  const AddSongsToPlaylistScreen({super.key, required this.playlistId});

  final String playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(sortedLibrarySongsProvider);
    final playlist = ref.watch(playlistByIdProvider(playlistId));
    final songIdsInPlaylist = playlist?.songIds.toSet() ?? const <int>{};

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'Tambah Lagu',
          style: AppTextTheme.titleMedium.copyWith(color: AppColors.ink),
        ),
      ),
      body: songsAsync.when(
        loading: () => ListView.builder(
          itemCount: 8,
          itemBuilder: (context, index) => const SkeletonSongRow(),
        ),
        error: (error, stackTrace) => Center(
          child: Text(
            'Gagal memuat: $error',
            style: AppTextTheme.bodySmall.copyWith(color: AppColors.ash),
          ),
        ),
        data: (songs) {
          if (songs.isEmpty) {
            return const EmptyState(
              icon: Icons.library_music_outlined,
              message: 'Belum ada lagu di library.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              final added = songIdsInPlaylist.contains(song.id);
              return SongRow(
                song: song,
                onTap: () {
                  final notifier = ref.read(playlistsProvider.notifier);
                  if (added) {
                    notifier.removeSong(playlistId, song.id);
                  } else {
                    notifier.addSong(playlistId, song.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '"${song.title}" ditambahkan ke playlist',
                          style: AppTextTheme.bodySmall.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                        backgroundColor: AppColors.surfaceHover,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                trailing: Icon(
                  added ? Icons.check_circle : Icons.add_circle_outline,
                  color: added ? AppColors.primary : AppColors.ash,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
