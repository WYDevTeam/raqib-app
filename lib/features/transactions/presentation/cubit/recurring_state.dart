import '../../domain/entities/recurring_rule_entity.dart';

sealed class RecurringState {
  const RecurringState();
}

final class RecurringInitial extends RecurringState {
  const RecurringInitial();
}

final class RecurringProcessing extends RecurringState {
  const RecurringProcessing();
}

final class RecurringLoaded extends RecurringState {
  final List<RecurringRuleEntity> rules;
  /// Number of transactions generated in the last processAllRules() call.
  final int lastGeneratedCount;

  const RecurringLoaded({
    required this.rules,
    this.lastGeneratedCount = 0,
  });

  List<RecurringRuleEntity> get activeRules =>
      rules.where((r) => r.isActive).toList();

  List<RecurringRuleEntity> get inactiveRules =>
      rules.where((r) => !r.isActive).toList();
}

final class RecurringError extends RecurringState {
  final String message;
  const RecurringError(this.message);
}
