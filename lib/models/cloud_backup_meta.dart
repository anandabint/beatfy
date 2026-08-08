import 'package:hive_ce/hive_ce.dart';

part 'cloud_backup_meta.g.dart';

/// Metadata cloud backup, single-entry (key `'current'`, sama pola dengan
/// `PlaybackStateCache`/`UserProfileCache`) — Schema.md § 3.
@HiveType(typeId: 10)
class CloudBackupMeta extends HiveObject {
  CloudBackupMeta({this.driveFolderId, this.autoBackupEnabled = true});

  /// Id folder "Beatfy Backup" di Drive user — di-cache supaya tidak perlu
  /// query pencarian folder tiap kali mau upload.
  @HiveField(0)
  final String? driveFolderId;

  /// Toggle di Settings screen — kalau false, listener konektivitas tidak
  /// memicu upload otomatis.
  @HiveField(1)
  final bool autoBackupEnabled;

  CloudBackupMeta copyWith({String? driveFolderId, bool? autoBackupEnabled}) {
    return CloudBackupMeta(
      driveFolderId: driveFolderId ?? this.driveFolderId,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
    );
  }
}
