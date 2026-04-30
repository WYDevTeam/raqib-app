import '../entities/asset_entity.dart';
import '../entities/asset_transaction_entity.dart';

abstract class InvestmentsRepository {
  List<AssetEntity> getAssets();
  List<AssetTransactionEntity> getTransactions(String assetId);
  Future<void> addAsset(AssetEntity asset);
  Future<void> deleteAsset(String id);
  Future<void> addTransaction(AssetTransactionEntity tx);
  Future<void> deleteTransaction(String txId);
  Future<void> updateAssetPrice(String assetId, double price);
}
