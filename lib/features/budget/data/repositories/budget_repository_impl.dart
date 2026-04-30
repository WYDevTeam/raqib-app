import 'package:collection/collection.dart';
import 'package:hive/hive.dart';

import '../../../../features/transactions/data/models/category_model.dart';
import '../../../../features/transactions/data/models/transaction_model.dart';
import '../../../../features/transactions/domain/entities/category_entity.dart';
import '../../domain/entities/budget_entity.dart';
import '../../domain/repositories/budget_repository.dart';
import '../models/budget_model.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final Box<BudgetModel> _budgetBox = Hive.box<BudgetModel>('budgets');
  final Box<TransactionModel> _txBox = Hive.box<TransactionModel>('transactions');
  final Box<CategoryModel> _categoryBox = Hive.box<CategoryModel>('categories');

  @override
  Future<void> setBudget(BudgetEntity budget) async {
    // Check if there is already a budget for this category and month
    final existing = _budgetBox.values.firstWhereOrNull(
      (b) => b.categoryId == budget.categoryId &&
             b.year == budget.year &&
             b.month == budget.month,
    );

    if (existing != null) {
      final updated = BudgetModel.fromEntity(budget);
      // Keep original created time
      final merged = BudgetModel(
        id: existing.id,
        categoryId: updated.categoryId,
        year: updated.year,
        month: updated.month,
        monthlyTarget: updated.monthlyTarget,
        applyToAllUpcoming: updated.applyToAllUpcoming,
        createdAtMs: existing.createdAtMs,
        isActive: existing.isActive,
      );
      await _budgetBox.put(existing.id, merged);
    } else {
      final model = BudgetModel.fromEntity(budget);
      await _budgetBox.put(model.id, model);
    }
  }

  @override
  List<BudgetSummary> getMonthSummary(DateTime targetMonth) {
    final start = DateTime(targetMonth.year, targetMonth.month, 1);
    final end = DateTime(targetMonth.year, targetMonth.month + 1, 0, 23, 59, 59);

    // 1. Find applicable budgets for this month
    // A budget applies if it matches the exact month/year, 
    // OR if applyToAllUpcoming is true and it was created in a prior month
    
    // Group by category to find the most relevant budget
    final Map<String, BudgetModel> applicableBudgets = {};

    for (final b in _budgetBox.values) {
      if (!b.isActive) continue;

      final isExactMonth = b.year == targetMonth.year && b.month == targetMonth.month;
      final budgetDate = DateTime(b.year, b.month, 1);
      final isPastWithUpcoming = b.applyToAllUpcoming && budgetDate.isBefore(start);

      if (isExactMonth || isPastWithUpcoming) {
        final existing = applicableBudgets[b.categoryId];
        if (existing == null) {
          applicableBudgets[b.categoryId] = b;
        } else {
          // If we already have an exact match, don't overwrite it
          final existingIsExact = existing.year == targetMonth.year && existing.month == targetMonth.month;
          if (!existingIsExact) {
            // Overwrite if the new one is an exact match, OR if the new one is more recent than the existing past one
            if (isExactMonth) {
              applicableBudgets[b.categoryId] = b;
            } else {
              final existingDate = DateTime(existing.year, existing.month, 1);
              if (budgetDate.isAfter(existingDate)) {
                applicableBudgets[b.categoryId] = b;
              }
            }
          }
        }
      }
    }

    // 2. Map budgets to summaries
    return applicableBudgets.values.map((b) {
      // Find category
      final categoryModel = _categoryBox.get(b.categoryId);
      // Fallback category if deleted
      final categoryEntity = categoryModel != null 
          ? CategoryEntity(
              id: categoryModel.id,
              name: categoryModel.name,
              iconCodePoint: categoryModel.iconCodePoint,
              colorValue: categoryModel.colorValue,
              type: CategoryType.fromInt(categoryModel.typeValue),
            )
          : CategoryEntity(
              id: b.categoryId,
              name: 'محذوف',
              iconCodePoint: 0xe000, // placeholder
              colorValue: 0xFF9E9E9E,
              type: CategoryType.expense,
            );

      // Calculate spent for this month and category
      final spent = _txBox.values
          .where((t) => t.categoryId == b.categoryId &&
                        !t.isIncome && // Only expenses count towards budget
                        t.date.isAfter(start.subtract(const Duration(seconds: 1))) && 
                        t.date.isBefore(end.add(const Duration(seconds: 1))))
          .fold(0.0, (sum, t) => sum + t.amount);

      return BudgetSummary(
        budget: b.toEntity(),
        category: categoryEntity,
        spent: spent,
      );
    }).toList();
  }

  @override
  List<CategoryEntity> getAvailableCategories() {
    return _categoryBox.values
        .where((c) => c.typeValue == 1 || c.typeValue == 2) // expense or both
        .map((c) => CategoryEntity(
              id: c.id,
              name: c.name,
              iconCodePoint: c.iconCodePoint,
              colorValue: c.colorValue,
              type: CategoryType.fromInt(c.typeValue),
            ))
        .toList();
  }
}
