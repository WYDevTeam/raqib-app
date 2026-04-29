import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/dashboard_widget_entity.dart';
import '../repositories/dashboard_repository.dart';

class UpdateDashboardWidgetsUseCase {
  final DashboardRepository _repository;
  const UpdateDashboardWidgetsUseCase(this._repository);

  Future<Either<AppFailure, void>> call(List<DashboardWidget> widgets) =>
      _repository.updateWidgets(widgets);
}
