import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/user_profile_repository.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

/// Di-override di main() (Architecture.md § 2 — repository sebagai
/// satu-satunya jalur data).
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  throw UnimplementedError(
    'userProfileRepositoryProvider must be overridden in main()',
  );
});

/// Profil user Google — opsional, null berarti belum/tidak sign-in (Home
/// fallback ke greeting waktu, PRD.md § 7 poin 5). `build()` HANYA baca
/// `UserProfileCache` lokal — **tidak ada call live ke Google di sini**
/// (Architecture.md § 4c, fix bug popup sign-in otomatis tiap app dibuka).
/// Status login yang tampil di UI dianggap benar selama cache lokal
/// konsisten, yang hanya di-update lewat [signIn]/[signOut] eksplisit.
class UserProfileNotifier extends AsyncNotifier<UserProfileCache?> {
  @override
  Future<UserProfileCache?> build() async {
    final repository = ref.watch(userProfileRepositoryProvider);
    return repository.get();
  }

  /// Sign-in interaktif — dipanggil dari tombol "Sign in with Google" di
  /// Settings screen. Error dilempar ke pemanggil (UI) supaya bisa
  /// ditampilkan, bukan ditelan di sini, karena ini hasil aksi eksplisit
  /// user yang butuh feedback.
  ///
  /// Sekalian minta authorization Drive (`drive.file`) di sini juga —
  /// selagi masih dalam konteks gesture eksplisit user yang sama, consent
  /// screen Drive (kalau memang perlu muncul) terasa jadi kelanjutan wajar
  /// dari tap sign-in, bukan popup yang muncul sendiri di background nanti
  /// (lihat `AuthService.getDriveAuthClient` — bug nyata yang diperbaiki
  /// 2026-08-07). Gagal di sini diam-diam saja, tidak boleh menggagalkan
  /// sign-in utama — greeting tetap harus jalan meski Drive belum
  /// terotorisasi (mis. masih diblokir status verifikasi OAuth Google).
  Future<void> signIn() async {
    final repository = ref.read(userProfileRepositoryProvider);
    final account = await AuthService.signIn();
    final profile = UserProfileCache(
      displayName: account.displayName,
      email: account.email,
      photoUrl: account.photoUrl,
    );
    await repository.save(profile);
    state = AsyncData(profile);

    try {
      await AuthService.requestDriveAuthorizationInteractive();
    } on Object {
      // Diam — auto-backup cukup tetap "pending" sampai otorisasi Drive
      // berhasil di kesempatan berikutnya (trigger WiFi, retry silent).
    }
  }

  Future<void> signOut() async {
    final repository = ref.read(userProfileRepositoryProvider);
    await AuthService.signOut();
    await repository.clear();
    state = const AsyncData(null);
  }
}

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfileCache?>(
      UserProfileNotifier.new,
    );
