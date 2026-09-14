import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/theme/app_colors.dart';
import 'data/local/hive/hive_setup.dart';
import 'data/repositories/app_preferences_repository.dart';
import 'data/repositories/cloud_backup_repository.dart';
import 'data/repositories/favorite_repository.dart';
import 'data/repositories/library_repository.dart';
import 'data/repositories/play_stats_repository.dart';
import 'data/repositories/playlist_repository.dart';
import 'data/repositories/user_profile_repository.dart';
import 'playback/audio_handler.dart';
import 'providers/auth_providers.dart';
import 'providers/cloud_backup_providers.dart';
import 'providers/favorite_providers.dart';
import 'providers/home_providers.dart';
import 'providers/library_providers.dart';
import 'providers/onboarding_providers.dart';
import 'providers/playback_providers.dart';
import 'providers/playlist_providers.dart';
import 'services/home_widget_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Performance gate (PRD.md § 11) — Android caps render di 60Hz meski
  // device support lebih tinggi kecuali diminta eksplisit. Android-only API;
  // gagal diam-diam di platform lain (mis. flutter run -d chrome saat dev).
  try {
    await FlutterDisplayMode.setHighRefreshRate();
  } on Object {
    // no-op — refresh rate tetap default kalau device/platform tidak support.
  }

  // Architecture.md § 7c (KRITIS) — harus eksplisit dan selesai sebelum
  // player manapun mulai. Tanpa ini, just_audio hanya menerapkan config
  // AndroidAudioAttributes lewat fallback lazy `AudioSession.setActive()`
  // (dipanggil saat play() pertama), yang rawan race/di-preempt kalau ada
  // package lain yang sempat men-`configure()` session lebih dulu dengan
  // config berbeda — hasilnya bisa jatuh ke profil Bluetooth panggilan
  // (SCO/HFP, mono narrowband, "memendam") bukan profil media (A2DP, stereo
  // full-bandwidth). Set eksplisit di sini menghilangkan race itu sama sekali.
  final audioSession = await AudioSession.instance;
  await audioSession.configure(const AudioSessionConfiguration.music());

  await HiveSetup.init();

  final libraryRepository = LibraryRepository();
  final favoriteRepository = FavoriteRepository();
  final playStatsRepository = PlayStatsRepository();
  final playlistRepository = PlaylistRepository();
  final userProfileRepository = UserProfileRepository();
  final cloudBackupRepository = CloudBackupRepository();
  final appPreferencesRepository = AppPreferencesRepository();

  final audioHandler = await AudioService.init(
    builder: () => BeatfyAudioHandler(
      libraryRepository: libraryRepository,
      playStatsRepository: playStatsRepository,
      appPreferencesRepository: appPreferencesRepository,
    ),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.anandabint.beatfy.channel.audio',
      androidNotificationChannelName: 'Beatfy playback',
      // Foreground service (dan notifikasinya) tetap hidup walau paused —
      // wajib untuk sesi playback aktif (Architecture.md § 4). NB:
      // `androidNotificationOngoing: true` butuh `androidStopForegroundOnPause:
      // true` (constraint dari package itu sendiri) jadi tidak dipasang
      // bersamaan — false+false ini sudah cukup untuk menjaga service hidup.
      androidStopForegroundOnPause: false,
      // Wajib true (sudah default package, dipasang eksplisit untuk
      // dokumentasi) — tap notification memicu MainActivity, ditangkap
      // `notificationClickedProvider` di app.dart untuk push Now Playing
      // (Architecture.md § 4a).
      androidNotificationClickStartsActivity: true,
      // Accent color notification/media session (dipakai juga oleh Android
      // Auto untuk aksen di kartu now-playing, docs/prompt_android_auto.md
      // Langkah 3) — satu-satunya titik gaya yang bisa disentuh dari sisi
      // app, sisanya template sistem.
      notificationColor: AppColors.primary,
    ),
  );

  // WAJIB selesai sebelum runApp() — restore queue+posisi sebelum UI pertama
  // kali render (Architecture.md § 4, fix bug utama PRD.md § 1).
  await audioHandler.restoreFromCache();

  // Home screen widget (docs/prompt_home_widget.md) — dijalankan setelah
  // restoreFromCache supaya push pertamanya sudah mencerminkan lagu yang
  // di-restore, bukan state kosong yang langsung menyusul dengan update
  // kedua. Tidak pernah di-dispose — hidup selama proses Flutter hidup,
  // sama seperti provider lain yang subscribe ke `audioHandler`.
  unawaited(HomeWidgetService(audioHandler).start());

  runApp(
    ProviderScope(
      overrides: [
        libraryRepositoryProvider.overrideWithValue(libraryRepository),
        favoriteRepositoryProvider.overrideWithValue(favoriteRepository),
        playStatsRepositoryProvider.overrideWithValue(playStatsRepository),
        playlistRepositoryProvider.overrideWithValue(playlistRepository),
        userProfileRepositoryProvider.overrideWithValue(userProfileRepository),
        cloudBackupRepositoryProvider.overrideWithValue(cloudBackupRepository),
        appPreferencesRepositoryProvider.overrideWithValue(
          appPreferencesRepository,
        ),
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const BeatfyApp(),
    ),
  );
}
