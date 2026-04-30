import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../repositories/debts_repository.dart';

class SettleDebtUseCase {
  final DebtsRepository _repository;
  const SettleDebtUseCase(this._repository);

  Future<Either<AppFailure, void>> call(String debtId) => _repository.settleDebt(debtId);
}
