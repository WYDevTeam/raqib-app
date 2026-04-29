import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/recurring_rule_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/usecases/add_recurring_rule_usecase.dart';
import '../../domain/usecases/get_recurring_rules_usecase.dart';
import '../../domain/usecases/stop_recurring_rule_usecase.dart';
import '../../domain/usecases/update_recurring_rule_usecase.dart';
import '../../domain/utils/recurring_service.dart';
import 'recurring_state.dart';

class RecurringCubit extends Cubit<RecurringState> {
  final GetRecurringRulesUseCase _getRules;
  final AddRecurringRuleUseCase _addRule;
  final UpdateRecurringRuleUseCase _updateRule;
  final StopRecurringRuleUseCase _stopRule;
  final ResumeRecurringRuleUseCase _resumeRule;
  final TransactionRepository _transactionRepo;

  RecurringCubit(
    this._getRules,
    this._addRule,
    this._updateRule,
    this._stopRule,
    this._resumeRule,
    this._transactionRepo,
  ) : super(const RecurringInitial());

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Called at app startup: generates all due transactions for every active rule.
  Future<void> processAllRules() async {
    emit(const RecurringProcessing());

    final rulesResult = await _getRules();
    if (rulesResult is Left) {
      final failure = (rulesResult as Left).value;
      emit(RecurringError(failure.message));
      return;
    }

    final rules = (rulesResult as Right).value as List<RecurringRuleEntity>;
    int generated = 0;

    for (final rule in rules) {
      if (!rule.isActive) continue;

      final due = RecurringService.generateDue(rule);
      if (due.isEmpty) continue;

      // Persist each generated transaction.
      for (final tx in due) {
        await _transactionRepo.addTransaction(tx);
        generated++;
      }

      // Update lastGeneratedDate to the date of the last generated tx.
      final updatedRule = rule.copyWith(
        lastGeneratedDate: due.last.date,
      );
      await _updateRule(updatedRule);
    }

    // Reload all rules after updates.
    final refreshResult = await _getRules();
    refreshResult.fold(
      (f) => emit(RecurringError(f.message)),
      (updatedRules) => emit(RecurringLoaded(
        rules: updatedRules,
        lastGeneratedCount: generated,
      )),
    );
  }

  /// Load rules without generating (for management screen).
  Future<void> loadRules() async {
    final result = await _getRules();
    result.fold(
      (f) => emit(RecurringError(f.message)),
      (rules) => emit(RecurringLoaded(rules: rules)),
    );
  }

  /// Add a new rule and immediately generate the first batch of due transactions.
  Future<void> addRule(RecurringRuleEntity rule) async {
    final result = await _addRule(rule);
    if (result is Left) {
      final failure = (result as Left).value;
      emit(RecurringError(failure.message));
      return;
    }

    // Generate any transactions due right away (e.g. startDate = today).
    final due = RecurringService.generateDue(rule);
    if (due.isNotEmpty) {
      for (final tx in due) {
        await _transactionRepo.addTransaction(tx);
      }
      final updatedRule = rule.copyWith(
        lastGeneratedDate: due.last.date,
      );
      await _updateRule(updatedRule);
    }
    await loadRules();
  }

  /// Stop a rule (sets isActive=false). Does NOT delete past transactions.
  Future<void> stopRule(RecurringRuleEntity rule) async {
    final result = await _stopRule(rule);
    result.fold(
      (f) => emit(RecurringError(f.message)),
      (_) => loadRules(),
    );
  }

  /// Re-activate a stopped rule.
  Future<void> resumeRule(RecurringRuleEntity rule) async {
    final result = await _resumeRule(rule);
    result.fold(
      (f) => emit(RecurringError(f.message)),
      (_) => loadRules(),
    );
  }
}
