// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cloud_backup_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CloudBackupRecordAdapter extends TypeAdapter<CloudBackupRecord> {
  @override
  final typeId = 5;

  @override
  CloudBackupRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CloudBackupRecord(
      songId: (fields[0] as num).toInt(),
      driveFileId: fields[1] as String?,
      backupStatus: fields[2] == null
          ? BackupStatus.pending
          : fields[2] as BackupStatus,
      lastAttemptAt: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CloudBackupRecord obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.songId)
      ..writeByte(1)
      ..write(obj.driveFileId)
      ..writeByte(2)
      ..write(obj.backupStatus)
      ..writeByte(3)
      ..write(obj.lastAttemptAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CloudBackupRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BackupStatusAdapter extends TypeAdapter<BackupStatus> {
  @override
  final typeId = 9;

  @override
  BackupStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BackupStatus.pending;
      case 1:
        return BackupStatus.uploading;
      case 2:
        return BackupStatus.done;
      case 3:
        return BackupStatus.failed;
      default:
        return BackupStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, BackupStatus obj) {
    switch (obj) {
      case BackupStatus.pending:
        writer.writeByte(0);
      case BackupStatus.uploading:
        writer.writeByte(1);
      case BackupStatus.done:
        writer.writeByte(2);
      case BackupStatus.failed:
        writer.writeByte(3);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
