import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../playback/audio_handler.dart';
import '../playback/output_detector.dart';

/// Di-override di main() dengan instance yang sama dipakai untuk
/// `AudioService.init()` (Architecture.md § 2, § 4 — AudioHandler adalah
/// satu-satunya otoritas playback state, provider cuma observe).
final audioHandlerProvider = Provider<BeatfyAudioHandler>((ref) {
  throw UnimplementedError('audioHandlerProvider must be overridden in main()');
});

final playbackStateProvider = StreamProvider<PlaybackState>((ref) {
  return ref.watch(audioHandlerProvider).playbackState;
});

final currentMediaItemProvider = StreamProvider<MediaItem?>((ref) {
  return ref.watch(audioHandlerProvider).mediaItem;
});

final queueProvider = StreamProvider<List<MediaItem>>((ref) {
  return ref.watch(audioHandlerProvider).queue;
});

/// Indikator output aktif (speaker/wired/bluetooth) — Architecture.md § 5 poin 3.
final activeOutputProvider = StreamProvider<ActiveOutput>((ref) {
  return ref.watch(audioHandlerProvider).activeOutputStream;
});

/// Tap notification media playback → buka Now Playing — Architecture.md
/// § 4a. `AudioService.notificationClicked` sudah `ValueStream` (seeded
/// `false`) yang replay nilai terakhir ke listener baru — cocok untuk kasus
/// cold-start dari notification (nilainya sudah `true` sebelum
/// listener pertama terpasang).
final notificationClickedProvider = StreamProvider<bool>((ref) {
  return AudioService.notificationClicked;
});
