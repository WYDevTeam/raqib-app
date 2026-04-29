class AssetEntity {
  final String id;
  final String name;
  final String type; // 'gold', 'silver', 'crypto', 'other'
  final String symbol;
  final double quantity;
  final String unit;
  final double totalCost;
  final double currentValuePerUnit;
  final double realizedPnL;
  final int? lastPriceUpdateMs;
  final int createdAtMs;
  final String note;

  const AssetEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.symbol,
    required this.quantity,
    required this.unit,
    required this.totalCost,
    required this.currentValuePerUnit,
    required this.realizedPnL,
    this.lastPriceUpdateMs,
    required this.createdAtMs,
    this.note = '',
  });

  double get avgCostPerUnit => quantity > 0 ? totalCost / quantity : 0;
  double get currentTotalValue => quantity * currentValuePerUnit;
  double get unrealizedPnL => currentTotalValue - totalCost;
  double get totalPnL => realizedPnL + unrealizedPnL;
  double get unrealizedPnLPercent =>
      totalCost > 0 ? unrealizedPnL / totalCost * 100 : 0;
}
