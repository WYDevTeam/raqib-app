import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class UpdateTransactionUseCase {
  final TransactionRepository _repository;
  const UpdateTransactionUseCase(this._repository);

  Future<Either<AppFailure, void>> call(TransactionEntity transaction) {
    return _repository.updateTransaction(transaction);
  }
}
