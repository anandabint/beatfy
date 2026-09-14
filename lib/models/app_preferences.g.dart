// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_preferences.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppPreferencesAdapter extends TypeAdapter<AppPreferences> {
  @override
  final typeId = 11;

  @override
  AppPreferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppPreferences(
      hasSeenOnboarding: fields[0] == null ? false : fields[0] as bool,
      audioEnhancementEnabled: fields[1] == null ? false : fields[1] as bool,
      audioEnhancementGainDb: fields[2] == null ? 2.5 : fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, AppPreferences obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.hasSeenOnboarding)
      ..writeByte(1)
      ..write(obj.audioEnhancementEnabled)
      ..writeByte(2)
      ..write(obj.audioEnhancementGainDb);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppPreferencesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
