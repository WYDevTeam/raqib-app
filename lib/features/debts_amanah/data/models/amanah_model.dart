import 'package:hive/hive.dart';

class AmanahModel extends HiveObject {
  final String id;
  final String personName;
  final double amount;
  final int receivedDateMs;
  final int? expectedReturnDateMs;
  final String note;
  bool isReturned;

  AmanahModel({
    required this.id,
    required this.personName,
    required this.amount,
    required this.receivedDateMs,
    this.expectedReturnDateMs,
    this.note = '',
    this.isReturned = false,
  });

  DateTime get receivedDate =>
      DateTime.fromMillisecondsSinceEpoch(receivedDateMs);
  DateTime? get expectedReturnDate => expectedReturnDateMs != null
      ? DateTime.fromMillisecondsSinceEpoch(expectedReturnDateMs!)
      : null;
}

class AmanahModelAdapter extends TypeAdapter<AmanahModel> {
  @override
  final int typeId = 6;

  @override
  AmanahModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AmanahModel(
      id: fields[0] as String,
      personName: fields[1] as String,
      amount: fields[2] as double,
      receivedDateMs: fields[3] as int,
      expectedReturnDateMs: fields[4] as int?,
      note: fields[5] as String,
      isReturned: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AmanahModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.personName)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.receivedDateMs)
      ..writeByte(4)
      ..write(obj.expectedReturnDateMs)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.isReturned);
  }
}
