import '../entities/transaction_entity.dart';

abstract final class RecurrenceUtils {
  /// Calculates the next occurrence date >= today based on start date and frequency.
  /// If start date is today or in the future, returns start date as-is.
  static DateTime nextOccurrence(
      DateTime startDate, RecurrenceFrequency frequency) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var next = DateTime(startDate.year, startDate.month, startDate.day);

    if (!next.isBefore(today)) return next;

    while (next.isBefore(today)) {
      next = _addPeriod(next, frequency);
    }
    return next;
  }

  /// Returns the next occurrence strictly AFTER [anchor].
  /// Used to show "next generation date" in the rules management screen.
  static DateTime nextOccurrenceAfter(
      DateTime anchor, RecurrenceFrequency frequency) {
    return _addPeriod(
      DateTime(anchor.year, anchor.month, anchor.day),
      frequency,
    );
  }

  /// Returns true if the recurring transaction has passed its end date.
  static bool isExpired(TransactionEntity t) {
    if (!t.isRecurring || t.endDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(t.endDate!.year, t.endDate!.month, t.endDate!.day);
    return end.isBefore(today);
  }

  static DateTime _addPeriod(DateTime d, RecurrenceFrequency f) {
    return switch (f) {
      RecurrenceFrequency.daily => d.add(const Duration(days: 1)),
      RecurrenceFrequency.weekly => d.add(const Duration(days: 7)),
      RecurrenceFrequency.monthly => _addMonth(d),
      RecurrenceFrequency.yearly => DateTime(d.year + 1, d.month, d.day),
    };
  }

  // Handles month-end edge cases: Jan 31 + 1 month = Feb 28/29, not Mar 2/3.
  static DateTime _addMonth(DateTime d) {
    var month = d.month + 1;
    var year = d.year;
    if (month > 12) {
      month = 1;
      year++;
    }
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, d.day.clamp(1, lastDayOfMonth));
  }

  static String formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final day = DateTime(d.year, d.month, d.day);

    if (day == today) return 'اليوم';
    if (day == tomorrow) return 'غداً';

    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
