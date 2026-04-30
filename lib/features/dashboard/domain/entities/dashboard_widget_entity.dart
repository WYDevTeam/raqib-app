class DashboardWidget {
  final String id;
  final String title;
  final bool isVisible;
  final int sortOrder;
  final String type; // 'builtin' | 'custom_formula'
  final String? formulaJson;
  final String displayFormat; // 'number' | 'signed' | 'percent'

  const DashboardWidget({
    required this.id,
    required this.title,
    required this.isVisible,
    required this.sortOrder,
    this.type = 'builtin',
    this.formulaJson,
    this.displayFormat = 'number',
  });

  bool get isCustomFormula => type == 'custom_formula';

  DashboardWidget copyWith({
    String? id,
    String? title,
    bool? isVisible,
    int? sortOrder,
    String? type,
    String? formulaJson,
    String? displayFormat,
  }) {
    return DashboardWidget(
      id: id ?? this.id,
      title: title ?? this.title,
      isVisible: isVisible ?? this.isVisible,
      sortOrder: sortOrder ?? this.sortOrder,
      type: type ?? this.type,
      formulaJson: formulaJson ?? this.formulaJson,
      displayFormat: displayFormat ?? this.displayFormat,
    );
  }
}
