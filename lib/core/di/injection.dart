import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

import '../../features/transactions/data/datasources/category_hive_datasource.dart';
import '../../features/transactions/data/datasources/recurring_rule_hive_datasource.dart';
import '../../features/transactions/data/datasources/transaction_hive_datasource.dart';
import '../../features/transactions/data/models/category_model.dart';
import '../../features/transactions/data/models/recurring_rule_model.dart';
import '../../features/transactions/data/models/transaction_model.dart';
import '../../features/transactions/data/repositories/recurring_rule_repository_impl.dart';
import '../../features/transactions/data/repositories/transaction_repository_impl.dart';
import '../../features/transactions/domain/repositories/recurring_rule_repository.dart';
import '../../features/transactions/domain/repositories/transaction_repository.dart';
import '../../features/transactions/domain/usecases/add_category_usecase.dart';
import '../../features/transactions/domain/usecases/add_recurring_rule_usecase.dart';
import '../../features/transactions/domain/usecases/add_transaction_usecase.dart';
import '../../features/transactions/domain/usecases/delete_category_usecase.dart';
import '../../features/transactions/domain/usecases/delete_transaction_usecase.dart';
import '../../features/transactions/domain/usecases/get_categories_usecase.dart';
import '../../features/transactions/domain/usecases/get_recurring_rules_usecase.dart';
import '../../features/transactions/domain/usecases/get_transactions_usecase.dart';
import '../../features/transactions/domain/usecases/stop_recurring_rule_usecase.dart';
import '../../features/transactions/domain/usecases/update_category_usecase.dart';
import '../../features/transactions/domain/usecases/update_recurring_rule_usecase.dart';
import '../../features/transactions/domain/usecases/update_transaction_usecase.dart';
import '../../features/transactions/presentation/cubit/category_cubit.dart';
import '../../features/transactions/presentation/cubit/recurring_cubit.dart';
import '../../features/transactions/presentation/cubit/transactions_cubit.dart';

final GetIt sl = GetIt.instance;

Future<void> setupDI() async {
  // ── Hive boxes ─────────────────────────────────────────────────────────────
  final transactionBox = Hive.box<TransactionModel>('transactions');
  final categoryBox = Hive.box<CategoryModel>('categories');
  final recurringRuleBox = Hive.box<RecurringRuleModel>('recurring_rules');

  // ── Datasources ────────────────────────────────────────────────────────────
  sl.registerLazySingleton<TransactionHiveDatasource>(
    () => TransactionHiveDatasource(transactionBox),
  );
  sl.registerLazySingleton<CategoryHiveDatasource>(
    () => CategoryHiveDatasource(categoryBox),
  );
  sl.registerLazySingleton<RecurringRuleHiveDatasource>(
    () => RecurringRuleHiveDatasource(recurringRuleBox),
  );

  // ── Repositories ───────────────────────────────────────────────────────────
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<RecurringRuleRepository>(
    () => RecurringRuleRepositoryImpl(sl()),
  );

  // ── Use cases — Transactions ───────────────────────────────────────────────
  sl.registerLazySingleton(() => GetTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => AddTransactionUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTransactionUseCase(sl()));
  sl.registerLazySingleton(() => DeleteTransactionUseCase(sl()));
  sl.registerLazySingleton(() => GetCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => AddCategoryUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCategoryUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCategoryUseCase(sl()));

  // ── Use cases — Recurring Rules ────────────────────────────────────────────
  sl.registerLazySingleton(() => GetRecurringRulesUseCase(sl()));
  sl.registerLazySingleton(() => AddRecurringRuleUseCase(sl()));
  sl.registerLazySingleton(() => UpdateRecurringRuleUseCase(sl()));
  sl.registerLazySingleton(() => StopRecurringRuleUseCase(sl()));
  sl.registerLazySingleton(() => ResumeRecurringRuleUseCase(sl()));

  // ── Cubits (factory: fresh instance per screen) ────────────────────────────
  sl.registerFactory(
    () => TransactionsCubit(sl(), sl(), sl(), sl(), sl()),
  );
  sl.registerFactory(
    () => CategoryCubit(sl(), sl(), sl(), sl()),
  );
  sl.registerFactory(
    () => RecurringCubit(sl(), sl(), sl(), sl(), sl(), sl()),
  );
}
