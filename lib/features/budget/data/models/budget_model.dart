import 'package:hive/hive.dart';

/// period: 0=monthly, 1=weekly, 2=yearly
class BudgetModel extends HiveObject {
  final String id;
  final String name;
  final String categoryId; // '' = applies to all spending
  final double limitAmount;
  final int period;
  final int createdAtMs;
  bool isActive;

  BudgetModel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.limitAmount,
    required this.period,
    required this.createdAtMs,
    this.isActive = true,
  });

  DateTime get createdAt => DateTime.fromMillisecondsSinceEpoch(createdAtMs);
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
      name: fields[1] as String,
      categoryId: fields[2] as String,
      limitAmount: fields[3] as double,
      period: fields[4] as int,
      createdAtMs: fields[5] as int,
      isActive: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, BudgetModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.categoryId)
      ..writeByte(3)
      ..write(obj.limitAmount)
      ..writeByte(4)
      ..write(obj.period)
      ..writeByte(5)
      ..write(obj.createdAtMs)
      ..writeByte(6)
      ..write(obj.isActive);
  }
}
