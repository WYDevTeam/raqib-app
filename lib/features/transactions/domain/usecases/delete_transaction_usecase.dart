import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../repositories/transaction_repository.dart';

class DeleteTransactionUseCase {
  final TransactionRepository _repository;
  const DeleteTransactionUseCase(this._repository);

  Future<Either<AppFailure, void>> call(String id) {
    return _repository.deleteTransaction(id);
  }
}
