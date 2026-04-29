enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
  yearly;

  String get arabicLabel => switch (this) {
        RecurrenceFrequency.daily => 'يومياً',
        RecurrenceFrequency.weekly => 'أسبوعياً',
        RecurrenceFrequency.monthly => 'شهرياً',
        RecurrenceFrequency.yearly => 'سنوياً',
      };

  String get hiveKey => name;

  static RecurrenceFrequency? fromString(String? s) => switch (s) {
        'daily' => RecurrenceFrequency.daily,
        'weekly' => RecurrenceFrequency.weekly,
        'monthly' => RecurrenceFrequency.monthly,
        'yearly' => RecurrenceFrequency.yearly,
        _ => null,
      };
}

class TransactionEntity {
  final String id;
  final double amount;
  final String categoryId;
  final String description;
  final DateTime date;
  final bool isIncome;
  final bool isRecurring;
  final RecurrenceFrequency? frequency;

  const TransactionEntity({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.description,
    required this.date,
    required this.isIncome,
    this.isRecurring = false,
    this.frequency,
  });

  TransactionEntity copyWith({
    String? id,
    double? amount,
    String? categoryId,
    String? description,
    DateTime? date,
    bool? isIncome,
    bool? isRecurring,
    RecurrenceFrequency? frequency,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      date: date ?? this.date,
      isIncome: isIncome ?? this.isIncome,
      isRecurring: isRecurring ?? this.isRecurring,
      frequency: frequency ?? this.frequency,
    );
  }
}
