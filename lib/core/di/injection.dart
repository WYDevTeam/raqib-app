import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

import '../../features/transactions/data/datasources/category_hive_datasource.dart';
import '../../features/transactions/data/datasources/transaction_hive_datasource.dart';
import '../../features/transactions/data/models/category_model.dart';
import '../../features/transactions/data/models/transaction_model.dart';
import '../../features/transactions/data/repositories/transaction_repository_impl.dart';
import '../../features/transactions/domain/repositories/transaction_repository.dart';
import '../../features/transactions/domain/usecases/add_category_usecase.dart';
import '../../features/transactions/domain/usecases/add_transaction_usecase.dart';
import '../../features/transactions/domain/usecases/delete_category_usecase.dart';
import '../../features/transactions/domain/usecases/delete_transaction_usecase.dart';
import '../../features/transactions/domain/usecases/get_categories_usecase.dart';
import '../../features/transactions/domain/usecases/get_transactions_usecase.dart';
import '../../features/transactions/domain/usecases/update_category_usecase.dart';
import '../../features/transactions/domain/usecases/update_transaction_usecase.dart';
import '../../features/transactions/presentation/cubit/category_cubit.dart';
import '../../features/transactions/presentation/cubit/transactions_cubit.dart';

final GetIt sl = GetIt.instance;

Future<void> setupDI() async {
  // ── Hive boxes ─────────────────────────────────────────────────────────────
  final transactionBox = Hive.box<TransactionModel>('transactions');
  final categoryBox = Hive.box<CategoryModel>('categories');

  // ── Datasources ────────────────────────────────────────────────────────────
  sl.registerLazySingleton<TransactionHiveDatasource>(
    () => TransactionHiveDatasource(transactionBox),
  );
  sl.registerLazySingleton<CategoryHiveDatasource>(
    () => CategoryHiveDatasource(categoryBox),
  );

  // ── Repository ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(sl(), sl()),
  );

  // ── Use cases ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => GetTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => AddTransactionUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTransactionUseCase(sl()));
  sl.registerLazySingleton(() => DeleteTransactionUseCase(sl()));
  sl.registerLazySingleton(() => GetCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => AddCategoryUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCategoryUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCategoryUseCase(sl()));

  // ── Cubits (factory: fresh instance per screen) ────────────────────────────
  sl.registerFactory(
    () => TransactionsCubit(sl(), sl(), sl(), sl(), sl()),
  );
  sl.registerFactory(
    () => CategoryCubit(sl(), sl(), sl(), sl()),
  );
}
