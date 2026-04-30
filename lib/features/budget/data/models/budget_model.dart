import 'package:hive/hive.dart';

import '../../domain/entities/budget_entity.dart';

class BudgetModel extends HiveObject {
  final String id;
  final String categoryId;
  final int year;
  final int month;
  final double monthlyTarget;
  final bool applyToAllUpcoming;
  final int createdAtMs;
  bool isActive;

  BudgetModel({
    required this.id,
    required this.categoryId,
    required this.year,
    required this.month,
    required this.monthlyTarget,
    required this.applyToAllUpcoming,
    required this.createdAtMs,
    this.isActive = true,
  });

  DateTime get createdAt => DateTime.fromMillisecondsSinceEpoch(createdAtMs);

  BudgetEntity toEntity() {
    return BudgetEntity(
      id: id,
      categoryId: categoryId,
      year: year,
      month: month,
      monthlyTarget: monthlyTarget,
      applyToAllUpcoming: applyToAllUpcoming,
    );
  }

  factory BudgetModel.fromEntity(BudgetEntity entity) {
    return BudgetModel(
      id: entity.id,
      categoryId: entity.categoryId,
      year: entity.year,
      month: entity.month,
      monthlyTarget: entity.monthlyTarget,
      applyToAllUpcoming: entity.applyToAllUpcoming,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }
}

class BudgetModelAdapter extends TypeAdapter<BudgetModel> {
  @override
  final int typeId = 7;

  @override
  BudgetModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BudgetModel(
      id: fields[0] as String,
      categoryId: fields[1] as String,
      year: fields[2] as int,
      month: fields[3] as int,
      monthlyTarget: fields[4] as double,
      applyToAllUpcoming: fields[5] as bool,
      createdAtMs: fields[6] as int,
      isActive: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, BudgetModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.categoryId)
      ..writeByte(2)
      ..write(obj.year)
      ..writeByte(3)
      ..write(obj.month)
      ..writeByte(4)
      ..write(obj.monthlyTarget)
      ..writeByte(5)
      ..write(obj.applyToAllUpcoming)
      ..writeByte(6)
      ..write(obj.createdAtMs)
      ..writeByte(7)
      ..write(obj.isActive);
  }
}
