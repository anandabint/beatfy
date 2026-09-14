import 'package:hive_ce/hive_ce.dart';

part 'app_preferences.g.dart';

/// Flag onboarding, single-entry (key `'current'`, sama pola dengan
/// `PlaybackStateCache`/`UserProfileCache`)  Schema.md § 3.
@HiveType(typeId: 11)
class AppPreferences extends HiveObject {
  AppPreferences({
    this.hasSeenOnboarding = false,
    this.audioEnhancementEnabled = false,
    this.audioEnhancementGainDb = 2.5,
  });

  /// Set `true` setelah user selesai atau tap "Lewati" di halaman sign-in
  /// akhir onboarding. Onboarding tidak tampil lagi setelah ini, terlepas
  /// status login (Architecture.md § 4b).
  @HiveField(0)
  final bool hasSeenOnboarding;

  /// Master switch loudness enhancer + EQ (Architecture.md § 7c, revisi
  /// 2026-08-28). Default `false`  playback default sekarang passthrough
  /// murni (sama seperti app lain yang tidak memproses ulang sinyal),
  /// bukan lagi aktif otomatis untuk semua orang/semua output. User yang
  /// mau suara "lebih hidup" mengaktifkannya sendiri di Settings.
  @HiveField(1)
  final bool audioEnhancementEnabled;

  /// Gain (dB) dipakai untuk `LoudnessEnhancer.targetGain` sekaligus skala
  /// intensitas preset EQ V-shape di `_applyEnhancementPreset`  satu angka
  /// yang user kendalikan lewat slider di Settings, bukan hardcoded. Default
  /// 2.5 dB jauh di bawah preset lama (6 dB) yang terbukti berisiko clipping
  /// di MP3 bitrate rendah + lebih gampang kedengaran lewat Bluetooth SBC.
  @HiveField(2)
  final double audioEnhancementGainDb;

  AppPreferences copyWith({
    bool? hasSeenOnboarding,
    bool? audioEnhancementEnabled,
    double? audioEnhancementGainDb,
  }) {
    return AppPreferences(
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      audioEnhancementEnabled:
          audioEnhancementEnabled ?? this.audioEnhancementEnabled,
      audioEnhancementGainDb:
          audioEnhancementGainDb ?? this.audioEnhancementGainDb,
    );
  }
}
