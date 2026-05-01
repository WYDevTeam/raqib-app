import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../data/models/debt_model.dart';
import '../repositories/debts_repository.dart';

class UpdateDebtUseCase {
  final DebtsRepository _repository;
  const UpdateDebtUseCase(this._repository);

  Future<Either<AppFailure, void>> call(DebtModel debt) => _repository.updateDebt(debt);
}
