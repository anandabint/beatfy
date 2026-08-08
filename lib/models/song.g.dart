// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SongAdapter extends TypeAdapter<Song> {
  @override
  final typeId = 0;

  @override
  Song read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Song(
      id: (fields[0] as num).toInt(),
      title: fields[1] as String,
      artist: fields[2] as String,
      album: fields[3] as String?,
      duration: (fields[4] as num).toInt(),
      filePath: fields[5] as String,
      dateAdded: fields[6] as DateTime,
      dateModified: (fields[7] as num).toInt(),
      albumArtId: (fields[8] as num?)?.toInt(),
      source: fields[9] == null
          ? SongSource.mediaStoreScan
          : fields[9] as SongSource,
      dataPath: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Song obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.artist)
      ..writeByte(3)
      ..write(obj.album)
      ..writeByte(4)
      ..write(obj.duration)
      ..writeByte(5)
      ..write(obj.filePath)
      ..writeByte(6)
      ..write(obj.dateAdded)
      ..writeByte(7)
      ..write(obj.dateModified)
      ..writeByte(8)
      ..write(obj.albumArtId)
      ..writeByte(9)
      ..write(obj.source)
      ..writeByte(10)
      ..write(obj.dataPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SongSourceAdapter extends TypeAdapter<SongSource> {
  @override
  final typeId = 6;

  @override
  SongSource read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SongSource.mediaStoreScan;
      default:
        return SongSource.mediaStoreScan;
    }
  }

  @override
  void write(BinaryWriter writer, SongSource obj) {
    switch (obj) {
      case SongSource.mediaStoreScan:
        writer.writeByte(0);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongSourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
