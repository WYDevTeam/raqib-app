import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../data/models/amanah_model.dart';
import '../repositories/debts_repository.dart';

class GetAmanahUseCase {
  final DebtsRepository _repository;
  const GetAmanahUseCase(this._repository);

  Future<Either<AppFailure, List<AmanahModel>>> call() => _repository.getAmanah();
}
