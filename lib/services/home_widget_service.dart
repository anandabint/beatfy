import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:home_widget/home_widget.dart';

import '../playback/audio_handler.dart';

/// Pushes data to the Android home screen widget (docs/prompt_home_widget.md
/// Langkah 3). Pure listener, zero playback logic of its own — subscribes to
/// the exact same `AudioHandler` streams the Flutter UI providers already
/// watch (`playback_providers.dart`), never a second/polling data source
/// (Architecture.md § 2 prinsip 2). Button taps on the widget never come
/// back through this class — they go straight from the native
/// `BeatfyHomeWidgetProvider` to `MediaButtonReceiver`, same path as the
/// notification's own controls.
class HomeWidgetService {
  HomeWidgetService(this._audioHandler);

  final BeatfyAudioHandler _audioHandler;

  StreamSubscription<MediaItem?>? _mediaItemSub;
  StreamSubscription<PlaybackState>? _playbackStateSub;
  bool _lastPlaying = false;

  static const _androidWidgetName = 'BeatfyHomeWidgetProvider';

  /// Push whatever state already exists (covers the case where
  /// `restoreFromCache` already restored a song before this starts) then
  /// keep listening for changes.
  Future<void> start() async {
    _lastPlaying = _audioHandler.playbackState.valueOrNull?.playing ?? false;
    await _push(_audioHandler.mediaItem.valueOrNull, _lastPlaying);

    _mediaItemSub = _audioHandler.mediaItem.listen((item) {
      unawaited(_push(item, _lastPlaying));
    });

    // `playbackState` re-emits on every position tick, not just play/pause
    // toggles — only push when `playing` actually flips, otherwise this
    // would hammer the widget with redundant updates several times a second.
    _playbackStateSub = _audioHandler.playbackState.listen((state) {
      if (state.playing == _lastPlaying) return;
      _lastPlaying = state.playing;
      unawaited(_push(_audioHandler.mediaItem.valueOrNull, _lastPlaying));
    });
  }

  Future<void> _push(MediaItem? item, bool playing) async {
    await HomeWidget.saveWidgetData<bool>('hasSong', item != null);
    await HomeWidget.saveWidgetData<String>('title', item?.title ?? '');
    await HomeWidget.saveWidgetData<String>('artist', item?.artist ?? '');
    await HomeWidget.saveWidgetData<String>(
      'artUri',
      item?.artUri?.toString() ?? '',
    );
    await HomeWidget.saveWidgetData<bool>('playing', playing);
    await HomeWidget.updateWidget(androidName: _androidWidgetName);
  }

  Future<void> dispose() async {
    await _mediaItemSub?.cancel();
    await _playbackStateSub?.cancel();
  }
}
