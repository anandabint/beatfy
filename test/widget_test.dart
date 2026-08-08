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
import 'package:beatfy/models/favorite.dart';
import 'package:beatfy/models/play_stats.dart';
import 'package:beatfy/models/playlist.dart';
import 'package:beatfy/models/song.dart';
import 'package:beatfy/providers/favorite_providers.dart';
import 'package:beatfy/providers/home_providers.dart';
import 'package:beatfy/providers/library_providers.dart';
import 'package:beatfy/providers/playlist_providers.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    // `Hive.init` (bukan `initFlutter`) supaya tidak butuh path_provider
    // platform channel — tidak tersedia di `flutter test` biasa.
    tempDir = await Directory.systemTemp.createTemp('beatfy_test_hive');
    Hive.init(tempDir.path);
    Hive.registerAdapters();
    await Hive.openBox<Song>(HiveBoxes.songs);
    await Hive.openBox<PlaybackStateCache>(HiveBoxes.playbackState);
    await Hive.openBox<Playlist>(HiveBoxes.playlists);
    await Hive.openBox<Favorite>(HiveBoxes.favorites);
    await Hive.openBox<PlayStats>(HiveBoxes.playStats);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('Beatfy app renders the dark theme shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          libraryRepositoryProvider.overrideWithValue(LibraryRepository()),
          favoriteRepositoryProvider.overrideWithValue(FavoriteRepository()),
          playStatsRepositoryProvider.overrideWithValue(PlayStatsRepository()),
          playlistRepositoryProvider.overrideWithValue(PlaylistRepository()),
        ],
        child: const BeatfyApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Beatfy'), findsOneWidget);
    expect(Theme.of(tester.element(find.text('Beatfy'))).brightness, Brightness.dark);
  });
}
