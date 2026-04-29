import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/recurring_rule_entity.dart';
import '../repositories/recurring_rule_repository.dart';

class UpdateRecurringRuleUseCase {
  final RecurringRuleRepository _repository;
  const UpdateRecurringRuleUseCase(this._repository);

  Future<Either<AppFailure, void>> call(RecurringRuleEntity rule) =>
      _repository.updateRule(rule);
}
