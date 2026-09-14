import 'package:hive_ce/hive_ce.dart';

import '../../models/app_preferences.dart';
import '../local/hive/hive_setup.dart';

/// Flag onboarding  Schema.md § 3. Satu entry saja (sama pola dengan
/// `UserProfileRepository`), key tetap `_key`.
class AppPreferencesRepository {
  AppPreferencesRepository({Box<AppPreferences>? box})
    : _box = box ?? Hive.box<AppPreferences>(HiveBoxes.appPreferences);

  final Box<AppPreferences> _box;

  static const _key = 'current';

  AppPreferences get() => _box.get(_key) ?? AppPreferences();

  Future<void> save(AppPreferences prefs) => _box.put(_key, prefs);
}
