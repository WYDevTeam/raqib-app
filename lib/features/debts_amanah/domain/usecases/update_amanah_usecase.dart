import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../data/models/amanah_model.dart';
import '../repositories/debts_repository.dart';

class UpdateAmanahUseCase {
  final DebtsRepository _repository;
  const UpdateAmanahUseCase(this._repository);

  Future<Either<AppFailure, void>> call(AmanahModel amanah) => _repository.updateAmanah(amanah);
}
