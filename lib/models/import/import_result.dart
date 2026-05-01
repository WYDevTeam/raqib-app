import 'parsed_items.dart';

class ImportResult {
  final List<ParsedTransaction> transactions;
  final List<ParsedAssetTransaction> assetTransactions;
  final List<ParsedDebt> debts;
  final List<ParsedAmanah> amanahs;
  final List<UnclearRow> unclear;

  ImportResult({
    required this.transactions,
    required this.assetTransactions,
    required this.debts,
    required this.amanahs,
    required this.unclear,
  });

  factory ImportResult.empty() => ImportResult(
        transactions: [],
        assetTransactions: [],
        debts: [],
        amanahs: [],
        unclear: [],
      );

  /// دمج نتائج batch آخر مع هذه النتائج (in-place)
  void merge(ImportResult other) {
    transactions.addAll(other.transactions);
    assetTransactions.addAll(other.assetTransactions);
    debts.addAll(other.debts);
    amanahs.addAll(other.amanahs);
    unclear.addAll(other.unclear);
  }

  int get totalCount =>
      transactions.length +
      assetTransactions.length +
      debts.length +
      amanahs.length;

  factory ImportResult.fromJson(Map<String, dynamic> json) {
    return ImportResult(
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map((e) =>
                  ParsedTransaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      assetTransactions: (json['asset_transactions'] as List<dynamic>?)
              ?.map((e) => ParsedAssetTransaction.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
      debts: (json['debts'] as List<dynamic>?)
              ?.map((e) => ParsedDebt.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      amanahs: (json['amanahs'] as List<dynamic>?)
              ?.map((e) => ParsedAmanah.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      unclear: (json['unclear'] as List<dynamic>?)
              ?.map((e) => UnclearRow.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
