import '../entities/asset_transaction_entity.dart';
import '../repositories/investments_repository.dart';

class AddAssetTransactionUseCase {
  final InvestmentsRepository _repo;
  const AddAssetTransactionUseCase(this._repo);

  Future<void> call(AssetTransactionEntity tx) => _repo.addTransaction(tx);
}
