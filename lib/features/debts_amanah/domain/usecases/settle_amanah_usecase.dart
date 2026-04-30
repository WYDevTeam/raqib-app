import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../repositories/debts_repository.dart';

class SettleAmanahUseCase {
  final DebtsRepository _repository;
  const SettleAmanahUseCase(this._repository);

  Future<Either<AppFailure, void>> call(String amanahId) => _repository.settleAmanah(amanahId);
}
