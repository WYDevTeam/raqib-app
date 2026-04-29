import 'package:hive/hive.dart';

class AssetModel extends HiveObject {
  final String id;
  final String name;
  final String type; // 'gold', 'silver', 'crypto', 'other'
  final String symbol; // 'XAU', 'XAG', 'BTCUSDT', '' for manual
  final double quantity;
  final String unit; // 'غرام', 'BTC', 'عقار', etc.
  final double totalCost;
  double currentValuePerUnit;
  int? lastPriceUpdateMs;
  final int createdAtMs;
  final String note;

  AssetModel({
    required this.id,
    required this.name,
    required this.type,
    required this.symbol,
    required this.quantity,
    required this.unit,
    required this.totalCost,
    required this.currentValuePerUnit,
    this.lastPriceUpdateMs,
    required this.createdAtMs,
    this.note = '',
  });

  double get currentTotalValue => quantity * currentValuePerUnit;
  double get unrealizedPnl => currentTotalValue - totalCost;
}

class AssetModelAdapter extends TypeAdapter<AssetModel> {
  @override
  final int typeId = 3;

  @override
  AssetModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AssetModel(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as String,
      symbol: fields[3] as String,
      quantity: fields[4] as double,
      unit: fields[5] as String,
      totalCost: fields[6] as double,
      currentValuePerUnit: fields[7] as double,
      lastPriceUpdateMs: fields[8] as int?,
      createdAtMs: fields[9] as int,
      note: fields[10] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AssetModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.symbol)
      ..writeByte(4)
      ..write(obj.quantity)
      ..writeByte(5)
      ..write(obj.unit)
      ..writeByte(6)
      ..write(obj.totalCost)
      ..writeByte(7)
      ..write(obj.currentValuePerUnit)
      ..writeByte(8)
      ..write(obj.lastPriceUpdateMs)
      ..writeByte(9)
      ..write(obj.createdAtMs)
      ..writeByte(10)
      ..write(obj.note);
  }
}
