import 'package:hive/hive.dart';

class AssetTransactionModel extends HiveObject {
  final String id;
  final String assetId;
  final bool isBuy; // true=buy, false=sell
  final double quantity;
  final double pricePerUnit;
  final int dateMs;
  final String note;

  AssetTransactionModel({
    required this.id,
    required this.assetId,
    required this.isBuy,
    required this.quantity,
    required this.pricePerUnit,
    required this.dateMs,
    this.note = '',
  });

  double get totalAmount => quantity * pricePerUnit;
  DateTime get date => DateTime.fromMillisecondsSinceEpoch(dateMs);
}

class AssetTransactionModelAdapter extends TypeAdapter<AssetTransactionModel> {
  @override
  final int typeId = 4;

  @override
  AssetTransactionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AssetTransactionModel(
      id: fields[0] as String,
      assetId: fields[1] as String,
      isBuy: fields[2] as bool,
      quantity: fields[3] as double,
      pricePerUnit: fields[4] as double,
      dateMs: fields[5] as int,
      note: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AssetTransactionModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.assetId)
      ..writeByte(2)
      ..write(obj.isBuy)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.pricePerUnit)
      ..writeByte(5)
      ..write(obj.dateMs)
      ..writeByte(6)
      ..write(obj.note);
  }
}
