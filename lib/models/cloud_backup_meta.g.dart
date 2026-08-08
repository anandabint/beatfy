// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cloud_backup_meta.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CloudBackupMetaAdapter extends TypeAdapter<CloudBackupMeta> {
  @override
  final typeId = 10;

  @override
  CloudBackupMeta read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CloudBackupMeta(
      driveFolderId: fields[0] as String?,
      autoBackupEnabled: fields[1] == null ? true : fields[1] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CloudBackupMeta obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.driveFolderId)
      ..writeByte(1)
      ..write(obj.autoBackupEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CloudBackupMetaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
