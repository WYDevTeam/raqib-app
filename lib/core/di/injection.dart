import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

import '../../features/budget/data/repositories/budget_repository_impl.dart';
import '../../features/budget/domain/repositories/budget_repository.dart';
import '../../features/budget/domain/usecases/get_budget_summary_usecase.dart';
import '../../features/budget/domain/usecases/set_budget_usecase.dart';
import '../../features/budget/presentation/cubit/budget_cubit.dart';

import '../../features/dashboard/data/models/dashboard_widget_model.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/domain/usecases/get_dashboard_summary_usecase.dart';
import '../../features/dashboard/domain/usecases/get_dashboard_widgets_usecase.dart';
import '../../features/dashboard/domain/usecases/update_dashboard_widgets_usecase.dart';
import '../../features/dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../features/debts_amanah/data/models/amanah_model.dart';
import '../../features/debts_amanah/data/models/debt_model.dart';
import '../../features/debts_amanah/data/repositories/debts_repository_impl.dart';
import '../../features/debts_amanah/domain/repositories/debts_repository.dart';
import '../../features/debts_amanah/domain/usecases/add_amanah_usecase.dart';
import '../../features/debts_amanah/domain/usecases/add_debt_usecase.dart';
import '../../features/debts_amanah/domain/usecases/get_amanah_usecase.dart';
import '../../features/debts_amanah/domain/usecases/get_debts_usecase.dart';
import '../../features/debts_amanah/domain/usecases/record_amanah_return_usecase.dart';
import '../../features/debts_amanah/domain/usecases/record_debt_payment_usecase.dart';
import '../../features/debts_amanah/domain/usecases/settle_amanah_usecase.dart';
import '../../features/debts_amanah/domain/usecases/settle_debt_usecase.dart';
import '../../features/debts_amanah/presentation/cubit/debts_cubit.dart';
import '../../features/investments/data/models/asset_model.dart';
import '../../features/investments/data/models/asset_transaction_model.dart';
import '../../features/onboarding/presentation/cubit/onboarding_cubit.dart';
import '../../features/settings/data/models/app_settings_model.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/complete_onboarding_usecase.dart';
import '../../features/settings/domain/usecases/is_onboarding_completed_usecase.dart';
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
import '../../features/transactions/domain/usecases/process_recurring_transactions_usecase.dart';
import '../../features/transactions/domain/usecases/stop_recurring_rule_usecase.dart';
import '../../features/transactions/domain/usecases/update_category_usecase.dart';
import '../../features/transactions/domain/usecases/update_recurring_rule_usecase.dart';
import '../../features/transactions/domain/usecases/update_transaction_usecase.dart';
import '../../features/transactions/presentation/cubit/category_cubit.dart';
import '../../features/transactions/presentation/cubit/recurring_cubit.dart';
import '../../features/transactions/presentation/cubit/transactions_cubit.dart';
import '../services/api_service.dart';
import '../services/calculations_service.dart';
import '../services/formula_service.dart';
import '../../features/dashboard/domain/usecases/delete_custom_widget_usecase.dart';
import '../../features/dashboard/domain/usecases/save_custom_widget_usecase.dart';
import '../../features/investments/data/repositories/investments_repository_impl.dart';
import '../../features/investments/domain/repositories/investments_repository.dart';
import '../../features/investments/domain/usecases/add_asset_transaction_usecase.dart';
import '../../features/investments/domain/usecases/add_asset_usecase.dart';
import '../../features/investments/domain/usecases/delete_asset_transaction_usecase.dart';
import '../../features/investments/domain/usecases/delete_asset_usecase.dart';
import '../../features/investments/domain/usecases/get_asset_transactions_usecase.dart';
import '../../features/investments/domain/usecases/get_assets_usecase.dart';
import '../../features/investments/domain/usecases/update_asset_price_usecase.dart';
import '../../features/investments/presentation/cubit/investments_cubit.dart';

final GetIt sl = GetIt.instance;

Future<void> setupDI() async {
  // ── Hive boxes ─────────────────────────────────────────────────────────────
  final transactionBox = Hive.box<TransactionModel>('transactions');
  final categoryBox = Hive.box<CategoryModel>('categories');
  final recurringRuleBox = Hive.box<RecurringRuleModel>('recurring_rules');
  final amanahBox = Hive.box<AmanahModel>('amanah');
  final debtBox = Hive.box<DebtModel>('debts');
  final assetBox = Hive.box<AssetModel>('assets');
  final assetTxBox = Hive.box<AssetTransactionModel>('asset_transactions');
  final settingsBox = Hive.box<AppSettingsModel>('settings');
  final widgetsBox = Hive.box<DashboardWidgetModel>('dashboard_widgets');

  // ── Core services ──────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => ApiService());
  sl.registerLazySingleton(
    () => CalculationsService(
      txBox: transactionBox,
      amanahBox: amanahBox,
      debtBox: debtBox,
      assetBox: assetBox,
      settingsBox: settingsBox,
    ),
  );
  sl.registerLazySingleton(() => FormulaService(sl()));

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
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(
      calc: sl(),
      widgetsBox: widgetsBox,
      apiService: sl(),
      formulaService: sl(),
    ),
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
  sl.registerLazySingleton(
    () => ProcessRecurringTransactionsUseCase(
      getRules: sl(),
      addTransaction: sl(),
      updateRule: sl(),
    ),
  );

  // ── Investments ────────────────────────────────────────────────────────────
  sl.registerLazySingleton<InvestmentsRepository>(
    () => InvestmentsRepositoryImpl(assetBox: assetBox, txBox: assetTxBox),
  );
  sl.registerLazySingleton(() => GetAssetsUseCase(sl()));
  sl.registerLazySingleton(() => AddAssetUseCase(sl()));
  sl.registerLazySingleton(() => DeleteAssetUseCase(sl()));
  sl.registerLazySingleton(() => GetAssetTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => AddAssetTransactionUseCase(sl()));
  sl.registerLazySingleton(() => DeleteAssetTransactionUseCase(sl()));
  sl.registerLazySingleton(() => UpdateAssetPriceUseCase(sl()));

  // ── Use cases — Dashboard ──────────────────────────────────────────────────
  sl.registerLazySingleton(() => GetDashboardSummaryUseCase(sl()));
  sl.registerLazySingleton(() => GetDashboardWidgetsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateDashboardWidgetsUseCase(sl()));
  sl.registerLazySingleton(() => SaveCustomWidgetUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCustomWidgetUseCase(sl()));

  // ── Settings ───────────────────────────────────────────────────────────────
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(settingsBox),
  );
  sl.registerLazySingleton(() => CompleteOnboardingUseCase(sl()));
  sl.registerLazySingleton(() => IsOnboardingCompletedUseCase(sl()));

  // ── Budget ─────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<BudgetRepository>(() => BudgetRepositoryImpl());
  sl.registerLazySingleton(() => GetBudgetSummaryUseCase(sl()));
  sl.registerLazySingleton(() => SetBudgetUseCase(sl()));
  sl.registerFactory(
    () => BudgetCubit(
      getBudgetSummaryUseCase: sl(),
      setBudgetUseCase: sl(),
      repository: sl(),
    ),
  );

  // ── Debts & Amanah ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<DebtsRepository>(
    () => DebtsRepositoryImpl(debtBox: debtBox, amanahBox: amanahBox),
  );
  sl.registerLazySingleton(() => GetDebtsUseCase(sl()));
  sl.registerLazySingleton(() => AddDebtUseCase(sl()));
  sl.registerLazySingleton(() => RecordDebtPaymentUseCase(sl()));
  sl.registerLazySingleton(() => SettleDebtUseCase(sl()));
  sl.registerLazySingleton(() => GetAmanahUseCase(sl()));
  sl.registerLazySingleton(() => AddAmanahUseCase(sl()));
  sl.registerLazySingleton(() => RecordAmanahReturnUseCase(sl()));
  sl.registerLazySingleton(() => SettleAmanahUseCase(sl()));

  // ── Cubits (factory: fresh instance per screen) ────────────────────────────
  sl.registerFactory(() => TransactionsCubit(sl(), sl(), sl(), sl(), sl()));
  sl.registerFactory(() => CategoryCubit(sl(), sl(), sl(), sl()));
  sl.registerFactory(() => RecurringCubit(sl(), sl(), sl(), sl(), sl(), sl()));
  sl.registerLazySingleton(() => DashboardCubit(sl(), sl(), sl(), sl(), sl()));
  sl.registerFactory(
    () => InvestmentsCubit(sl(), sl(), sl(), sl(), sl(), sl(), sl()),
  );
  sl.registerFactory(
    () => DebtsCubit(sl(), sl(), sl(), sl(), sl(), sl(), sl(), sl()),
  );
  sl.registerFactory(
    () => OnboardingCubit(
      completeOnboarding: sl(),
      addTransaction: sl(),
      assetBox: assetBox,
      assetTxBox: assetTxBox,
      amanahBox: amanahBox,
      debtBox: debtBox,
    ),
  );
}
