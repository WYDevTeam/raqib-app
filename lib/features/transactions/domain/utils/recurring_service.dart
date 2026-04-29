import 'package:uuid/uuid.dart';

import '../entities/recurring_rule_entity.dart';
import '../entities/transaction_entity.dart';

/// Core service that generates due transactions from a RecurringRuleEntity.
///
/// Strategy:
///   lastGenerated = rule.lastGeneratedDate ?? (startDate - 1 period)
///   Walk forward by one period at a time until we reach today.
///   For each occurrence date D where startDate <= D <= today (and D <= endDate):
///     → generate a TransactionEntity with date=D.
///
/// The caller is responsible for persisting the generated transactions
/// and updating rule.lastGeneratedDate to today (or last occurrence).
abstract final class RecurringService {
  /// Returns all transactions that should be generated for [rule]
  /// up to and including [today].
  ///
  /// Returns an empty list if:
  ///   - rule.isActive == false
  ///   - rule has expired (endDate < today)
  ///   - no new occurrences since lastGeneratedDate
  static List<TransactionEntity> generateDue(
    RecurringRuleEntity rule, {
    DateTime? overrideToday,
    int maxOccurrences = 500,
  }) {
    if (!rule.isActive) return [];

    final now = overrideToday ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = _dateOnly(rule.startDate);

    // If start is in the future, nothing is due yet.
    if (start.isAfter(today)) return [];

    // If rule has expired, no new transactions.
    if (rule.endDate != null) {
      final end = _dateOnly(rule.endDate!);
      if (end.isBefore(today) && end.isBefore(start)) return [];
    }

    // Determine where to start generating from.
    // If we've never generated, start from the startDate itself.
    // Otherwise, start one period after the last generated date.
    DateTime cursor;
    if (rule.lastGeneratedDate == null) {
      cursor = start;
    } else {
      cursor = _addPeriod(_dateOnly(rule.lastGeneratedDate!), rule.frequency);
    }

    final generated = <TransactionEntity>[];

    while (!cursor.isAfter(today) && generated.length < maxOccurrences) {
      // Stop if past endDate.
      if (rule.endDate != null && cursor.isAfter(_dateOnly(rule.endDate!))) {
        break;
      }

      // Only generate from startDate onwards.
      if (!cursor.isBefore(start)) {
        generated.add(TransactionEntity(
          id: const Uuid().v4(),
          amount: rule.amount,
          categoryId: rule.categoryId,
          description: rule.description,
          date: cursor,
          isIncome: rule.isIncome,
          isRecurring: false,
          ruleId: rule.id,
        ));
      }

      cursor = _addPeriod(cursor, rule.frequency);
    }

    return generated;
  }

  // ── Period math ────────────────────────────────────────────────────────────

  static DateTime _addPeriod(DateTime d, RecurrenceFrequency f) {
    return switch (f) {
      RecurrenceFrequency.daily => d.add(const Duration(days: 1)),
      RecurrenceFrequency.weekly => d.add(const Duration(days: 7)),
      RecurrenceFrequency.monthly => _addMonth(d),
      RecurrenceFrequency.yearly => DateTime(d.year + 1, d.month, d.day),
    };
  }

  /// Adds one month with clamping to prevent month overflow.
  /// e.g. Jan 31 + 1 month = Feb 28 (not Mar 3).
  static DateTime _addMonth(DateTime d) {
    var month = d.month + 1;
    var year = d.year;
    if (month > 12) {
      month = 1;
      year++;
    }
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, d.day.clamp(1, lastDay));
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
