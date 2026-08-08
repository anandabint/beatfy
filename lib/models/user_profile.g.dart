// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileCacheAdapter extends TypeAdapter<UserProfileCache> {
  @override
  final typeId = 8;

  @override
  UserProfileCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfileCache(
      displayName: fields[0] as String?,
      email: fields[1] as String,
      photoUrl: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfileCache obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.displayName)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.photoUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
