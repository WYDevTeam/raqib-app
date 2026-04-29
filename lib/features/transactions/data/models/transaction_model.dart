import 'package:hive/hive.dart';

import '../../domain/entities/transaction_entity.dart';

class TransactionModel extends HiveObject {
  final String id;
  final double amount;
  final String categoryId;
  final String description;
  final DateTime date;
  final bool isIncome;
  final bool isRecurring;
  final String? frequency;
  final DateTime? endDate;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.description,
    required this.date,
    required this.isIncome,
    required this.isRecurring,
    this.frequency,
    this.endDate,
  });

  TransactionEntity toEntity() => TransactionEntity(
        id: id,
        amount: amount,
        categoryId: categoryId,
        description: description,
        date: date,
        isIncome: isIncome,
        isRecurring: isRecurring,
        frequency: RecurrenceFrequency.fromString(frequency),
        endDate: endDate,
      );

  static TransactionModel fromEntity(TransactionEntity e) => TransactionModel(
        id: e.id,
        amount: e.amount,
        categoryId: e.categoryId,
        description: e.description,
        date: e.date,
        isIncome: e.isIncome,
        isRecurring: e.isRecurring,
        frequency: e.frequency?.hiveKey,
        endDate: e.endDate,
      );
}

class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = 0;

  @override
  TransactionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionModel(
      id: fields[0] as String,
      amount: fields[1] as double,
      categoryId: fields[2] as String,
      description: fields[3] as String,
      date: fields[4] as DateTime,
      isIncome: fields[5] as bool,
      isRecurring: fields[6] as bool,
      frequency: fields[7] as String?,
      endDate: fields[8] as DateTime?, // null for old records without this field
    );
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.categoryId)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.isIncome)
      ..writeByte(6)
      ..write(obj.isRecurring)
      ..writeByte(7)
      ..write(obj.frequency)
      ..writeByte(8)
      ..write(obj.endDate);
  }
}
