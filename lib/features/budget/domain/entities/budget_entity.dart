import '../../../../features/transactions/domain/entities/category_entity.dart';

class BudgetEntity {
  final String id;
  final String categoryId;
  final int year;
  final int month;
  final double monthlyTarget;
  final bool applyToAllUpcoming;

  const BudgetEntity({
    required this.id,
    required this.categoryId,
    required this.year,
    required this.month,
    required this.monthlyTarget,
    required this.applyToAllUpcoming,
  });
}

class BudgetSummary {
  final BudgetEntity budget;
  final CategoryEntity category;
  final double spent;

  const BudgetSummary({
    required this.budget,
    required this.category,
    required this.spent,
  });

  double get progress => monthlyTarget > 0 ? (spent / monthlyTarget) : 0;
  bool get isOverBudget => spent > monthlyTarget;
  double get remaining => monthlyTarget - spent;
  double get monthlyTarget => budget.monthlyTarget;
}
