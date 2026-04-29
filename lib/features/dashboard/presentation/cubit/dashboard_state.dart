import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/dashboard_widget_entity.dart';

sealed class DashboardState {
  const DashboardState();
}

final class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

final class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

final class DashboardLoaded extends DashboardState {
  final DashboardSummary summary;
  final List<DashboardWidget> widgets;
  final bool isConservativeMode;

  const DashboardLoaded({
    required this.summary,
    required this.widgets,
    this.isConservativeMode = true,
  });

  double get displayedNetWorth =>
      isConservativeMode ? summary.netWorthConservative : summary.netWorthTotal;

  List<DashboardWidget> get visibleWidgets =>
      widgets.where((w) => w.isVisible).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  DashboardLoaded copyWith({
    DashboardSummary? summary,
    List<DashboardWidget>? widgets,
    bool? isConservativeMode,
  }) {
    return DashboardLoaded(
      summary: summary ?? this.summary,
      widgets: widgets ?? this.widgets,
      isConservativeMode: isConservativeMode ?? this.isConservativeMode,
    );
  }
}

final class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
}
