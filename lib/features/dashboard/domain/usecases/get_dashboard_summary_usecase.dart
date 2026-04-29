import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/dashboard_summary.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardSummaryUseCase {
  final DashboardRepository _repository;
  const GetDashboardSummaryUseCase(this._repository);

  Future<Either<AppFailure, DashboardSummary>> call() =>
      _repository.getDashboardSummary();
}
