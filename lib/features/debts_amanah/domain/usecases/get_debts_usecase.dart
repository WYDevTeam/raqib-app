import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../data/models/debt_model.dart';
import '../repositories/debts_repository.dart';

class GetDebtsUseCase {
  final DebtsRepository _repository;
  const GetDebtsUseCase(this._repository);

  Future<Either<AppFailure, List<DebtModel>>> call() => _repository.getDebts();
}
