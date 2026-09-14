import 'package:hive_ce/hive_ce.dart';

import '../../models/favorite.dart';
import '../local/hive/hive_setup.dart';

/// Favorite lagu  Schema.md § 3, PRD.md § 7 poin 2 (bukan tab terpisah,
/// section/filter di dalam Library tab).
class FavoriteRepository {
  FavoriteRepository({Box<Favorite>? box})
    : _box = box ?? Hive.box<Favorite>(HiveBoxes.favorites);

  final Box<Favorite> _box;

  bool isFavorite(int songId) => _box.containsKey(songId);

  Set<int> favoriteIds() => _box.keys.cast<int>().toSet();

  Future<void> toggleFavorite(int songId) async {
    if (_box.containsKey(songId)) {
      await _box.delete(songId);
    } else {
      await _box.put(songId, Favorite(songId: songId, addedAt: DateTime.now()));
    }
  }

  /// Dipakai saat song dihapus dari device (Architecture.md § 4a)  beda
  /// dari [toggleFavorite] karena harus unconditional (tidak boleh malah
  /// nambah entry baru kalau kebetulan belum favorit).
  Future<void> remove(int songId) async {
    if (_box.containsKey(songId)) await _box.delete(songId);
  }
}
