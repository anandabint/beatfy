import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../../../hive_registrar.g.dart';
import '../../../models/app_preferences.dart';
import '../../../models/cloud_backup_meta.dart';
import '../../../models/cloud_backup_record.dart';
import '../../../models/favorite.dart';
import '../../../models/play_stats.dart';
import '../../../models/playlist.dart';
import '../../../models/song.dart';
import '../../../models/user_profile.dart';
import 'playback_state_cache.dart';

/// Box names  Schema.md § 2, § 3.
abstract final class HiveBoxes {
  static const songs = 'songs';
  static const playbackState = 'playback_state';
  static const playlists = 'playlists';
  static const favorites = 'favorites';
  static const playStats = 'play_stats';
  static const userProfile = 'user_profile';
  static const cloudBackup = 'cloud_backup';
  static const cloudBackupMeta = 'cloud_backup_meta';
  static const appPreferences = 'app_preferences';
}

/// Key of the single `PlaybackStateCache` entry in [HiveBoxes.playbackState].
const playbackStateCacheKey = 'current';

/// Opens Hive and all v1+v2 boxes. Must run before `runApp` and before
/// `AudioService.init`  the AudioHandler restores from these boxes at
/// construction time (Architecture.md § 4).
abstract final class HiveSetup {
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapters();

    await Hive.openBox<Song>(HiveBoxes.songs);
    await Hive.openBox<PlaybackStateCache>(HiveBoxes.playbackState);
    await Hive.openBox<Playlist>(HiveBoxes.playlists);
    await Hive.openBox<Favorite>(HiveBoxes.favorites);
    await Hive.openBox<PlayStats>(HiveBoxes.playStats);
    await Hive.openBox<UserProfileCache>(HiveBoxes.userProfile);
    await Hive.openBox<CloudBackupRecord>(HiveBoxes.cloudBackup);
    await Hive.openBox<CloudBackupMeta>(HiveBoxes.cloudBackupMeta);
    await Hive.openBox<AppPreferences>(HiveBoxes.appPreferences);
  }
}
