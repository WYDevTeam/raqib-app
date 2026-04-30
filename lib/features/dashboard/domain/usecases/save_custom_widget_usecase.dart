import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/dashboard_widget_entity.dart';
import '../repositories/dashboard_repository.dart';

class SaveCustomWidgetUseCase {
  final DashboardRepository _repository;
  const SaveCustomWidgetUseCase(this._repository);

  Future<Either<AppFailure, void>> call(DashboardWidget widget) =>
      _repository.saveCustomWidget(widget);
}
