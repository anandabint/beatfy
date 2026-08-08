import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_theme.dart';
import '../../models/library_group.dart';
import '../../providers/favorite_providers.dart';
import '../../providers/playback_providers.dart';
import '../../widgets/common/song_actions_sheet.dart';
import '../../widgets/common/song_row.dart';

/// Detail satu grup Album/Artist/Folder — generic, dipakai untuk ketiganya
/// (PRD.md § 7 poin 6: strukturnya identik, cukup 1 screen reusable).
/// Reuse [SongRow] + [showSongActionsSheet] persis seperti Library flat list.
class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({super.key, required this.group});

  final LibraryGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSongId = ref.watch(currentMediaItemProvider).value?.id;
    final favoriteIds = ref.watch(favoriteIdsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          group.title,
          style: AppTextTheme.titleMedium.copyWith(color: AppColors.ink),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        // Semua row seragam tinggi — skip layout pass per-item saat scroll
        // (audit performa PRD.md § 11, 2026-08-07).
        prototypeItem: SongRow(song: group.songs.first, onTap: () {}),
        itemCount: group.songs.length,
        itemBuilder: (context, index) {
          final song = group.songs[index];
          final isFavorite = favoriteIds.contains(song.id);
          return SongRow(
            song: song,
            active: song.id.toString() == currentSongId,
            onTap: () => ref
                .read(audioHandlerProvider)
                .playFromSongs(group.songs, index),
            onLongPress: () => showSongActionsSheet(context, song),
            trailing: IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? AppColors.primary : AppColors.ash,
              ),
              tooltip: isFavorite ? 'Hapus dari favorit' : 'Tandai favorit',
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(favoriteIdsProvider.notifier).toggle(song.id);
              },
            ),
          );
        },
      ),
    );
  }
}
