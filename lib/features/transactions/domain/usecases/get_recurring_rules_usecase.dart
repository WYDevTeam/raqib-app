import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/recurring_rule_entity.dart';
import '../repositories/recurring_rule_repository.dart';

class GetRecurringRulesUseCase {
  final RecurringRuleRepository _repository;
  const GetRecurringRulesUseCase(this._repository);

  Future<Either<AppFailure, List<RecurringRuleEntity>>> call() =>
      _repository.getRules();
}
