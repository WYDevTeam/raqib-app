import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../repositories/debts_repository.dart';

class RecordAmanahReturnUseCase {
  final DebtsRepository _repository;
  const RecordAmanahReturnUseCase(this._repository);

  Future<Either<AppFailure, void>> call(String amanahId, double amount) =>
      _repository.recordAmanahReturn(amanahId, amount);
}
