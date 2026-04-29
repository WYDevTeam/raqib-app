import '../entities/asset_entity.dart';
import '../repositories/investments_repository.dart';

class GetAssetsUseCase {
  final InvestmentsRepository _repo;
  const GetAssetsUseCase(this._repo);

  List<AssetEntity> call() => _repo.getAssets();
}
