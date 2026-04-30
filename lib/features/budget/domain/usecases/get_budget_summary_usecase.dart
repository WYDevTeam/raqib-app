import '../entities/budget_entity.dart';
import '../repositories/budget_repository.dart';

class GetBudgetSummaryUseCase {
  final BudgetRepository _repository;

  GetBudgetSummaryUseCase(this._repository);

  List<BudgetSummary> call(DateTime month) {
    return _repository.getMonthSummary(month);
  }
}
