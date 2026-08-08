import 'package:hive_ce/hive_ce.dart';

import '../../models/user_profile.dart';
import '../local/hive/hive_setup.dart';

/// Cache lokal profil akun Google — Schema.md § 3. Satu entry saja (sama
/// pola dengan `PlaybackStateCache`), key tetap `_key`.
class UserProfileRepository {
  UserProfileRepository({Box<UserProfileCache>? box})
    : _box = box ?? Hive.box<UserProfileCache>(HiveBoxes.userProfile);

  final Box<UserProfileCache> _box;

  static const _key = 'current';

  UserProfileCache? get() => _box.get(_key);

  Future<void> save(UserProfileCache profile) => _box.put(_key, profile);

  Future<void> clear() => _box.delete(_key);
}
