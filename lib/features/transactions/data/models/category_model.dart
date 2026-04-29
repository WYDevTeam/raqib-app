import 'package:hive/hive.dart';

import '../../domain/entities/category_entity.dart';

class CategoryModel extends HiveObject {
  final String id;
  final String name;
  final String emoji;
  final int colorValue;
  final int typeValue;

  CategoryModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.colorValue,
    required this.typeValue,
  });

  CategoryEntity toEntity() => CategoryEntity(
        id: id,
        name: name,
        emoji: emoji,
        colorValue: colorValue,
        type: CategoryType.fromInt(typeValue),
      );

  static CategoryModel fromEntity(CategoryEntity e) => CategoryModel(
        id: e.id,
        name: e.name,
        emoji: e.emoji,
        colorValue: e.colorValue,
        typeValue: e.type.hiveValue,
      );
}

class CategoryModelAdapter extends TypeAdapter<CategoryModel> {
  @override
  final int typeId = 1;

  @override
  CategoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoryModel(
      id: fields[0] as String,
      name: fields[1] as String,
      emoji: fields[2] as String,
      colorValue: fields[3] as int,
      typeValue: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.emoji)
      ..writeByte(3)
      ..write(obj.colorValue)
      ..writeByte(4)
      ..write(obj.typeValue);
  }
}
