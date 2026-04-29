import '../../../../core/utils/either.dart';
import '../entities/recurring_rule_entity.dart';
import '../utils/recurring_service.dart';
import 'add_transaction_usecase.dart';
import 'get_recurring_rules_usecase.dart';
import 'update_recurring_rule_usecase.dart';

class ProcessRecurringTransactionsUseCase {
  final GetRecurringRulesUseCase _getRules;
  final AddTransactionUseCase _addTransaction;
  final UpdateRecurringRuleUseCase _updateRule;

  const ProcessRecurringTransactionsUseCase({
    required GetRecurringRulesUseCase getRules,
    required AddTransactionUseCase addTransaction,
    required UpdateRecurringRuleUseCase updateRule,
  })  : _getRules = getRules,
        _addTransaction = addTransaction,
        _updateRule = updateRule;

  Future<void> call() async {
    final result = await _getRules();
    if (result is! Right) return;

    final rules = (result as Right).value as List<RecurringRuleEntity>;

    for (final rule in rules) {
      if (!rule.isActive) continue;

      final due = RecurringService.generateDue(rule);
      if (due.isEmpty) continue;

      for (final tx in due) {
        await _addTransaction(tx);
      }

      await _updateRule(rule.copyWith(lastGeneratedDate: due.last.date));
    }
  }
}
