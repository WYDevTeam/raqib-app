import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/dashboard_widget_entity.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardWidgetsUseCase {
  final DashboardRepository _repository;
  const GetDashboardWidgetsUseCase(this._repository);

  Future<Either<AppFailure, List<DashboardWidget>>> call() =>
      _repository.getWidgets();
}
