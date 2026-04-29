import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/recurring_rule_entity.dart';
import '../repositories/recurring_rule_repository.dart';

/// Stops a rule without deleting previously generated transactions.
/// Sets isActive = false and persists it.
class StopRecurringRuleUseCase {
  final RecurringRuleRepository _repository;
  const StopRecurringRuleUseCase(this._repository);

  Future<Either<AppFailure, void>> call(RecurringRuleEntity rule) =>
      _repository.updateRule(rule.copyWith(isActive: false));
}

/// Re-activates a previously stopped rule.
class ResumeRecurringRuleUseCase {
  final RecurringRuleRepository _repository;
  const ResumeRecurringRuleUseCase(this._repository);

  Future<Either<AppFailure, void>> call(RecurringRuleEntity rule) =>
      _repository.updateRule(rule.copyWith(isActive: true));
}
