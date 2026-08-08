// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback_state_cache.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlaybackStateCacheAdapter extends TypeAdapter<PlaybackStateCache> {
  @override
  final typeId = 1;

  @override
  PlaybackStateCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlaybackStateCache(
      currentSongId: (fields[0] as num?)?.toInt(),
      positionMs: (fields[1] as num).toInt(),
      queueSongIds: (fields[2] as List).cast<int>(),
      queueIndex: (fields[3] as num).toInt(),
      shuffleEnabled: fields[4] as bool,
      repeatMode: fields[5] as RepeatMode,
      isPlaying: fields[6] as bool,
      updatedAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PlaybackStateCache obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.currentSongId)
      ..writeByte(1)
      ..write(obj.positionMs)
      ..writeByte(2)
      ..write(obj.queueSongIds)
      ..writeByte(3)
      ..write(obj.queueIndex)
      ..writeByte(4)
      ..write(obj.shuffleEnabled)
      ..writeByte(5)
      ..write(obj.repeatMode)
      ..writeByte(6)
      ..write(obj.isPlaying)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackStateCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RepeatModeAdapter extends TypeAdapter<RepeatMode> {
  @override
  final typeId = 7;

  @override
  RepeatMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RepeatMode.off;
      case 1:
        return RepeatMode.one;
      case 2:
        return RepeatMode.all;
      default:
        return RepeatMode.off;
    }
  }

  @override
  void write(BinaryWriter writer, RepeatMode obj) {
    switch (obj) {
      case RepeatMode.off:
        writer.writeByte(0);
      case RepeatMode.one:
        writer.writeByte(1);
      case RepeatMode.all:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepeatModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
