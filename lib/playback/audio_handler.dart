import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:just_audio/just_audio.dart' as ja;

import '../data/local/hive/hive_setup.dart';
import '../data/local/hive/playback_state_cache.dart';
import '../data/repositories/app_preferences_repository.dart';
import '../data/repositories/library_repository.dart';
import '../data/repositories/play_stats_repository.dart';
import '../models/song.dart';
import 'output_detector.dart';
import 'queue_manager.dart';

/// Satu-satunya pintu ke `just_audio` player (Architecture.md § 4). Semua
/// perubahan playback (`playing`, `position`, `queue index`) di-broadcast
/// lewat stream `audio_service` (`playbackState`/`mediaItem`/`queue`); UI
/// dan provider tidak pernah subscribe langsung ke just_audio.
class BeatfyAudioHandler extends BaseAudioHandler {
  BeatfyAudioHandler({
    required this.libraryRepository,
    required this.playStatsRepository,
    required this.appPreferencesRepository,
    OutputDetector? outputDetector,
  }) : _outputDetector = outputDetector ?? OutputDetector() {
    _listenToPlaybackEvents();
    _listenToOutputDisconnect();
    _listenToPlayStats();
    _startPeriodicPersist();
    unawaited(_restoreAudioEnhancementFromPrefs());
  }

  final LibraryRepository libraryRepository;
  final PlayStatsRepository playStatsRepository;
  final AppPreferencesRepository appPreferencesRepository;
  final OutputDetector _outputDetector;

  // Audio Enhancement (Architecture.md § 7a); pakai audio effect bawaan
  // just_audio (native android.media.audiofx di baliknya), bukan platform
  // channel custom: just_audio sudah handle re-attach effect ke
  // audioSessionId baru tiap kali platform player di-recreate (ganti lagu/
  // reset), dan release native resource otomatis saat `_player.dispose()`.
  // Tidak ada BassBoost API di just_audio; bass boost didekati lewat band
  // rendah equalizer di `_applyEnhancementPreset`.
  final _loudnessEnhancer = ja.AndroidLoudnessEnhancer();
  final _equalizer = ja.AndroidEqualizer();
  late final _player = ja.AudioPlayer(
    audioPipeline: ja.AudioPipeline(
      androidAudioEffects: [_loudnessEnhancer, _equalizer],
    ),
  );

  List<Song> _currentSongs = [];
  RepeatMode _repeatMode = RepeatMode.off;
  bool _playStatsCounted = false;

  StreamSubscription<void>? _outputSub;
  StreamSubscription<int?>? _playStatsIndexSub;
  StreamSubscription<Duration>? _playStatsPositionSub;
  Timer? _periodicPersistTimer;

  Stream<ActiveOutput> get activeOutputStream =>
      _outputDetector.activeOutputStream;

  // ---------------------------------------------------------------------
  // Restore; Architecture.md § 4: WAJIB di-await di main() sebelum
  // runApp(), supaya Now Playing/mini player pertama kali render sudah
  // dengan queue+posisi yang benar, bukan kosong lalu "loncat". Ini fix
  // langsung untuk bug "posisi playback reset ke awal lagu" (PRD.md § 1).
  // ---------------------------------------------------------------------
  Future<void> restoreFromCache() async {
    final box = Hive.box<PlaybackStateCache>(HiveBoxes.playbackState);
    final cache = box.get(playbackStateCacheKey);
    if (cache == null || cache.queueSongIds.isEmpty) return;

    final songs = cache.queueSongIds
        .map(libraryRepository.getById)
        .whereType<Song>()
        .toList();
    if (songs.isEmpty) return;

    // Kalau ada lagu yang hilang dari cache (file dihapus sejak sesi
    // terakhir), clamp index supaya tidak out-of-range alih-alih crash.
    final index = cache.queueIndex.clamp(0, songs.length - 1);

    _currentSongs = songs;
    _repeatMode = cache.repeatMode;
    queue.add(songs.map(QueueManager.toMediaItem).toList());
    mediaItem.add(QueueManager.toMediaItem(songs[index]));

    try {
      await _player.setAudioSources(
        QueueManager.toAudioSources(songs),
        initialIndex: index,
        initialPosition: Duration(milliseconds: cache.positionMs),
      );
      await _player.setShuffleModeEnabled(cache.shuffleEnabled);
      await _player.setLoopMode(QueueManager.toLoopMode(cache.repeatMode));

      // Status SELALU di-restore sebagai paused, terlepas dari isPlaying
      // terakhir; keputusan final Pann (PRD.md § 11) untuk mencegah audio
      // auto-blast tak terduga (mis. HP baru diambil dari kantong). User
      // tap play manual untuk lanjut. `_player` sudah default tidak playing
      // setelah `setAudioSources`; tidak ada langkah tambahan diperlukan.
      _broadcastState();

      // Simpan ulang cache supaya `isPlaying` yang tersimpan konsisten
      // dengan status nyata (paused) setelah restore, bukan meninggalkan
      // nilai lama dari sesi sebelumnya sampai event persist berikutnya.
      await _persist();
    } on Object {
      // File yang direferensikan cache mungkin sudah tidak valid/pindah;
      // gagal restore bukan alasan untuk crash startup.
    }
  }

  // ---------------------------------------------------------------------
  // Entry point dipanggil provider/UI untuk mulai queue baru.
  // ---------------------------------------------------------------------
  Future<void> playFromSongs(List<Song> songs, int startIndex) async {
    _currentSongs = songs;
    queue.add(songs.map(QueueManager.toMediaItem).toList());
    mediaItem.add(QueueManager.toMediaItem(songs[startIndex]));
    await _player.setAudioSources(
      QueueManager.toAudioSources(songs),
      initialIndex: startIndex,
    );
    await _player.setLoopMode(QueueManager.toLoopMode(_repeatMode));
    await _player.play();
  }

  /// Dipanggil setelah real file delete sukses (Architecture.md § 4a);
  /// kalau lagu yang dihapus ada di queue saat ini, buang dari queue tanpa
  /// crash; kalau itu lagu yang sedang diputar, auto-lanjut ke berikutnya
  /// (bukan pause diam di tengah lagu yang filenya sudah tidak ada).
  Future<void> handleSongDeleted(int songId) async {
    final index = _currentSongs.indexWhere((song) => song.id == songId);
    if (index == -1) return;

    if (_currentSongs.length == 1) {
      await stop();
      _currentSongs = [];
      queue.add(const []);
      mediaItem.add(null);
      return;
    }

    final currentPlayerIndex = _player.currentIndex ?? 0;
    final wasCurrent = currentPlayerIndex == index;
    final position = _player.position;

    final songs = [..._currentSongs]..removeAt(index);
    final newIndex = wasCurrent
        ? index.clamp(0, songs.length - 1)
        : (currentPlayerIndex > index
              ? currentPlayerIndex - 1
              : currentPlayerIndex);

    _currentSongs = songs;
    queue.add(songs.map(QueueManager.toMediaItem).toList());
    await _player.setAudioSources(
      QueueManager.toAudioSources(songs),
      initialIndex: newIndex,
      initialPosition: wasCurrent ? Duration.zero : position,
    );
    mediaItem.add(QueueManager.toMediaItem(songs[newIndex]));
    if (wasCurrent) await _player.play();
    _broadcastState(queueIndex: newIndex);
    await _persist();
  }

  Future<void> setShuffleEnabled(bool enabled) async {
    await _player.setShuffleModeEnabled(enabled);
    _broadcastState();
    await _persist();
  }

  Future<void> cycleRepeatMode() async {
    _repeatMode = switch (_repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
    await _player.setLoopMode(QueueManager.toLoopMode(_repeatMode));
    _broadcastState();
    await _persist();
  }

  // ---------------------------------------------------------------------
  // BaseAudioHandler overrides; satu-satunya jalur play/pause/seek ke player.
  // ---------------------------------------------------------------------
  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await _persist();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) await _player.seekToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) await _player.seekToPrevious();
  }

  @override
  Future<void> skipToQueueItem(int index) =>
      _player.seek(Duration.zero, index: index);

  // ---------------------------------------------------------------------
  // Android Auto / media browsing (docs/prompt_android_auto.md). Flat list
  // only for now (Langkah 2); album/artist/playlist grouping belum perlu,
  // itu iterasi lanjutan. Reuses `libraryRepository` (sumber yang sama
  // dipakai Library tab) dan `QueueManager.toMediaItem` (sumber yang sama
  // dipakai notification/lock-screen); Android Auto tidak pernah punya
  // query path atau representasi lagu sendiri (Architecture.md § 2 prinsip
  // 1 & 2).
  // ---------------------------------------------------------------------
  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async {
    if (parentMediaId != AudioService.browsableRootId) return const [];
    return libraryRepository
        .getCachedSongs()
        .map(QueueManager.toMediaItem)
        .toList();
  }

  /// Dipanggil head unit saat user pilih lagu dari daftar browse. Queue-nya
  /// SELALU seluruh library (bukan cuma satu lagu); supaya next/prev dari
  /// head unit punya sesuatu untuk dilanjutkan, sama seperti tap lagu dari
  /// Library tab di HP (`playFromSongs`, satu-satunya jalur mulai play,
  /// Architecture.md § 4).
  @override
  Future<void> playFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) async {
    final songId = int.tryParse(mediaId);
    if (songId == null) return;

    final songs = libraryRepository.getCachedSongs();
    final index = songs.indexWhere((song) => song.id == songId);
    if (index == -1) return;

    await playFromSongs(songs, index);
  }

  // ---------------------------------------------------------------------
  // Broadcast state + persistence triggers.
  // ---------------------------------------------------------------------
  void _listenToPlaybackEvents() {
    _player.playbackEventStream.listen(
      (event) => _broadcastState(queueIndex: event.currentIndex),
      onError: (Object error, StackTrace stackTrace) {
        // just_audio sudah mengubah error load jadi processingState idle;
        // di sini cuma jaga-jaga supaya stream tidak mati kalau ada error
        // tak terduga; playback lain di queue harus tetap bisa dicoba.
      },
    );

    _player.currentIndexStream.listen((index) {
      if (index == null || index >= _currentSongs.length) return;
      mediaItem.add(QueueManager.toMediaItem(_currentSongs[index]));
      unawaited(_persist());
    });

    // Menutupi kedua kasus: event pause DAN event play (Architecture.md § 4
    // minta persist "setiap event pause"; playingStream sekalian menutupi
    // resume supaya status isPlaying di cache selalu akurat).
    _player.playingStream.listen((_) => unawaited(_persist()));
  }

  void _broadcastState({int? queueIndex}) {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (_player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 3],
        processingState: const {
          ja.ProcessingState.idle: AudioProcessingState.idle,
          ja.ProcessingState.loading: AudioProcessingState.loading,
          ja.ProcessingState.buffering: AudioProcessingState.buffering,
          ja.ProcessingState.ready: AudioProcessingState.ready,
          ja.ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: queueIndex ?? _player.currentIndex,
        repeatMode: switch (_repeatMode) {
          RepeatMode.off => AudioServiceRepeatMode.none,
          RepeatMode.one => AudioServiceRepeatMode.one,
          RepeatMode.all => AudioServiceRepeatMode.all,
        },
        shuffleMode: _player.shuffleModeEnabled
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
      ),
    );
  }

  void _listenToOutputDisconnect() {
    _outputSub = _outputDetector.onOutputDisconnected.listen((_) {
      if (_player.playing) pause();
    });
  }

  /// Increment play count sekali per lagu, begitu posisi lewat >50% durasi
  /// (Schema.md § 3 "PlayStats"). Subscription baru terpisah; tidak
  /// mengubah listener playback/persist yang sudah teruji.
  void _listenToPlayStats() {
    // `.distinct()` wajib; `currentIndexStream` bisa re-emit index yang
    // SAMA berkali-kali (bukan cuma saat pindah lagu), yang tanpa ini akan
    // reset `_playStatsCounted` berulang kali dan bikin satu kali dengar
    // tercatat sebagai banyak play (playCount meledak).
    _playStatsIndexSub = _player.currentIndexStream.distinct().listen(
      (_) => _playStatsCounted = false,
    );

    _playStatsPositionSub = _player.positionStream.listen((position) {
      if (_playStatsCounted) return;
      final duration = _player.duration;
      if (duration == null || duration <= Duration.zero) return;
      if (position.inMilliseconds < duration.inMilliseconds * 0.5) return;

      final index = _player.currentIndex;
      if (index == null || index >= _currentSongs.length) return;

      _playStatsCounted = true;
      unawaited(playStatsRepository.recordPlay(_currentSongs[index].id));
    });
  }

  // ---------------------------------------------------------------------
  // Audio Enhancement (Architecture.md § 7c, revisi 2026-08-28); dulu aktif
  // otomatis tanpa toggle dengan gain agresif (loudness +6 dB, EQ hingga +6
  // dB), yang terbukti menyebabkan warna suara "tidak natural" dibanding app
  // passthrough (mis. Telegram); makin kentara lewat Bluetooth SBC karena
  // headroom codec itu lebih sempit dari wired/speaker. Sekarang default-nya
  // OFF (playback = passthrough murni, sama seperti app lain), opt-in lewat
  // toggle+slider di Settings. Nilai `enabled`/`targetGain`/band gain
  // disimpan di sisi Dart oleh just_audio dan otomatis dikirim ulang tiap
  // platform player baru dibuat (ganti lagu/reset session); tidak perlu
  // listen manual ke `androidAudioSessionId` di sini.
  // ---------------------------------------------------------------------

  /// Gain (dB) referensi tempat bentuk kurva `_presetGainForFrequency`
  /// dikalibrasi; dipakai untuk menyekalakan band EQ proporsional terhadap
  /// `gainDb` yang dipilih user (lihat `_applyEnhancementPreset`).
  static const _referenceGainDb = 6.0;

  Future<void> _restoreAudioEnhancementFromPrefs() async {
    final prefs = appPreferencesRepository.get();
    try {
      await _loudnessEnhancer.setEnabled(prefs.audioEnhancementEnabled);
      await _equalizer.setEnabled(prefs.audioEnhancementEnabled);
      if (prefs.audioEnhancementEnabled) {
        await _applyEnhancementPreset(prefs.audioEnhancementGainDb);
      }

      // Konfirmasi eksplisit lewat logcat (Architecture.md § 7c minta
      // dipastikan effect ini benar-benar attach, bukan cuma ter-kode);
      // cari tag "AudioEnhancement" saat QC di device.
      debugPrint(
        'AudioEnhancement: restored; enabled=${prefs.audioEnhancementEnabled}, '
        'gain=${prefs.audioEnhancementGainDb}dB',
      );
    } on Object catch (error, stackTrace) {
      // Sebelumnya gagal diam-diam (unhandled Future error, tidak pernah
      // ke-log jelas); sekarang eksplisit supaya kelihatan di logcat kalau
      // effect ini gagal attach di device tertentu (mis. tidak didukung
      // chipset/OEM audio stack), bukan tertelan tanpa jejak.
      debugPrint('AudioEnhancement: FAILED to attach; $error\n$stackTrace');
    }
  }

  /// Toggle dipanggil dari Settings (`audioEnhancementEnabledProvider`).
  /// Persist di sini (bukan di provider) supaya AudioHandler tetap
  /// satu-satunya otoritas state playback+effect (Architecture.md § 4),
  /// sama pola dengan `_persist()` untuk playback cache.
  Future<void> setAudioEnhancementEnabled(bool enabled) async {
    final prefs = appPreferencesRepository.get();
    await appPreferencesRepository.save(
      prefs.copyWith(audioEnhancementEnabled: enabled),
    );
    await _loudnessEnhancer.setEnabled(enabled);
    await _equalizer.setEnabled(enabled);
    if (enabled) await _applyEnhancementPreset(prefs.audioEnhancementGainDb);
  }

  /// Slider gain dipanggil dari Settings (`audioEnhancementGainProvider`).
  Future<void> setAudioEnhancementGain(double gainDb) async {
    final prefs = appPreferencesRepository.get();
    await appPreferencesRepository.save(
      prefs.copyWith(audioEnhancementGainDb: gainDb),
    );
    if (prefs.audioEnhancementEnabled) await _applyEnhancementPreset(gainDb);
  }

  /// Band gain baru bisa di-set setelah `parameters` resolve, yaitu setelah
  /// platform player pertama kali aktif (butuh source ter-load); biasanya
  /// sesaat setelah `restoreFromCache`/`playFromSongs` jalan.
  Future<void> _applyEnhancementPreset(double gainDb) async {
    await _loudnessEnhancer.setTargetGain(gainDb);

    final parameters = await _equalizer.parameters;
    final scale = gainDb / _referenceGainDb;
    for (final band in parameters.bands) {
      final gain = (_presetGainForFrequency(band.centerFrequency) * scale)
          .clamp(parameters.minDecibels, parameters.maxDecibels)
          .toDouble();
      await band.setGain(gain);
    }
  }

  /// Bentuk kurva clarity/warmth + "bass boost" lewat band rendah equalizer
  ///; just_audio tidak expose `BassBoost` API, jadi didekati lewat sini.
  /// Dikalibrasi di gain referensi `_referenceGainDb` (6 dB); nilai aktual
  /// yang diterapkan disekalakan proporsional lewat `_applyEnhancementPreset`
  /// terhadap gain yang user pilih di slider.
  double _presetGainForFrequency(double centerFrequencyHz) {
    if (centerFrequencyHz < 250) return 6; // bass lebih terasa
    if (centerFrequencyHz < 1000) return 1; // low-mid sedikit terangkat
    if (centerFrequencyHz < 6000) return 3; // clarity vokal/instrumen
    return 2; // "air" di treble, masih hindari sibilance berlebih
  }

  void _startPeriodicPersist() {
    _periodicPersistTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_player.playing) unawaited(_persist());
    });
  }

  Future<void> _persist() async {
    if (_currentSongs.isEmpty) return;
    final index = _player.currentIndex;
    if (index == null || index >= _currentSongs.length) return;

    final box = Hive.box<PlaybackStateCache>(HiveBoxes.playbackState);
    await box.put(
      playbackStateCacheKey,
      PlaybackStateCache(
        currentSongId: _currentSongs[index].id,
        positionMs: _player.position.inMilliseconds,
        queueSongIds: QueueManager.songIdsOf(_currentSongs),
        queueIndex: index,
        shuffleEnabled: _player.shuffleModeEnabled,
        repeatMode: _repeatMode,
        isPlaying: _player.playing,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> disposeHandler() async {
    _periodicPersistTimer?.cancel();
    await _outputSub?.cancel();
    await _playStatsIndexSub?.cancel();
    await _playStatsPositionSub?.cancel();
    await _player.dispose();
  }
}
