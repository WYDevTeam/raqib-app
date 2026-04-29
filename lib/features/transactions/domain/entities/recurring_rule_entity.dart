import 'transaction_entity.dart';

/// A recurring rule that drives automatic transaction generation.
/// Stored separately from generated transactions so stopping a rule
/// never deletes already-generated transactions.
class RecurringRuleEntity {
  final String id;
  final double amount;
  final String categoryId;
  final String description;
  final bool isIncome;
  final RecurrenceFrequency frequency;

  /// The date of the first occurrence (used as the day-anchor for monthly/yearly).
  final DateTime startDate;

  /// Null = never ends.
  final DateTime? endDate;

  /// The last date a transaction was generated from this rule.
  /// Null = no transaction generated yet (will generate from startDate).
  final DateTime? lastGeneratedDate;

  /// false = rule is paused; no more transactions will be generated.
  /// Already-generated transactions are NOT affected.
  final bool isActive;

  const RecurringRuleEntity({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.description,
    required this.isIncome,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.lastGeneratedDate,
    this.isActive = true,
  });

  RecurringRuleEntity copyWith({
    String? id,
    double? amount,
    String? categoryId,
    String? description,
    bool? isIncome,
    RecurrenceFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    DateTime? lastGeneratedDate,
    bool clearLastGenerated = false,
    bool? isActive,
  }) {
    return RecurringRuleEntity(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      isIncome: isIncome ?? this.isIncome,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      lastGeneratedDate: clearLastGenerated
          ? null
          : (lastGeneratedDate ?? this.lastGeneratedDate),
      isActive: isActive ?? this.isActive,
    );
  }
}
