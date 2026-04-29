import 'package:hive/hive.dart';

import '../../domain/entities/recurring_rule_entity.dart';
import '../../domain/entities/transaction_entity.dart';

class RecurringRuleModel extends HiveObject {
  final String id;
  final double amount;
  final String categoryId;
  final String description;
  final bool isIncome;
  final String frequency; // RecurrenceFrequency.hiveKey
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? lastGeneratedDate;
  final bool isActive;

  RecurringRuleModel({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.description,
    required this.isIncome,
    required this.frequency,
    required this.startDate,
    required this.isActive,
    this.endDate,
    this.lastGeneratedDate,
  });

  RecurringRuleEntity toEntity() => RecurringRuleEntity(
        id: id,
        amount: amount,
        categoryId: categoryId,
        description: description,
        isIncome: isIncome,
        frequency: RecurrenceFrequency.fromString(frequency)!,
        startDate: startDate,
        endDate: endDate,
        lastGeneratedDate: lastGeneratedDate,
        isActive: isActive,
      );

  static RecurringRuleModel fromEntity(RecurringRuleEntity e) =>
      RecurringRuleModel(
        id: e.id,
        amount: e.amount,
        categoryId: e.categoryId,
        description: e.description,
        isIncome: e.isIncome,
        frequency: e.frequency.hiveKey,
        startDate: e.startDate,
        endDate: e.endDate,
        lastGeneratedDate: e.lastGeneratedDate,
        isActive: e.isActive,
      );
}

class RecurringRuleModelAdapter extends TypeAdapter<RecurringRuleModel> {
  @override
  final int typeId = 2;

  @override
  RecurringRuleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringRuleModel(
      id: fields[0] as String,
      amount: fields[1] as double,
      categoryId: fields[2] as String,
      description: fields[3] as String,
      isIncome: fields[4] as bool,
      frequency: fields[5] as String,
      startDate: fields[6] as DateTime,
      endDate: fields[7] as DateTime?,
      lastGeneratedDate: fields[8] as DateTime?,
      isActive: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringRuleModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.categoryId)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.isIncome)
      ..writeByte(5)
      ..write(obj.frequency)
      ..writeByte(6)
      ..write(obj.startDate)
      ..writeByte(7)
      ..write(obj.endDate)
      ..writeByte(8)
      ..write(obj.lastGeneratedDate)
      ..writeByte(9)
      ..write(obj.isActive);
  }
}
