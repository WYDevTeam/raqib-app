import '../entities/budget_entity.dart';
import '../repositories/budget_repository.dart';

class SetBudgetUseCase {
  final BudgetRepository _repository;

  SetBudgetUseCase(this._repository);

  Future<void> call(BudgetEntity budget) async {
    await _repository.setBudget(budget);
  }
}
