import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../repositories/dashboard_repository.dart';

class DeleteCustomWidgetUseCase {
  final DashboardRepository _repository;
  const DeleteCustomWidgetUseCase(this._repository);

  Future<Either<AppFailure, void>> call(String id) =>
      _repository.deleteCustomWidget(id);
}
