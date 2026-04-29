import '../../domain/entities/asset_entity.dart';
import '../../domain/entities/asset_transaction_entity.dart';

sealed class InvestmentsState {
  const InvestmentsState();
}

final class InvestmentsInitial extends InvestmentsState {
  const InvestmentsInitial();
}

final class InvestmentsLoading extends InvestmentsState {
  const InvestmentsLoading();
}

final class InvestmentsLoaded extends InvestmentsState {
  final List<AssetEntity> assets;
  final Map<String, List<AssetTransactionEntity>> transactionsByAsset;

  const InvestmentsLoaded({
    required this.assets,
    required this.transactionsByAsset,
  });

  double get totalCurrentValue =>
      assets.fold(0, (s, a) => s + a.currentTotalValue);
  double get totalCost => assets.fold(0, (s, a) => s + a.totalCost);
  double get totalUnrealizedPnL =>
      assets.fold(0, (s, a) => s + a.unrealizedPnL);
  double get totalRealizedPnL =>
      assets.fold(0, (s, a) => s + a.realizedPnL);

  List<AssetTransactionEntity> get allTransactions =>
      transactionsByAsset.values.expand((txs) => txs).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
}

final class InvestmentsError extends InvestmentsState {
  final String message;
  const InvestmentsError(this.message);
}
