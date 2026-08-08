import 'package:hive_ce/hive_ce.dart';

part 'app_preferences.g.dart';

/// Flag onboarding, single-entry (key `'current'`, sama pola dengan
/// `PlaybackStateCache`/`UserProfileCache`) — Schema.md § 3.
@HiveType(typeId: 11)
class AppPreferences extends HiveObject {
  AppPreferences({this.hasSeenOnboarding = false});

  /// Set `true` setelah user selesai atau tap "Lewati" di halaman sign-in
  /// akhir onboarding. Onboarding tidak tampil lagi setelah ini, terlepas
  /// status login (Architecture.md § 4b).
  @HiveField(0)
  final bool hasSeenOnboarding;

  AppPreferences copyWith({bool? hasSeenOnboarding}) {
    return AppPreferences(
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
    );
  }
}
