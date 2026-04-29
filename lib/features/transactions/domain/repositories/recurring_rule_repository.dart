import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/recurring_rule_entity.dart';

abstract class RecurringRuleRepository {
  Future<Either<AppFailure, List<RecurringRuleEntity>>> getRules();

  Future<Either<AppFailure, void>> addRule(RecurringRuleEntity rule);

  Future<Either<AppFailure, void>> updateRule(RecurringRuleEntity rule);

  Future<Either<AppFailure, void>> deleteRule(String id);
}
