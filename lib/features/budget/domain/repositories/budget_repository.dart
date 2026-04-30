import '../entities/budget_entity.dart';
import '../../../../features/transactions/domain/entities/category_entity.dart';

abstract class BudgetRepository {
  Future<void> setBudget(BudgetEntity budget);
  List<BudgetSummary> getMonthSummary(DateTime month);
  List<CategoryEntity> getAvailableCategories();
}
