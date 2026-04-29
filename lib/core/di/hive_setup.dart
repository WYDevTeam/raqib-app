import 'package:hive_flutter/hive_flutter.dart';

import '../../features/budget/data/models/budget_model.dart';
import '../../features/dashboard/data/models/dashboard_widget_model.dart';
import '../../features/debts_amanah/data/models/amanah_model.dart';
import '../../features/debts_amanah/data/models/debt_model.dart';
import '../../features/investments/data/models/asset_model.dart';
import '../../features/investments/data/models/asset_transaction_model.dart';
import '../../features/settings/data/models/app_settings_model.dart';
import '../../features/transactions/data/datasources/category_hive_datasource.dart';
import '../../features/transactions/data/models/category_model.dart';
import '../../features/transactions/data/models/recurring_rule_model.dart';
import '../../features/transactions/data/models/transaction_model.dart';

abstract final class HiveSetup {
  static Future<void> initialize() async {
    await Hive.initFlutter();
    _registerAdapters();
    await _openBoxes();
    await _seedDefaults();
  }

  static void _registerAdapters() {
    Hive.registerAdapter(TransactionModelAdapter());
    Hive.registerAdapter(CategoryModelAdapter());
    Hive.registerAdapter(RecurringRuleModelAdapter());
    Hive.registerAdapter(AssetModelAdapter());
    Hive.registerAdapter(AssetTransactionModelAdapter());
    Hive.registerAdapter(DebtModelAdapter());
    Hive.registerAdapter(AmanahModelAdapter());
    Hive.registerAdapter(BudgetModelAdapter());
    Hive.registerAdapter(DashboardWidgetModelAdapter());
    Hive.registerAdapter(AppSettingsModelAdapter());
  }

  static Future<void> _openBoxes() async {
    await Hive.openBox<TransactionModel>('transactions');
    await Hive.openBox<CategoryModel>('categories');
    await Hive.openBox<RecurringRuleModel>('recurring_rules');
    await Hive.openBox<AssetModel>('assets');
    await Hive.openBox<AssetTransactionModel>('asset_transactions');
    await Hive.openBox<DebtModel>('debts');
    await Hive.openBox<AmanahModel>('amanah');
    await Hive.openBox<BudgetModel>('budgets');
    await Hive.openBox<DashboardWidgetModel>('dashboard_widgets');
    await Hive.openBox<AppSettingsModel>('settings');
  }

  static Future<void> _seedDefaults() async {
    final categoryBox = Hive.box<CategoryModel>('categories');
    await CategoryHiveDatasource(categoryBox).seedDefaultsIfEmpty();

    final settingsBox = Hive.box<AppSettingsModel>('settings');
    if (settingsBox.isEmpty) {
      await settingsBox.put('settings', AppSettingsModel());
    }
  }
}
