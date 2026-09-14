import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:volume_controller/volume_controller.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_theme.dart';
import '../../core/theme/artwork_gradients.dart';
import '../../core/utils/ambient_color_cache.dart';
import '../../providers/playback_providers.dart';
import '../../widgets/common/gradient_blob.dart';
import '../../widgets/common/song_artwork.dart';

/// Now Playing  album art besar, progress bar (scrubbing), kontrol utama,
/// info lagu (PRD.md § 6.3). Expand dari mini player lewat shared [Hero].
class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key, required this.heroTag});

  final String heroTag;

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  Timer? _ticker;
  double? _dragValueMs;
  String? _ambientLoadedForSongId;
  List<Color>? _ambientColors;

  @override
  void initState() {
    super.initState();
    // Posisi di PlaybackState di-extrapolate (bukan di-emit tiap frame) 
    // ticker lokal ini cuma soal refresh visual seek bar, tidak menyentuh
    // player/persistence sama sekali.
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Ambient color dinamis Now Playing (Architecture.md § 7b)  dipanggil
  /// tiap build tapi hanya benar-benar kerja sekali per pergantian lagu
  /// (guard `_ambientLoadedForSongId`), supaya tidak re-trigger tiap tick
  /// timer 500ms di atas. Cache di [AmbientColorCache] dicek dulu untuk
  /// hasil instan kalau lagu yang sama sudah pernah diputar sesi ini.
  void _syncAmbientColor(MediaItem mediaItem) {
    if (_ambientLoadedForSongId == mediaItem.id) return;
    _ambientLoadedForSongId = mediaItem.id;

    final albumArtId = mediaItem.extras?['albumArtId'] as int?;
    if (albumArtId == null) {
      // Lagu tanpa artwork (pakai fallback gradient)  langsung default
      // blob ungu-pink, tidak ada yang bisa diekstrak.
      _ambientColors = null;
      return;
    }

    final cached = AmbientColorCache.cached(mediaItem.id);
    if (cached != null) {
      _ambientColors = cached;
      return;
    }

    _ambientColors = null;
    AmbientColorCache.extract(mediaItem.id, albumArtId).then((colors) {
      if (!mounted || _ambientLoadedForSongId != mediaItem.id) return;
      setState(() => _ambientColors = colors);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaItem = ref.watch(currentMediaItemProvider).value;
    final playbackState = ref.watch(playbackStateProvider).value;
    final handler = ref.read(audioHandlerProvider);

    if (mediaItem == null) {
      return const Scaffold(
        backgroundColor: AppColors.canvas,
        body: SizedBox.shrink(),
      );
    }

    _syncAmbientColor(mediaItem);

    final playing = playbackState?.playing ?? false;
    final shuffleOn = playbackState?.shuffleMode == AudioServiceShuffleMode.all;
    final repeatMode = playbackState?.repeatMode ?? AudioServiceRepeatMode.none;
    final duration = mediaItem.duration ?? Duration.zero;
    final positionMs =
        (_dragValueMs ?? playbackState?.position.inMilliseconds.toDouble() ?? 0)
            .clamp(0, duration.inMilliseconds.toDouble());
    final albumArtId = mediaItem.extras?['albumArtId'] as int?;
    final audioId = int.tryParse(mediaItem.id);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 60,
            left: -80,
            child: GradientBlob(size: 320, colors: _ambientColors),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              children: [
                // Flex tidak seimbang (revisi 2026-08-07, Design.md § 7) 
                // menaikkan posisi art dengan mengecilkan porsi Spacer atas
                // relatif ke bawah, bukan padding tetap (tetap adaptif ke
                // tinggi layar berapapun).
                const Spacer(flex: 2),
                Padding(
                  // Inset lebih tipis dari sebelumnya (AppSpacing.lg → xs) 
                  // memperbesar art ~8-10% (Design.md § 7 revisi 2026-08-07),
                  // masih menyisakan sedikit ruang di sekitar Hero.
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Hero(
                    tag: widget.heroTag,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: SongArtwork(
                          audioId: audioId,
                          albumArtId: albumArtId,
                          gradientSeed: ArtworkGradients.songSeed(
                            mediaItem.title,
                            mediaItem.artist ?? '',
                          ),
                          size: double.infinity,
                        ),
                      ),
                    ),
                  ),
                ),
                // Design.md § 7 revisi 2026-08-07  jarak art→judul lebih
                // lega, xl (32px) bukan md (12px) yang dipakai sebelumnya.
                // Revisi lanjutan: +AppSpacing.md (12px) lagi di atas itu 
                // art tetap di posisi/ukuran semula, cuma blok judul→volume
                // digeser turun sedikit.
                const SizedBox(height: AppSpacing.xl + AppSpacing.md),
                Text(
                  mediaItem.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextTheme.displayLarge.copyWith(
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  mediaItem.artist ?? 'Unknown Artist',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextTheme.bodyMedium.copyWith(color: AppColors.ash),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Tinggi hit-area eksplisit (Design.md § polish 2026-08-08) 
                // tanpa ini, RenderBox Slider menyusut ke `trackHeight` saja
                // begitu `thumbShape`/`overlayShape` di-null-kan (noThumb/
                // noOverlay biasanya yang menentukan tinggi minimum), bikin
                // area sentuh cuma beberapa px padahal visualnya terlihat
                // lebih tebal. Bulatan/thumb visual TETAP tidak dimunculkan
                // (noThumb dipertahankan)  cuma target sentuhnya diperlebar.
                SizedBox(
                  height: 44,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 6,
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.surfaceMuted,
                      thumbShape: SliderComponentShape.noThumb,
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      min: 0,
                      max: duration.inMilliseconds.toDouble().clamp(
                        1,
                        double.infinity,
                      ),
                      value: positionMs.toDouble(),
                      onChanged: (value) =>
                          setState(() => _dragValueMs = value),
                      onChangeEnd: (value) {
                        handler.seek(Duration(milliseconds: value.toInt()));
                        setState(() => _dragValueMs = null);
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatMs(positionMs.toInt()),
                        style: AppTextTheme.caption.copyWith(
                          color: AppColors.stone,
                        ),
                      ),
                      Text(
                        _formatMs(duration.inMilliseconds),
                        style: AppTextTheme.caption.copyWith(
                          color: AppColors.stone,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      iconSize: 22,
                      color: shuffleOn ? AppColors.primary : AppColors.ash,
                      icon: const Icon(Icons.shuffle),
                      onPressed: () => handler.setShuffleEnabled(!shuffleOn),
                    ),
                    IconButton(
                      iconSize: 30,
                      color: AppColors.ink,
                      icon: const Icon(Icons.skip_previous),
                      onPressed: handler.skipToPrevious,
                    ),
                    _PlayPauseButton(
                      playing: playing,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        playing ? handler.pause() : handler.play();
                      },
                    ),
                    IconButton(
                      iconSize: 30,
                      color: AppColors.ink,
                      icon: const Icon(Icons.skip_next),
                      onPressed: handler.skipToNext,
                    ),
                    IconButton(
                      iconSize: 22,
                      color: repeatMode == AudioServiceRepeatMode.none
                          ? AppColors.ash
                          : AppColors.primary,
                      icon: Icon(
                        repeatMode == AudioServiceRepeatMode.one
                            ? Icons.repeat_one
                            : Icons.repeat,
                      ),
                      onPressed: handler.cycleRepeatMode,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const _VolumeSlider(),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatMs(int ms) {
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes.remainder(60).toString();
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// Volume slider fungsional  Design.md § 7 revisi 2026-08-07. Kontrol
/// `STREAM_MUSIC` asli lewat `volume_controller` (bukan cuma dekorasi):
/// baca volume awal, dengarkan perubahan dari tombol fisik/sumber lain
/// (`addListener`), dan set volume saat slider digeser. `showSystemUI =
/// false` supaya toast volume bawaan Android tidak dobel muncul di atas
/// slider custom ini.
class _VolumeSlider extends StatefulWidget {
  const _VolumeSlider();

  @override
  State<_VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<_VolumeSlider> {
  double _volume = 0;
  StreamSubscription<double>? _subscription;

  @override
  void initState() {
    super.initState();
    VolumeController.instance.showSystemUI = false;
    VolumeController.instance.getVolume().then((value) {
      if (mounted) setState(() => _volume = value);
    });
    _subscription = VolumeController.instance.addListener((value) {
      if (mounted) setState(() => _volume = value);
    }, fetchInitialVolume: false);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    VolumeController.instance.removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.volume_down, color: AppColors.ash, size: 20),
        Expanded(
          // Sama alasan dengan progress bar di atas  tinggi eksplisit
          // supaya area drag nyaman tanpa memunculkan thumb visual.
          child: SizedBox(
            height: 44,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 6,
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.surfaceMuted,
                thumbShape: SliderComponentShape.noThumb,
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                min: 0,
                max: 1,
                value: _volume.clamp(0, 1),
                onChanged: (value) {
                  setState(() => _volume = value);
                  VolumeController.instance.setVolume(value);
                },
              ),
            ),
          ),
        ),
        const Icon(Icons.volume_up, color: AppColors.ash, size: 20),
      ],
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({required this.playing, required this.onTap});

  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        // Splash gelap dari tema global akan terlihat kotor di atas hijau 
        // pakai overlay hitam transparan (senada dengan konten on-primary).
        splashColor: Colors.black12,
        highlightColor: Colors.black12,
        child: SizedBox(
          width: 76,
          height: 76,
          child: Icon(
            playing ? Icons.pause : Icons.play_arrow,
            color: Colors.black,
            size: 36,
          ),
        ),
      ),
    );
  }
}
