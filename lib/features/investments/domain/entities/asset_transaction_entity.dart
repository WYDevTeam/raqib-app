class AssetTransactionEntity {
  final String id;
  final String assetId;
  final bool isBuy;
  final double quantity;
  final double pricePerUnit;
  final DateTime date;
  final String note;

  const AssetTransactionEntity({
    required this.id,
    required this.assetId,
    required this.isBuy,
    required this.quantity,
    required this.pricePerUnit,
    required this.date,
    this.note = '',
  });

  double get totalAmount => quantity * pricePerUnit;
}
