import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'features/transactions/data/datasources/category_hive_datasource.dart';
import 'features/transactions/data/models/category_model.dart';
import 'features/transactions/data/models/recurring_rule_model.dart';
import 'features/transactions/data/models/transaction_model.dart';
import 'features/transactions/presentation/cubit/recurring_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();

  await Hive.initFlutter();
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(CategoryModelAdapter());
  Hive.registerAdapter(RecurringRuleModelAdapter());

  await Hive.openBox<TransactionModel>('transactions');
  final categoryBox = await Hive.openBox<CategoryModel>('categories');
  await Hive.openBox<RecurringRuleModel>('recurring_rules');

  await setupDI();

  await CategoryHiveDatasource(categoryBox).seedDefaultsIfEmpty();

  // ── Process due recurring transactions at startup ──────────────────────────
  // This runs before the first frame so by the time the UI loads,
  // all generated transactions are already in the box.
  await sl<RecurringCubit>().processAllRules();

  runApp(const MainApp());
}

