import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_theme.dart';
import '../../core/theme/artwork_gradients.dart';
import '../../providers/playback_providers.dart';
import '../../screens/now_playing/now_playing_screen.dart';
import '../common/song_artwork.dart';

/// Floating pill di atas bottom nav; Design.md § 7 ("Mini player"). Tap
/// untuk expand ke Now Playing screen. **Revisi frosted glass (sesi ini)**:
/// background solid diganti translucent + `BackdropFilter` blur, sama pola
/// dengan `_BottomNavBar` di `main_shell.dart`; list tab di baliknya
/// (`MainShell.extendBody: true`) kelihatan blur lewat pill.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaItem = ref.watch(currentMediaItemProvider).value;
    final playbackState = ref.watch(playbackStateProvider).value;

    if (mediaItem == null) return const SizedBox.shrink();

    final playing = playbackState?.playing ?? false;
    final shuffleOn = playbackState?.shuffleMode == AudioServiceShuffleMode.all;
    // `mediaItem.id` = song id dari MediaStore, sama seperti yang dipakai
    // Now Playing (`now_playing_screen.dart`) supaya artwork yang tampil
    // adalah sampul audio asli yang tertanam/sepaket dengan lagu
    // (`ArtworkType.AUDIO`), bukan fallback via album art.
    final audioId = int.tryParse(mediaItem.id);
    final albumArtId = mediaItem.extras?['albumArtId'] as int?;
    final heroTag = 'song-artwork-${mediaItem.id}';
    final handler = ref.read(audioHandlerProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      // Isolasi `BackdropFilter` (mahal secara GPU) dari repaint tetangganya;
      // pola sama dengan `GradientBlob` (audit performa PRD.md § 11).
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Material(
              color: AppColors.surface.withValues(alpha: 0.6),
              // Default `clipBehavior` di `Material` adalah `Clip.none`;
              // tanpa ini, ink splash dari InkWell di bawah (yang membentang
              // selebar pill) bisa bocor melewati sudut membulat saat
              // ditekan, sekilas kelihatan seperti kotak di belakang bentuk
              // pill.
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NowPlayingScreen(heroTag: heroTag),
                  ),
                ),
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Hero(
                        tag: heroTag,
                        child: SongArtwork(
                          audioId: audioId,
                          albumArtId: albumArtId,
                          gradientSeed: ArtworkGradients.songSeed(
                            mediaItem.title,
                            mediaItem.artist ?? '',
                          ),
                          size: 44,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              mediaItem.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextTheme.bodyMedium.copyWith(
                                color: AppColors.ink,
                              ),
                            ),
                            if (mediaItem.artist != null)
                              Text(
                                mediaItem.artist!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextTheme.bodySmall.copyWith(
                                  color: AppColors.ash,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        iconSize: 20,
                        color: shuffleOn ? AppColors.primary : AppColors.ash,
                        icon: const Icon(Icons.shuffle),
                        onPressed: () => handler.setShuffleEnabled(!shuffleOn),
                      ),
                      Material(
                        color: AppColors.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          splashColor: Colors.black12,
                          highlightColor: Colors.black12,
                          onTap: () =>
                              playing ? handler.pause() : handler.play(),
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: Icon(
                              playing ? Icons.pause : Icons.play_arrow,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
