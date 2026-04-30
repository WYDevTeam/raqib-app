import 'package:equatable/equatable.dart';

import '../../../../features/transactions/domain/entities/category_entity.dart';
import '../../domain/entities/budget_entity.dart';

abstract class BudgetState extends Equatable {
  const BudgetState();

  @override
  List<Object?> get props => [];
}

class BudgetInitial extends BudgetState {}

class BudgetLoading extends BudgetState {}

class BudgetLoaded extends BudgetState {
  final DateTime currentMonth;
  final List<BudgetSummary> summaries;
  final double totalAllocated;
  final double totalSpent;
  final List<CategoryEntity> availableCategories;

  const BudgetLoaded({
    required this.currentMonth,
    required this.summaries,
    required this.totalAllocated,
    required this.totalSpent,
    required this.availableCategories,
  });

  @override
  List<Object?> get props => [currentMonth, summaries, totalAllocated, totalSpent, availableCategories];
}

class BudgetError extends BudgetState {
  final String message;

  const BudgetError(this.message);

  @override
  List<Object?> get props => [message];
}
