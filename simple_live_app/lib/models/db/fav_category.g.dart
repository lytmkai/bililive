// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fav_category.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FavCategoryAdapter extends TypeAdapter<FavCategory> {
  @override
  final int typeId = 5;

  @override
  FavCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FavCategory(
      id: fields[0] as String,
      parentAreaName: fields[1] as String,
      areaName: fields[2] as String,
      areaId: fields[3] as String,
      parentAreaId: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FavCategory obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.parentAreaName)
      ..writeByte(2)
      ..write(obj.areaName)
      ..writeByte(3)
      ..write(obj.areaId)
      ..writeByte(4)
      ..write(obj.parentAreaId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
