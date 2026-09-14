import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

import 'package:beatfy/app.dart';
import 'package:beatfy/data/local/hive/hive_setup.dart';
import 'package:beatfy/data/local/hive/playback_state_cache.dart';
import 'package:beatfy/data/repositories/favorite_repository.dart';
import 'package:beatfy/data/repositories/library_repository.dart';
import 'package:beatfy/data/repositories/play_stats_repository.dart';
import 'package:beatfy/data/repositories/playlist_repository.dart';
import 'package:beatfy/hive_registrar.g.dart';
import 'package:beatfy/data/repositories/app_preferences_repository.dart';
import 'package:beatfy/models/favorite.dart';
import 'package:beatfy/models/app_preferences.dart';
import 'package:beatfy/models/play_stats.dart';
import 'package:beatfy/models/playlist.dart';
import 'package:beatfy/models/song.dart';
import 'package:beatfy/providers/onboarding_providers.dart';
import 'package:beatfy/providers/favorite_providers.dart';
import 'package:beatfy/providers/home_providers.dart';
import 'package:beatfy/providers/library_providers.dart';
import 'package:beatfy/providers/playlist_providers.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    // `Hive.init` (bukan `initFlutter`) supaya tidak butuh path_provider
    // platform channel  tidak tersedia di `flutter test` biasa.
    tempDir = await Directory.systemTemp.createTemp('beatfy_test_hive');
    Hive.init(tempDir.path);
    Hive.registerAdapters();
    await Hive.openBox<Song>(HiveBoxes.songs);
    await Hive.openBox<PlaybackStateCache>(HiveBoxes.playbackState);
    await Hive.openBox<Playlist>(HiveBoxes.playlists);
    await Hive.openBox<Favorite>(HiveBoxes.favorites);
    await Hive.openBox<PlayStats>(HiveBoxes.playStats);
    await Hive.openBox<AppPreferences>(HiveBoxes.appPreferences);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('Beatfy app renders first-launch onboarding', (WidgetTester tester) async {
    final appPreferencesRepository = AppPreferencesRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          libraryRepositoryProvider.overrideWithValue(LibraryRepository()),
          favoriteRepositoryProvider.overrideWithValue(FavoriteRepository()),
          playStatsRepositoryProvider.overrideWithValue(PlayStatsRepository()),
          playlistRepositoryProvider.overrideWithValue(PlaylistRepository()),
          appPreferencesRepositoryProvider.overrideWithValue(
            appPreferencesRepository,
          ),
        ],
        child: const BeatfyApp(),
      ),
    );
    await tester.pump();

    final title = find.text('Selamat datang di Beatfy');
    expect(title, findsOneWidget);
    expect(Theme.of(tester.element(title)).brightness, Brightness.dark);
  });
}
