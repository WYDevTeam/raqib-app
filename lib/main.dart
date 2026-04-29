import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/di/hive_setup.dart';
import 'core/di/injection.dart';
import 'features/transactions/domain/usecases/process_recurring_transactions_usecase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  await HiveSetup.initialize();
  await setupDI();
  runApp(const MainApp());
  sl<ProcessRecurringTransactionsUseCase>()();
}
