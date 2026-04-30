import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/dashboard_widget_entity.dart';
import '../../domain/usecases/delete_custom_widget_usecase.dart';
import '../../domain/usecases/get_dashboard_summary_usecase.dart';
import '../../domain/usecases/get_dashboard_widgets_usecase.dart';
import '../../domain/usecases/save_custom_widget_usecase.dart';
import '../../domain/usecases/update_dashboard_widgets_usecase.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final GetDashboardSummaryUseCase _getSummary;
  final GetDashboardWidgetsUseCase _getWidgets;
  final UpdateDashboardWidgetsUseCase _updateWidgets;
  final SaveCustomWidgetUseCase _saveCustomWidget;
  final DeleteCustomWidgetUseCase _deleteCustomWidget;

  DashboardCubit(
    this._getSummary,
    this._getWidgets,
    this._updateWidgets,
    this._saveCustomWidget,
    this._deleteCustomWidget,
  ) : super(const DashboardInitial());

  Future<void> loadDashboard() async {
    emit(const DashboardLoading());

    final summaryResult = await _getSummary();
    final widgetsResult = await _getWidgets();

    summaryResult.fold(
      (f) => emit(DashboardError(f.message)),
      (summary) {
        widgetsResult.fold(
          (_) => emit(DashboardLoaded(summary: summary, widgets: const [])),
          (widgets) => emit(DashboardLoaded(summary: summary, widgets: widgets)),
        );
      },
    );
  }

  Future<void> refresh() => loadDashboard();

  void toggleConservativeMode() {
    final current = state;
    if (current is! DashboardLoaded) return;
    emit(current.copyWith(isConservativeMode: !current.isConservativeMode));
  }

  Future<void> saveWidgets(List<DashboardWidget> widgets) async {
    final result = await _updateWidgets(widgets);
    result.fold(
      (_) {},
      (_) {
        final current = state;
        if (current is DashboardLoaded) {
          emit(current.copyWith(widgets: widgets));
        }
      },
    );
  }

  Future<void> saveCustomWidget(DashboardWidget widget) async {
    await _saveCustomWidget(widget);
    await loadDashboard();
  }

  Future<void> deleteCustomWidget(String id) async {
    await _deleteCustomWidget(id);
    await loadDashboard();
  }
}
