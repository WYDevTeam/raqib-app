import '../repositories/investments_repository.dart';

class DeleteAssetUseCase {
  final InvestmentsRepository _repo;
  const DeleteAssetUseCase(this._repo);

  Future<void> call(String id) => _repo.deleteAsset(id);
}
