import 'package:hive_ce/hive_ce.dart';

part 'favorite.g.dart';

/// Penanda lagu favorit  Schema.md § 3. Box key = [songId].
@HiveType(typeId: 3)
class Favorite extends HiveObject {
  Favorite({required this.songId, required this.addedAt});

  @HiveField(0)
  final int songId;

  @HiveField(1)
  final DateTime addedAt;
}
