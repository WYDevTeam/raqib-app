import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/dashboard_summary.dart';
import '../entities/dashboard_widget_entity.dart';

abstract class DashboardRepository {
  Future<Either<AppFailure, DashboardSummary>> getDashboardSummary();
  Future<Either<AppFailure, List<DashboardWidget>>> getWidgets();
  Future<Either<AppFailure, void>> updateWidgets(List<DashboardWidget> widgets);
  Future<Either<AppFailure, void>> saveCustomWidget(DashboardWidget widget);
  Future<Either<AppFailure, void>> deleteCustomWidget(String id);
}
