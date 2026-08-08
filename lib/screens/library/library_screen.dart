import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_theme.dart';
import '../../providers/favorite_providers.dart';
import '../../providers/library_providers.dart';
import '../../providers/playback_providers.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/filter_pill_row.dart';
import '../../widgets/common/library_group_row.dart';
import '../../widgets/common/skeleton_loader.dart';
import '../../widgets/common/song_actions_sheet.dart';
import '../../widgets/common/song_row.dart';
import 'group_detail_screen.dart';

/// Library screen — daftar lagu hasil scan, tap untuk play (PRD.md § 6.8).
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permission = ref.watch(libraryPermissionProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'Library',
          style: AppTextTheme.displayLarge.copyWith(color: AppColors.ink),
        ),
        actions: const [_SortPill()],
      ),
      body: permission.when(
        loading: () => const _CenteredMessage(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stackTrace) => _CenteredMessage(
          child: Text(
            'Gagal cek permission: $error',
            style: AppTextTheme.bodySmall.copyWith(color: AppColors.ash),
          ),
        ),
        data: (status) {
          if (status != LibraryPermissionStatus.granted) {
            return _PermissionDeniedView(status: status);
          }
          return const _SongList();
        },
      ),
    );
  }
}

class _SongList extends ConsumerWidget {
  const _SongList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(sortedLibrarySongsProvider);
    final currentSongId = ref.watch(currentMediaItemProvider).value?.id;
    final favoriteIds = ref.watch(favoriteIdsProvider);
    final filter = ref.watch(libraryFilterProvider);

    return Column(
      children: [
        const SizedBox(height: AppSpacing.xs),
        _LibraryFilterPillRow(filter: filter),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: isGroupingFilter(filter)
              ? const _GroupList()
              : songsAsync.when(
                  loading: () => const _ScanningSkeleton(),
                  error: (error, stackTrace) => _CenteredMessage(
                    child: Text(
                      'Gagal scan library: $error',
                      style: AppTextTheme.bodySmall.copyWith(
                        color: AppColors.ash,
                      ),
                    ),
                  ),
                  data: (allSongs) {
                    final songs = filter == LibraryFilter.likedSongs
                        ? allSongs
                              .where((song) => favoriteIds.contains(song.id))
                              .toList()
                        : allSongs;

                    if (songs.isEmpty) {
                      return EmptyState(
                        icon: filter == LibraryFilter.likedSongs
                            ? Icons.favorite_border_rounded
                            : Icons.library_music_outlined,
                        message: filter == LibraryFilter.likedSongs
                            ? 'Belum ada lagu favorit. Tap ikon hati di lagu untuk menandai.'
                            : 'Belum ada lagu ditemukan di HP ini.',
                      );
                    }
                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () =>
                          ref.read(librarySongsProvider.notifier).rescan(),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        // Semua row seragam tinggi — skip layout pass per-item
                        // saat scroll (audit performa PRD.md § 11, 2026-08-07).
                        prototypeItem: SongRow(song: songs.first, onTap: () {}),
                        itemCount: songs.length,
                        itemBuilder: (context, index) {
                          final song = songs[index];
                          final isFavorite = favoriteIds.contains(song.id);
                          return SongRow(
                            song: song,
                            active: song.id.toString() == currentSongId,
                            onTap: () => ref
                                .read(audioHandlerProvider)
                                .playFromSongs(songs, index),
                            onLongPress: () =>
                                showSongActionsSheet(context, song),
                            trailing: IconButton(
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite
                                    ? AppColors.primary
                                    : AppColors.ash,
                              ),
                              tooltip: isFavorite
                                  ? 'Hapus dari favorit'
                                  : 'Tandai favorit',
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(favoriteIdsProvider.notifier)
                                    .toggle(song.id);
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Grouped rows buat filter Albums/Artists/Folders (PRD.md § 7 poin 6) —
/// tap grup push ke [GroupDetailScreen] generic.
class _GroupList extends ConsumerWidget {
  const _GroupList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(libraryGroupsProvider);

    return groupsAsync.when(
      loading: () => const _ScanningSkeleton(),
      error: (error, stackTrace) => _CenteredMessage(
        child: Text(
          'Gagal muat grup: $error',
          style: AppTextTheme.bodySmall.copyWith(color: AppColors.ash),
        ),
      ),
      data: (groups) {
        if (groups.isEmpty) {
          return const EmptyState(
            icon: Icons.library_music_outlined,
            message: 'Belum ada lagu ditemukan di HP ini.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          // Semua row seragam tinggi — skip layout pass per-item saat scroll
          // (audit performa PRD.md § 11, 2026-08-07).
          prototypeItem: LibraryGroupRow(group: groups.first, onTap: () {}),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            return LibraryGroupRow(
              group: group,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupDetailScreen(group: group),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ScanningSkeleton extends StatelessWidget {
  const _ScanningSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Text(
            'Scanning library…',
            style: AppTextTheme.bodySmall.copyWith(color: AppColors.ash),
          ),
        ),
        Expanded(
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 8,
            itemBuilder: (context, index) => const SkeletonSongRow(),
          ),
        ),
      ],
    );
  }
}

class _LibraryFilterPillRow extends ConsumerWidget {
  const _LibraryFilterPillRow({required this.filter});

  final LibraryFilter filter;

  static const _labels = {
    LibraryFilter.all: 'All',
    LibraryFilter.playlists: 'Playlists',
    LibraryFilter.likedSongs: 'Liked Songs',
    LibraryFilter.downloads: 'Downloads',
    LibraryFilter.albums: 'Albums',
    LibraryFilter.artists: 'Artists',
    LibraryFilter.folders: 'Folders',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilterPillRow<LibraryFilter>(
      values: LibraryFilter.values,
      labels: _labels,
      selected: filter,
      onSelected: (value) =>
          ref.read(libraryFilterProvider.notifier).state = value,
    );
  }
}

class _PermissionDeniedView extends ConsumerWidget {
  const _PermissionDeniedView({required this.status});

  final LibraryPermissionStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permanentlyDenied =
        status == LibraryPermissionStatus.permanentlyDenied;
    return EmptyState(
      icon: Icons.music_off,
      message:
          'Beatfy butuh akses ke file audio\ndi HP kamu untuk menampilkan library.',
      action: ElevatedButton(
        onPressed: () {
          if (permanentlyDenied) {
            ref.read(libraryPermissionProvider.notifier).openSettings();
          } else {
            ref.read(libraryPermissionProvider.notifier).requestAgain();
          }
        },
        child: Text(permanentlyDenied ? 'Buka Pengaturan' : 'Izinkan Akses'),
      ),
    );
  }
}

/// Sort control — outline pill kecil (Design.md § 7), pengganti dropdown
/// text+arrow polos versi sebelumnya. Interaksi tetap `PopupMenuButton`.
class _SortPill extends ConsumerWidget {
  const _SortPill();

  static const _labels = {
    LibrarySortOption.title: 'Title',
    LibrarySortOption.artist: 'Artist',
    LibrarySortOption.dateAdded: 'Date',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(librarySortOptionProvider);

    return PopupMenuButton<LibrarySortOption>(
      tooltip: 'Urutkan',
      initialValue: current,
      color: AppColors.surfaceHover,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      onSelected: (option) =>
          ref.read(librarySortOptionProvider.notifier).state = option,
      itemBuilder: (context) => LibrarySortOption.values
          .map(
            (option) => PopupMenuItem(
              value: option,
              child: Text(
                _labels[option]!,
                style: AppTextTheme.bodyMedium.copyWith(
                  color: option == current ? AppColors.primary : AppColors.ink,
                ),
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.hairline),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _labels[current]!,
              style: AppTextTheme.labelMedium.copyWith(color: AppColors.ash),
            ),
            const SizedBox(width: AppSpacing.xxs),
            const Icon(Icons.arrow_drop_down, color: AppColors.ash, size: 18),
          ],
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: DefaultTextStyle.merge(
          style: AppTextTheme.bodyMedium.copyWith(color: AppColors.ash),
          textAlign: TextAlign.center,
          child: child,
        ),
      ),
    );
  }
}
