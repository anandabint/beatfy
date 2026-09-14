import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/app_preferences_repository.dart';

/// Di-override di main() (Architecture.md § 2).
final appPreferencesRepositoryProvider = Provider<AppPreferencesRepository>((
  ref,
) {
  throw UnimplementedError(
    'appPreferencesRepositoryProvider must be overridden in main()',
  );
});

/// Flag onboarding (Architecture.md § 4b)  baca sinkron dari Hive, sudah
/// terbuka sebelum `runApp` (Architecture.md § 4, `HiveSetup.init`), jadi
/// tidak butuh `AsyncNotifier`.
class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(appPreferencesRepositoryProvider).get().hasSeenOnboarding;

  /// Dipanggil setelah onboarding selesai (baik lewat sign-in sukses maupun
  /// "Lewati" di halaman sign-in)  Architecture.md § 4b. Tidak pernah
  /// di-set balik ke `false`.
  Future<void> complete() async {
    final repository = ref.read(appPreferencesRepositoryProvider);
    await repository.save(repository.get().copyWith(hasSeenOnboarding: true));
    state = true;
  }
}

final onboardingProvider = NotifierProvider<OnboardingNotifier, bool>(
  OnboardingNotifier.new,
);
