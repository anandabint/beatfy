import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_theme.dart';
import '../../models/library_group.dart';
import 'song_artwork.dart';

/// Baris grup Album/Artist/Folder di Library tab (Design.md § 7)  art
/// representatif (lagu pertama di grup) + nama grup + "X Lagu".
class LibraryGroupRow extends StatelessWidget {
  const LibraryGroupRow({super.key, required this.group, required this.onTap});

  final LibraryGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final representative = group.representativeSong;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            SongArtwork(
              audioId: representative?.id,
              albumArtId: representative?.albumArtId,
              gradientSeed: group.title,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                group.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextTheme.bodyMedium.copyWith(color: AppColors.ink),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${group.songCount} Lagu',
              style: AppTextTheme.caption.copyWith(color: AppColors.stone),
            ),
          ],
        ),
      ),
    );
  }
}
