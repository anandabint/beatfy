// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'play_stats.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlayStatsAdapter extends TypeAdapter<PlayStats> {
  @override
  final typeId = 4;

  @override
  PlayStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlayStats(
      songId: (fields[0] as num).toInt(),
      playCount: (fields[1] as num).toInt(),
      lastPlayedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PlayStats obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.songId)
      ..writeByte(1)
      ..write(obj.playCount)
      ..writeByte(2)
      ..write(obj.lastPlayedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
