import 'package:hive_ce/hive_ce.dart';

part 'cloud_backup_record.g.dart';

/// Status backup satu lagu ke Google Drive — Schema.md § 3.
@HiveType(typeId: 5)
class CloudBackupRecord extends HiveObject {
  CloudBackupRecord({
    required this.songId,
    this.driveFileId,
    this.backupStatus = BackupStatus.pending,
    this.lastAttemptAt,
  });

  /// Key box = [songId] juga (lihat `CloudBackupRepository`).
  @HiveField(0)
  final int songId;

  /// Null = belum ter-upload.
  @HiveField(1)
  final String? driveFileId;

  @HiveField(2)
  final BackupStatus backupStatus;

  @HiveField(3)
  final DateTime? lastAttemptAt;

  CloudBackupRecord copyWith({
    String? driveFileId,
    BackupStatus? backupStatus,
    DateTime? lastAttemptAt,
  }) {
    return CloudBackupRecord(
      songId: songId,
      driveFileId: driveFileId ?? this.driveFileId,
      backupStatus: backupStatus ?? this.backupStatus,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
    );
  }
}

@HiveType(typeId: 9)
enum BackupStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  uploading,
  @HiveField(2)
  done,
  @HiveField(3)
  failed,
}
