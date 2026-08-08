import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_theme.dart';
import '../../models/song.dart';
import '../../providers/auth_providers.dart';
import '../../providers/home_providers.dart';
import '../../providers/library_providers.dart';
import '../../providers/playback_providers.dart';
import '../../widgets/common/filter_pill_row.dart';
import '../../widgets/common/gradient_blob.dart';
import '../../widgets/common/skeleton_loader.dart';
import '../../widgets/common/song_actions_sheet.dart';
import '../../widgets/common/song_artwork.dart';
import '../../widgets/common/user_avatar.dart';
import '../library/library_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';

enum _HomeFilter { all, newRelease, trending, topCharts }

final _homeFilterProvider = StateProvider<_HomeFilter>(
  (ref) => _HomeFilter.all,
);

/// Home tab — Recently Added + Top 10 (PRD.md § 7 poin 4). Header personal
/// (greeting + avatar + shortcut icons), filter pill row, featured card, dan
/// gradient blob atmosferik — Design.md § 7 (revisi 2026-08-06).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentlyAdded = ref.watch(recentlyAddedProvider);
    final topPlayed = ref.watch(topPlayedProvider);
    final filter = ref.watch(_homeFilterProvider);
    final showRecent =
        filter == _HomeFilter.all || filter == _HomeFilter.newRelease;
    final showTop =
        filter == _HomeFilter.all ||
        filter == _HomeFilter.trending ||
        filter == _HomeFilter.topCharts;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          const Positioned(
            top: -80,
            right: -60,
            child: GradientBlob(size: 300),
          ),
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              children: [
                const _HomeHeader(),
                const SizedBox(height: AppSpacing.lg),
                _HomeFilterPillRow(filter: filter),
                const SizedBox(height: AppSpacing.lg),
                _FeaturedCard(
                  topPlayed: topPlayed,
                  recentlyAdded: recentlyAdded,
                ),
                const SizedBox(height: AppSpacing.xl),
                if (showRecent) ...[
                  _Section(
                    title: 'Recently Added',
                    icon: Icons.history_rounded,
                    songsAsync: recentlyAdded,
                    emptyText: 'Belum ada lagu di library.',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
                if (showTop)
                  _TopSection(
                    title: 'Top 10',
                    icon: Icons.trending_up_rounded,
                    songsAsync: topPlayed,
                    emptyText: 'Belum ada lagu yang diputar cukup lama.',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Greeting + avatar + shortcut icons — Design.md § 7 "Header Home"
/// (revisi 2026-08-07: satu baris, bukan dua). Google Sign-In (PRD.md § 7
/// poin 5) tetap sepenuhnya opsional: signed-in menampilkan
/// "Hi, {nama depan}", belum/tidak sign-in fallback ke teks statis
/// "Hi there" — logic sapaan berbasis jam dihapus total (PRD.md § 11),
/// tidak pernah ada login wall. Tap avatar push [SettingsScreen] (PRD.md
/// § 7 poin 5, revisi 2026-08-07) — sign-in/sign-out sekarang di dalam
/// Settings, bukan inline di sini.
class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  /// Kata pertama dari `displayName` sebagai nama panggilan, mis. "Ananda B
  /// Ramadhan" → "Ananda".
  static String? _firstName(String? displayName) {
    final trimmed = displayName?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    final firstName = _firstName(profile?.displayName);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Text(
              firstName != null ? 'Hi, $firstName' : 'Hi there',
              style: AppTextTheme.displayLarge.copyWith(color: AppColors.ink),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppColors.ink),
            tooltip: 'Search',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_rounded, color: AppColors.ink),
            tooltip: 'Favorit',
            onPressed: () {
              ref.read(libraryFilterProvider.notifier).state =
                  LibraryFilter.likedSongs;
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const LibraryScreen()));
            },
          ),
          const SizedBox(width: AppSpacing.xs),
          InkWell(
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            customBorder: const CircleBorder(),
            child: const UserAvatar(size: 36),
          ),
        ],
      ),
    );
  }
}

class _HomeFilterPillRow extends ConsumerWidget {
  const _HomeFilterPillRow({required this.filter});

  final _HomeFilter filter;

  static const _labels = {
    _HomeFilter.all: 'All',
    _HomeFilter.newRelease: 'New Release',
    _HomeFilter.trending: 'Trending',
    _HomeFilter.topCharts: 'Top Charts',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilterPillRow<_HomeFilter>(
      values: _HomeFilter.values,
      labels: _labels,
      selected: filter,
      onSelected: (value) =>
          ref.read(_homeFilterProvider.notifier).state = value,
    );
  }
}

/// Hero card, gaya "Discover weekly" — surface lagu paling relevan yang
/// tersedia (top played, fallback recently added), bukan sekadar dekorasi:
/// tombol play beneran memutar lagu tersebut.
class _FeaturedCard extends ConsumerWidget {
  const _FeaturedCard({required this.topPlayed, required this.recentlyAdded});

  final AsyncValue<List<Song>> topPlayed;
  final AsyncValue<List<Song>> recentlyAdded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTopPlayed = topPlayed.value?.isNotEmpty ?? false;
    final source = isTopPlayed
        ? topPlayed.value!
        : (recentlyAdded.value ?? const []);
    final song = source.isNotEmpty ? source.first : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6A3FB5), Color(0xFF3E2260)],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song == null
                        ? 'Discover Beatfy'
                        : (isTopPlayed
                              ? 'Paling sering diputar'
                              : 'Baru ditambahkan'),
                    style: AppTextTheme.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    song?.title ?? 'Scan library buat mulai dengar',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextTheme.titleMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _FeaturedPlayButton(
                    enabled: song != null,
                    onTap: song == null
                        ? null
                        : () => ref
                              .read(audioHandlerProvider)
                              .playFromSongs(source, 0),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            if (song != null) SongArtwork.ofSong(song, size: 84),
          ],
        ),
      ),
    );
  }
}

class _FeaturedPlayButton extends StatelessWidget {
  const _FeaturedPlayButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppColors.primary : Colors.white.withValues(alpha: 0.2),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        splashColor: Colors.black12,
        highlightColor: Colors.black12,
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: Icon(Icons.play_arrow_rounded, color: Colors.black, size: 22),
        ),
      ),
    );
  }
}

class _Section extends ConsumerWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.songsAsync,
    required this.emptyText,
  });

  final String title;
  final IconData icon;
  final AsyncValue<List<Song>> songsAsync;
  final String emptyText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              _TintedIcon(icon: icon),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: AppTextTheme.titleMedium.copyWith(color: AppColors.ink),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        songsAsync.when(
          loading: () => SizedBox(
            height: 172,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: 5,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) => const SkeletonHomeCard(),
            ),
          ),
          error: (error, stackTrace) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'Gagal memuat: $error',
              style: AppTextTheme.bodySmall.copyWith(color: AppColors.ash),
            ),
          ),
          data: (songs) {
            if (songs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  emptyText,
                  style: AppTextTheme.bodySmall.copyWith(color: AppColors.ash),
                ),
              );
            }
            return SizedBox(
              height: 172,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: songs.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) {
                  final song = songs[index];
                  return _HomeSongCard(
                    song: song,
                    onTap: () => ref
                        .read(audioHandlerProvider)
                        .playFromSongs(songs, index),
                    onLongPress: () => showSongActionsSheet(context, song),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Top 10 — layout beda dari Recently Added: list vertikal dengan angka rank
/// oversized (Design.md § 7), bukan horizontal card scroll.
class _TopSection extends ConsumerWidget {
  const _TopSection({
    required this.title,
    required this.icon,
    required this.songsAsync,
    required this.emptyText,
  });

  final String title;
  final IconData icon;
  final AsyncValue<List<Song>> songsAsync;
  final String emptyText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              _TintedIcon(icon: icon),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: AppTextTheme.titleMedium.copyWith(color: AppColors.ink),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        songsAsync.when(
          loading: () => Column(
            children: List.generate(4, (index) => const SkeletonSongRow()),
          ),
          error: (error, stackTrace) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'Gagal memuat: $error',
              style: AppTextTheme.bodySmall.copyWith(color: AppColors.ash),
            ),
          ),
          data: (songs) {
            if (songs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  emptyText,
                  style: AppTextTheme.bodySmall.copyWith(color: AppColors.ash),
                ),
              );
            }
            return Column(
              children: [
                for (var index = 0; index < songs.length; index++)
                  _RankedSongRow(
                    rank: index + 1,
                    song: songs[index],
                    onTap: () => ref
                        .read(audioHandlerProvider)
                        .playFromSongs(songs, index),
                    onLongPress: () =>
                        showSongActionsSheet(context, songs[index]),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _RankedSongRow extends StatelessWidget {
  const _RankedSongRow({
    required this.rank,
    required this.song,
    required this.onTap,
    this.onLongPress,
  });

  final int rank;
  final Song song;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  '$rank',
                  style: AppTextTheme.rankNumber.copyWith(
                    fontSize: 22,
                    color: rank <= 3 ? AppColors.primary : AppColors.stone,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
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
        ),
      ),
    );
  }
}

class _HomeSongCard extends StatelessWidget {
  const _HomeSongCard({
    required this.song,
    required this.onTap,
    this.onLongPress,
  });

  final Song song;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(64),
        child: SizedBox(
          width: 128,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SongArtwork.ofSong(song, size: 128),
              const SizedBox(height: AppSpacing.xs),
              Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextTheme.bodySmall.copyWith(color: AppColors.ink),
              ),
              Text(
                song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextTheme.caption.copyWith(color: AppColors.ash),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tinted leading icon — Design.md § 12: kotak circular (revisi § 5), bg
/// `primary` 15% opacity, icon solid `primary`.
class _TintedIcon extends StatelessWidget {
  const _TintedIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.primary, size: 16),
    );
  }
}
