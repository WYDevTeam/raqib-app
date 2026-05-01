import 'ambiguous_item.dart';

class FileAnalysis {
  final List<String> headers;

  /// رقم الصف الأول من البيانات (بعد الـ header)، 0-indexed
  final int dataStartRow;

  /// خريطة العمود المكتشف: 'date', 'amount', 'type', 'description', 'category' → index أو null
  final Map<String, int?> detectedColumns;

  /// 'signed' | 'type_column' | 'two_columns'
  final String amountBehavior;

  final String? typeColumnIncomeValue;
  final String? typeColumnExpenseValue;
  final int? incomeColumnIndex;
  final int? expenseColumnIndex;

  /// جميع الكاتيغوريز الفريدة المكتشفة
  final List<String> uniqueCategories;

  /// الأسئلة الغامضة التي يجب على المستخدم الإجابة عليها
  final List<AmbiguousItem> ambiguousItems;

  final String notes;

  const FileAnalysis({
    required this.headers,
    required this.dataStartRow,
    required this.detectedColumns,
    required this.amountBehavior,
    this.typeColumnIncomeValue,
    this.typeColumnExpenseValue,
    this.incomeColumnIndex,
    this.expenseColumnIndex,
    required this.uniqueCategories,
    required this.ambiguousItems,
    required this.notes,
  });

  factory FileAnalysis.fromJson(Map<String, dynamic> json) {
    final cols = json['detected_columns'] as Map<String, dynamic>? ?? {};
    return FileAnalysis(
      headers: (json['headers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      dataStartRow: json['data_start_row'] as int? ?? 1,
      detectedColumns: {
        'date': cols['date'] as int?,
        'amount': cols['amount'] as int?,
        'type': cols['type'] as int?,
        'description': cols['description'] as int?,
        'category': cols['category'] as int?,
      },
      amountBehavior: json['amount_behavior'] as String? ?? 'signed',
      typeColumnIncomeValue: json['type_column_income_value'] as String?,
      typeColumnExpenseValue: json['type_column_expense_value'] as String?,
      incomeColumnIndex: json['income_column_index'] as int?,
      expenseColumnIndex: json['expense_column_index'] as int?,
      uniqueCategories: (json['unique_categories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      ambiguousItems: (json['ambiguous_items'] as List<dynamic>?)
              ?.map((e) => AmbiguousItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      notes: json['notes'] as String? ?? '',
    );
  }
}
