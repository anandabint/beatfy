import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_theme.dart';
import '../../models/song.dart';
import '../../providers/favorite_providers.dart';
import '../../providers/song_delete_providers.dart';
import 'add_to_playlist_sheet.dart';
import 'song_artwork.dart';

/// Context menu song lewat long-press — Design.md § 7 "Context menu song"
/// (baru 2026-08-07). Pengganti utama swipe-to-delete untuk song row:
/// aksi hapus sekarang destructive (real file, PRD.md § 7.7) jadi butuh
/// tempat yang lebih eksplisit daripada gesture swipe yang gampang tidak
/// sengaja.
Future<void> showSongActionsSheet(BuildContext context, Song song) {
  HapticFeedback.mediumImpact();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _SongActionsSheet(song: song),
  );
}

class _SongActionsSheet extends ConsumerWidget {
  const _SongActionsSheet({required this.song});

  final Song song;

  Future<void> _handleShare(BuildContext context) async {
    Navigator.of(context).pop();
    await SharePlus.instance.share(
      ShareParams(
        text: '${song.title} — ${song.artist}',
        files: [XFile(song.filePath)],
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Hapus "${song.title}"?',
          style: AppTextTheme.titleMedium.copyWith(color: AppColors.ink),
        ),
        content: Text(
          'File akan dihapus permanen dari perangkat, tidak bisa dibatalkan.',
          style: AppTextTheme.bodySmall.copyWith(color: AppColors.ash),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Hapus', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final success = await ref.read(songDeleterProvider).deleteFromDevice(song);
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '"${song.title}" dihapus dari perangkat'
              : 'Hapus dibatalkan',
          style: AppTextTheme.bodySmall.copyWith(color: AppColors.ink),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoriteIdsProvider).contains(song.id);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SongArtwork.ofSong(song, size: 44),
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
                        color: AppColors.ink,
                      ),
                    ),
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
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ActionTile(
            icon: Icons.playlist_add,
            label: 'Tambah ke playlist',
            onTap: () {
              Navigator.of(context).pop();
              showAddToPlaylistSheet(context, song);
            },
          ),
          _ActionTile(
            icon: isFavorite ? Icons.favorite : Icons.favorite_border,
            iconColor: isFavorite ? AppColors.primary : null,
            label: isFavorite ? 'Hapus dari favorit' : 'Favorite',
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(favoriteIdsProvider.notifier).toggle(song.id);
              Navigator.of(context).pop();
            },
          ),
          _ActionTile(
            icon: Icons.share_outlined,
            label: 'Bagikan',
            onTap: () => _handleShare(context),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Divider(color: AppColors.hairline, height: 1),
          ),
          _ActionTile(
            icon: Icons.delete_outline,
            label: 'Hapus dari perangkat',
            iconColor: AppColors.danger,
            labelColor: AppColors.danger,
            onTap: () => _handleDelete(context, ref),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? AppColors.ash, size: 22),
              const SizedBox(width: AppSpacing.md),
              Text(
                label,
                style: AppTextTheme.bodyMedium.copyWith(
                  color: labelColor ?? AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
