import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_theme.dart';
import '../../models/cloud_backup_record.dart';
import '../../models/song.dart';
import '../../providers/cloud_backup_providers.dart';
import 'song_artwork.dart';

class SongRow extends ConsumerWidget {
  const SongRow({
    super.key,
    required this.song,
    required this.onTap,
    this.onLongPress,
    this.active = false,
    this.trailing,
  });

  final Song song;
  final VoidCallback onTap;

  /// Buka context menu (Design.md § 7 "Context menu song")  null berarti
  /// pemanggil sengaja tidak menyediakan menu di konteks itu.
  final VoidCallback? onLongPress;
  final bool active;

  /// Slot opsional setelah durasi  dipakai mis. star favorite (Library tab)
  /// atau drag handle (Playlist detail).
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupStatus = ref.watch(backupStatusProvider(song.id));

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            SongArtwork.ofSong(song),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextTheme.bodyMedium.copyWith(
                      color: active ? AppColors.primary : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextTheme.bodySmall.copyWith(
                      color: AppColors.ash,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Ikon status backup  Architecture.md § 7b, subtle, bukan
            // indikator "streaming vs lokal" (app ini tidak streaming).
            Icon(
              backupStatus == BackupStatus.done
                  ? Icons.cloud_done_rounded
                  : Icons.cloud_outlined,
              size: 14,
              color: backupStatus == BackupStatus.done
                  ? AppColors.ash
                  : AppColors.stone.withValues(alpha: 0.4),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              _formatDuration(song.duration),
              style: AppTextTheme.caption.copyWith(color: AppColors.stone),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.xs),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }

  static String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes.remainder(60).toString();
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
