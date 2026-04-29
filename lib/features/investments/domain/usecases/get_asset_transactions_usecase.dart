import '../entities/asset_transaction_entity.dart';
import '../repositories/investments_repository.dart';

class GetAssetTransactionsUseCase {
  final InvestmentsRepository _repo;
  const GetAssetTransactionsUseCase(this._repo);

  List<AssetTransactionEntity> call(String assetId) =>
      _repo.getTransactions(assetId);
}
