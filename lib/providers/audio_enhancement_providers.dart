import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'onboarding_providers.dart';
import 'playback_providers.dart';

/// Toggle "Audio Enhancement" (loudness enhancer + EQ) di Settings 
/// default OFF (Architecture.md § 7c, revisi 2026-08-28). Persist dan
/// penerapan efek nyata terjadi di `BeatfyAudioHandler` (satu-satunya
/// otoritas playback state) lewat `setAudioEnhancementEnabled`; provider ini
/// cuma expose state itu ke UI.
class AudioEnhancementToggleNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(appPreferencesRepositoryProvider).get().audioEnhancementEnabled;

  Future<void> toggle(bool enabled) async {
    await ref.read(audioHandlerProvider).setAudioEnhancementEnabled(enabled);
    state = enabled;
  }
}

final audioEnhancementEnabledProvider =
    NotifierProvider<AudioEnhancementToggleNotifier, bool>(
      AudioEnhancementToggleNotifier.new,
    );

/// Slider gain (dB) untuk loudness enhancer + skala EQ  lihat
/// `BeatfyAudioHandler.setAudioEnhancementGain`.
class AudioEnhancementGainNotifier extends Notifier<double> {
  @override
  double build() =>
      ref.watch(appPreferencesRepositoryProvider).get().audioEnhancementGainDb;

  Future<void> setGain(double gainDb) async {
    await ref.read(audioHandlerProvider).setAudioEnhancementGain(gainDb);
    state = gainDb;
  }
}

final audioEnhancementGainProvider =
    NotifierProvider<AudioEnhancementGainNotifier, double>(
      AudioEnhancementGainNotifier.new,
    );
