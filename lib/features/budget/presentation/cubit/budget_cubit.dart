import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/budget_entity.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/usecases/get_budget_summary_usecase.dart';
import '../../domain/usecases/set_budget_usecase.dart';
import 'budget_state.dart';

class BudgetCubit extends Cubit<BudgetState> {
  final GetBudgetSummaryUseCase _getBudgetSummaryUseCase;
  final SetBudgetUseCase _setBudgetUseCase;
  final BudgetRepository _repository; // For getting available categories

  DateTime _currentMonth;

  BudgetCubit({
    required GetBudgetSummaryUseCase getBudgetSummaryUseCase,
    required SetBudgetUseCase setBudgetUseCase,
    required BudgetRepository repository,
  })  : _getBudgetSummaryUseCase = getBudgetSummaryUseCase,
        _setBudgetUseCase = setBudgetUseCase,
        _repository = repository,
        _currentMonth = DateTime.now(),
        super(BudgetInitial());

  void loadBudgets({DateTime? month}) {
    if (month != null) {
      _currentMonth = month;
    }

    emit(BudgetLoading());

    try {
      final summaries = _getBudgetSummaryUseCase(_currentMonth);
      final categories = _repository.getAvailableCategories();

      double totalAllocated = 0.0;
      double totalSpent = 0.0;

      for (final summary in summaries) {
        totalAllocated += summary.monthlyTarget;
        totalSpent += summary.spent;
      }

      emit(BudgetLoaded(
        currentMonth: _currentMonth,
        summaries: summaries,
        totalAllocated: totalAllocated,
        totalSpent: totalSpent,
        availableCategories: categories,
      ));
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }

  void changeMonth(int offset) {
    final newMonth = DateTime(_currentMonth.year, _currentMonth.month + offset, 1);
    loadBudgets(month: newMonth);
  }

  Future<void> addBudget({
    required String categoryId,
    required double monthlyTarget,
    required bool applyToAllUpcoming,
  }) async {
    try {
      final budget = BudgetEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        categoryId: categoryId,
        year: _currentMonth.year,
        month: _currentMonth.month,
        monthlyTarget: monthlyTarget,
        applyToAllUpcoming: applyToAllUpcoming,
      );

      await _setBudgetUseCase(budget);
      loadBudgets(); // Refresh current month view
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }
}
