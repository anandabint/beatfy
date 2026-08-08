import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/favorite_repository.dart';

/// Di-override di main() (Architecture.md § 2 — repository sebagai
/// satu-satunya jalur data).
final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  throw UnimplementedError(
    'favoriteRepositoryProvider must be overridden in main()',
  );
});

/// Set songId favorit saat ini. Semua mutasi lewat `.toggle()` di sini
/// (satu-satunya jalur, jadi tidak perlu watch Hive box terpisah).
class FavoriteIdsNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => ref.watch(favoriteRepositoryProvider).favoriteIds();

  Future<void> toggle(int songId) async {
    final repository = ref.read(favoriteRepositoryProvider);
    await repository.toggleFavorite(songId);
    state = repository.favoriteIds();
  }
}

final favoriteIdsProvider = NotifierProvider<FavoriteIdsNotifier, Set<int>>(
  FavoriteIdsNotifier.new,
);
