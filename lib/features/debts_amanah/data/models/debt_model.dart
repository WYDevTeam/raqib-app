import 'package:hive/hive.dart';

class DebtModel extends HiveObject {
  final String id;
  final String personName;
  final double totalAmount;
  double paidAmount;
  final int givenDateMs;
  final int? dueDateMs;
  final String note;
  bool isSettled;

  DebtModel({
    required this.id,
    required this.personName,
    required this.totalAmount,
    required this.paidAmount,
    required this.givenDateMs,
    this.dueDateMs,
    this.note = '',
    this.isSettled = false,
  });

  double get remainingAmount => totalAmount - paidAmount;
  double get progress =>
      totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0.0;
  DateTime get givenDate => DateTime.fromMillisecondsSinceEpoch(givenDateMs);
  DateTime? get dueDate =>
      dueDateMs != null ? DateTime.fromMillisecondsSinceEpoch(dueDateMs!) : null;
}

class DebtModelAdapter extends TypeAdapter<DebtModel> {
  @override
  final int typeId = 5;

  @override
  DebtModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DebtModel(
      id: fields[0] as String,
      personName: fields[1] as String,
      totalAmount: fields[2] as double,
      paidAmount: fields[3] as double,
      givenDateMs: fields[4] as int,
      dueDateMs: fields[5] as int?,
      note: fields[6] as String,
      isSettled: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DebtModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.personName)
      ..writeByte(2)
      ..write(obj.totalAmount)
      ..writeByte(3)
      ..write(obj.paidAmount)
      ..writeByte(4)
      ..write(obj.givenDateMs)
      ..writeByte(5)
      ..write(obj.dueDateMs)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.isSettled);
  }
}
