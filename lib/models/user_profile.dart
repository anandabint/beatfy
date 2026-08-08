import 'package:hive_ce/hive_ce.dart';

part 'user_profile.g.dart';

/// Cache lokal akun Google (opsional) — Schema.md § 3. Login sepenuhnya
/// opsional; box kosong berarti belum/tidak sign-in, Home fallback ke
/// greeting berbasis waktu (PRD.md § 7 poin 5). Bukan sumber kebenaran auth
/// (itu tetap Google Sign-In SDK) — murni cache untuk personalisasi
/// greeting tanpa perlu hit Google tiap buka app.
@HiveType(typeId: 8)
class UserProfileCache extends HiveObject {
  UserProfileCache({
    required this.displayName,
    required this.email,
    this.photoUrl,
  });

  @HiveField(0)
  final String? displayName;

  @HiveField(1)
  final String email;

  /// Foto profil akun Google (`GoogleSignInAccount.photoUrl`) — Schema.md
  /// § 3, field ditambahkan 2026-08-07 buat avatar asli (Design.md § 7).
  /// Nullable: sebagian akun Google tidak punya foto.
  @HiveField(2)
  final String? photoUrl;
}
