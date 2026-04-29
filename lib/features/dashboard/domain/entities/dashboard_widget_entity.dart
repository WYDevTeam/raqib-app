class DashboardWidget {
  final String id;
  final String title;
  final bool isVisible;
  final int sortOrder;

  const DashboardWidget({
    required this.id,
    required this.title,
    required this.isVisible,
    required this.sortOrder,
  });

  DashboardWidget copyWith({
    String? id,
    String? title,
    bool? isVisible,
    int? sortOrder,
  }) {
    return DashboardWidget(
      id: id ?? this.id,
      title: title ?? this.title,
      isVisible: isVisible ?? this.isVisible,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
