import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../data/models/amanah_model.dart';
import '../repositories/debts_repository.dart';

class AddAmanahUseCase {
  final DebtsRepository _repository;
  const AddAmanahUseCase(this._repository);

  Future<Either<AppFailure, void>> call(AmanahModel amanah) => _repository.addAmanah(amanah);
}
