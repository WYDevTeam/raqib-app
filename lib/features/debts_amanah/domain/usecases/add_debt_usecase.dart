import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../data/models/debt_model.dart';
import '../repositories/debts_repository.dart';

class AddDebtUseCase {
  final DebtsRepository _repository;
  const AddDebtUseCase(this._repository);

  Future<Either<AppFailure, void>> call(DebtModel debt) => _repository.addDebt(debt);
}
