class TransactionFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? categoryIds;
  final bool? isIncome;

  const TransactionFilter({
    this.startDate,
    this.endDate,
    this.categoryIds,
    this.isIncome,
  });

  bool get isEmpty =>
      startDate == null &&
      endDate == null &&
      (categoryIds == null || categoryIds!.isEmpty) &&
      isIncome == null;

  TransactionFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categoryIds,
    bool? isIncome,
    bool clearIsIncome = false,
  }) {
    return TransactionFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      categoryIds: categoryIds ?? this.categoryIds,
      isIncome: clearIsIncome ? null : (isIncome ?? this.isIncome),
    );
  }
}
