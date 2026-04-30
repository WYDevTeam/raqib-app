import '../repositories/investments_repository.dart';

class UpdateAssetPriceUseCase {
  final InvestmentsRepository _repo;
  UpdateAssetPriceUseCase(this._repo);

  Future<void> call(String assetId, double price) =>
      _repo.updateAssetPrice(assetId, price);
}
