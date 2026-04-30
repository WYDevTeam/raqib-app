import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../repositories/debts_repository.dart';

class RecordDebtPaymentUseCase {
  final DebtsRepository _repository;
  const RecordDebtPaymentUseCase(this._repository);

  Future<Either<AppFailure, void>> call(String debtId, double amount) =>
      _repository.recordDebtPayment(debtId, amount);
}
