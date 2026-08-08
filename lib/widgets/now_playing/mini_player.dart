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

/// Floating pill di atas bottom nav — Design.md § 7 ("Mini player"). Tap
/// untuk expand ke Now Playing screen.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaItem = ref.watch(currentMediaItemProvider).value;
    final playbackState = ref.watch(playbackStateProvider).value;

    if (mediaItem == null) return const SizedBox.shrink();

    final playing = playbackState?.playing ?? false;
    final shuffleOn = playbackState?.shuffleMode == AudioServiceShuffleMode.all;
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          // Default `clipBehavior` di `Material` adalah `Clip.none` — tanpa
          // ini, ink splash dari InkWell di bawah (yang membentang selebar
          // pill) bisa bocor melewati sudut membulat saat ditekan,
          // sekilas kelihatan seperti kotak di belakang bentuk pill.
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NowPlayingScreen(heroTag: heroTag),
              ),
            ),
            borderRadius: BorderRadius.circular(AppRadius.pill),
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
                      onTap: () => playing ? handler.pause() : handler.play(),
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
    );
  }
}
