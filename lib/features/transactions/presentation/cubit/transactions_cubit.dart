import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_filter.dart';
import '../../domain/usecases/add_transaction_usecase.dart';
import '../../domain/usecases/delete_transaction_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/get_transactions_usecase.dart';
import '../../domain/usecases/update_transaction_usecase.dart';
import 'transactions_state.dart';

class TransactionsCubit extends Cubit<TransactionsState> {
  final GetTransactionsUseCase _getTransactions;
  final AddTransactionUseCase _addTransaction;
  final UpdateTransactionUseCase _updateTransaction;
  final DeleteTransactionUseCase _deleteTransaction;
  final GetCategoriesUseCase _getCategories;

  TransactionFilter? _activeFilter;

  TransactionsCubit(
    this._getTransactions,
    this._addTransaction,
    this._updateTransaction,
    this._deleteTransaction,
    this._getCategories,
  ) : super(const TransactionsInitial());

  Future<void> loadTransactions({TransactionFilter? filter}) async {
    _activeFilter = filter;
    emit(const TransactionsLoading());

    final transResult = await _getTransactions(_activeFilter);
    final catResult = await _getCategories();

    transResult.fold(
      (failure) => emit(TransactionsError(failure.message)),
      (transactions) => catResult.fold(
        (failure) => emit(TransactionsError(failure.message)),
        (categories) => emit(TransactionsLoaded(
          transactions: transactions,
          categories: categories,
          activeFilter: _activeFilter,
        )),
      ),
    );
  }

  Future<void> addTransaction(TransactionEntity transaction) async {
    final result = await _addTransaction(transaction);
    result.fold(
      (failure) => emit(TransactionsError(failure.message)),
      (_) => loadTransactions(filter: _activeFilter),
    );
  }

  Future<void> updateTransaction(TransactionEntity transaction) async {
    final result = await _updateTransaction(transaction);
    result.fold(
      (failure) => emit(TransactionsError(failure.message)),
      (_) => loadTransactions(filter: _activeFilter),
    );
  }

  Future<void> deleteTransaction(String id) async {
    final result = await _deleteTransaction(id);
    result.fold(
      (failure) => emit(TransactionsError(failure.message)),
      (_) => loadTransactions(filter: _activeFilter),
    );
  }
}
