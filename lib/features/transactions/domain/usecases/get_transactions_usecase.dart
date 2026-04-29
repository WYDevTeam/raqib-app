import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/transaction_entity.dart';
import '../entities/transaction_filter.dart';
import '../repositories/transaction_repository.dart';

class GetTransactionsUseCase {
  final TransactionRepository _repository;
  const GetTransactionsUseCase(this._repository);

  Future<Either<AppFailure, List<TransactionEntity>>> call(
      TransactionFilter? filter) {
    return _repository.getTransactions(filter: filter);
  }
}
