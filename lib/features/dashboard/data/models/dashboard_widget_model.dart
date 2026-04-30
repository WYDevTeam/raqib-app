import 'package:hive/hive.dart';

class DashboardWidgetModel extends HiveObject {
  final String id;
  final String title;
  String formulaExpression;
  bool isVisible;
  int sortOrder;
  String type;
  String displayFormat;

  DashboardWidgetModel({
    required this.id,
    required this.title,
    required this.formulaExpression,
    this.isVisible = true,
    this.sortOrder = 0,
    this.type = 'builtin',
    this.displayFormat = 'number',
  });
}

class DashboardWidgetModelAdapter extends TypeAdapter<DashboardWidgetModel> {
  @override
  final int typeId = 8;

  @override
  DashboardWidgetModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DashboardWidgetModel(
      id: fields[0] as String,
      title: fields[1] as String,
      formulaExpression: fields[2] as String,
      isVisible: fields[3] as bool,
      sortOrder: fields[4] as int,
      type: (fields[5] as String?) ?? 'builtin',
      displayFormat: (fields[6] as String?) ?? 'number',
    );
  }

  @override
  void write(BinaryWriter writer, DashboardWidgetModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.formulaExpression)
      ..writeByte(3)
      ..write(obj.isVisible)
      ..writeByte(4)
      ..write(obj.sortOrder)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.displayFormat);
  }
}
