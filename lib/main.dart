import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'features/transactions/data/datasources/category_hive_datasource.dart';
import 'features/transactions/data/models/category_model.dart';
import 'features/transactions/data/models/transaction_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(CategoryModelAdapter());

  await Hive.openBox<TransactionModel>('transactions');
  final categoryBox = await Hive.openBox<CategoryModel>('categories');

  await setupDI();

  await CategoryHiveDatasource(categoryBox).seedDefaultsIfEmpty();

  runApp(const MainApp());
}
