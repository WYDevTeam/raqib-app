import 'package:hive/hive.dart';

/// Singleton settings record — stored under key 'settings' in the box.
///
/// themeMode:       0=system, 1=light, 2=dark
/// debtNetWorthMode: 0=conservative, 1=total, 2=perDebt
/// cumulativeMode:  0=last12Months, 1=allTime
class AppSettingsModel extends HiveObject {
  String currency;
  String language;
  int themeMode;
  bool onboardingCompleted;

  // Calculation settings
  bool amanahAddedToLiquidCash;
  bool amanahDeductedFromNetWorth;
  int debtNetWorthMode;
  bool investmentIncludedInNetBalance;
  int cumulativeMode;

  AppSettingsModel({
    this.currency = 'USD',
    this.language = 'ar',
    this.themeMode = 0,
    this.onboardingCompleted = false,
    this.amanahAddedToLiquidCash = false,
    this.amanahDeductedFromNetWorth = true,
    this.debtNetWorthMode = 0,
    this.investmentIncludedInNetBalance = true,
    this.cumulativeMode = 0,
  });
}

class AppSettingsModelAdapter extends TypeAdapter<AppSettingsModel> {
  @override
  final int typeId = 9;

  @override
  AppSettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettingsModel(
      currency: fields[0] as String,
      language: fields[1] as String,
      themeMode: fields[2] as int,
      onboardingCompleted: fields[3] as bool,
      amanahAddedToLiquidCash: fields[4] as bool,
      amanahDeductedFromNetWorth: fields[5] as bool,
      debtNetWorthMode: fields[6] as int,
      investmentIncludedInNetBalance: fields[7] as bool,
      cumulativeMode: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettingsModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.currency)
      ..writeByte(1)
      ..write(obj.language)
      ..writeByte(2)
      ..write(obj.themeMode)
      ..writeByte(3)
      ..write(obj.onboardingCompleted)
      ..writeByte(4)
      ..write(obj.amanahAddedToLiquidCash)
      ..writeByte(5)
      ..write(obj.amanahDeductedFromNetWorth)
      ..writeByte(6)
      ..write(obj.debtNetWorthMode)
      ..writeByte(7)
      ..write(obj.investmentIncludedInNetBalance)
      ..writeByte(8)
      ..write(obj.cumulativeMode);
  }
}
