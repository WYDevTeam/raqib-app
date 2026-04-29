import '../entities/asset_entity.dart';
import '../repositories/investments_repository.dart';

class AddAssetUseCase {
  final InvestmentsRepository _repo;
  const AddAssetUseCase(this._repo);

  Future<void> call(AssetEntity asset) => _repo.addAsset(asset);
}
