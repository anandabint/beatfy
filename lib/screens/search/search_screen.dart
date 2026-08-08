import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_theme.dart';
import '../../models/song.dart';
import '../../providers/library_providers.dart';
import '../../providers/playback_providers.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeleton_loader.dart';
import '../../widgets/common/song_actions_sheet.dart';
import '../../widgets/common/song_row.dart';

final _searchQueryProvider = StateProvider<String>((ref) => '');

/// Filter title/artis/album real-time dari `librarySongsProvider` — cari
/// murni di memori, tidak query MediaStore/Hive ulang tiap ketikan
/// (PRD.md § 7 poin 3).
final _searchResultsProvider = Provider<AsyncValue<List<Song>>>((ref) {
  final query = ref.watch(_searchQueryProvider).trim().toLowerCase();
  final songsAsync = ref.watch(librarySongsProvider);
  if (query.isEmpty) return const AsyncData([]);

  return songsAsync.whenData((songs) {
    return songs.where((song) {
      return song.title.toLowerCase().contains(query) ||
          song.artist.toLowerCase().contains(query) ||
          (song.album?.toLowerCase().contains(query) ?? false);
    }).toList();
  });
});

/// Search tab — cari across judul/artis/album (PRD.md § 7 poin 3).
class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(_searchQueryProvider);
    final resultsAsync = ref.watch(_searchResultsProvider);
    final currentSongId = ref.watch(currentMediaItemProvider).value?.id;
    // Bottom padding di bawah biasanya dicadangkan buat bottom-nav/mini-
    // player supaya konten tidak ketutup nav pill. Begitu keyboard muncul,
    // nav itu sendiri sudah ketutup keyboard — padding itu jadi ruang kosong
    // tak berguna antara list hasil dan keyboard. Proporsional ke tinggi
    // keyboard asli (bukan angka tetap) supaya list tidak ketutup keyboard
    // maupun nyisain gap kosong di baliknya.
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    final resultsBottomPadding = viewInsetsBottom > 0
        ? viewInsetsBottom + AppSpacing.sm
        : AppSpacing.xxxl;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'Search',
          style: AppTextTheme.displayLarge.copyWith(color: AppColors.ink),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: TextField(
              onChanged: (value) =>
                  ref.read(_searchQueryProvider.notifier).state = value,
              style: AppTextTheme.bodyMedium.copyWith(color: AppColors.ink),
              decoration: InputDecoration(
                hintText: 'Cari judul, artis, album…',
                hintStyle: AppTextTheme.bodyMedium.copyWith(
                  color: AppColors.stone,
                ),
                prefixIcon: const Icon(Icons.search, color: AppColors.ash),
                filled: true,
                fillColor: AppColors.surfaceMuted,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: query.trim().isEmpty
                ? const EmptyState(
                    icon: Icons.search_rounded,
                    message: 'Ketik untuk mencari lagu.',
                  )
                : resultsAsync.when(
                    loading: () => ListView.builder(
                      itemCount: 6,
                      itemBuilder: (context, index) => const SkeletonSongRow(),
                    ),
                    error: (error, stackTrace) =>
                        _CenteredHint(text: 'Gagal memuat: $error'),
                    data: (songs) {
                      if (songs.isEmpty) {
                        return const EmptyState(
                          icon: Icons.search_off_rounded,
                          message: 'Tidak ada hasil.',
                        );
                      }
                      return ListView.builder(
                        padding: EdgeInsets.only(bottom: resultsBottomPadding),
                        // Semua row seragam tinggi — skip layout pass
                        // per-item saat scroll (audit performa PRD.md § 11,
                        // 2026-08-07).
                        prototypeItem: SongRow(song: songs.first, onTap: () {}),
                        itemCount: songs.length,
                        itemBuilder: (context, index) {
                          final song = songs[index];
                          return SongRow(
                            song: song,
                            active: song.id.toString() == currentSongId,
                            onTap: () => ref
                                .read(audioHandlerProvider)
                                .playFromSongs(songs, index),
                            onLongPress: () =>
                                showSongActionsSheet(context, song),
                            trailing: _PlayPill(
                              onTap: () => ref
                                  .read(audioHandlerProvider)
                                  .playFromSongs(songs, index),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Circular lime play button trailing — Design.md § 7 "Song row" (bukan
/// icon play kecil polos). Tap = shortcut sama seperti tap baris.
class _PlayPill extends StatelessWidget {
  const _PlayPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        splashColor: Colors.black12,
        highlightColor: Colors.black12,
        child: const SizedBox(
          width: 32,
          height: 32,
          child: Icon(Icons.play_arrow, color: Colors.black, size: 18),
        ),
      ),
    );
  }
}

class _CenteredHint extends StatelessWidget {
  const _CenteredHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextTheme.bodyMedium.copyWith(color: AppColors.ash),
        ),
      ),
    );
  }
}
