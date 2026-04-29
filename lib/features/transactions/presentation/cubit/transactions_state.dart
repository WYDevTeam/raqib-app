import '../../domain/entities/category_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_filter.dart';

sealed class TransactionsState {
  const TransactionsState();
}

final class TransactionsInitial extends TransactionsState {
  const TransactionsInitial();
}

final class TransactionsLoading extends TransactionsState {
  const TransactionsLoading();
}

final class TransactionsLoaded extends TransactionsState {
  final List<TransactionEntity> transactions;
  final List<CategoryEntity> categories;
  final TransactionFilter? activeFilter;

  const TransactionsLoaded({
    required this.transactions,
    required this.categories,
    this.activeFilter,
  });

  double get totalIncome => transactions
      .where((t) => t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => transactions
      .where((t) => !t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);
}

final class TransactionsError extends TransactionsState {
  final String message;
  const TransactionsError(this.message);
}
