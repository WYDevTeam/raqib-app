import '../../data/models/amanah_model.dart';
import '../../data/models/debt_model.dart';

sealed class DebtsState {
  const DebtsState();
}

class DebtsLoading extends DebtsState {
  const DebtsLoading();
}

class DebtsLoaded extends DebtsState {
  final List<DebtModel> activeDebts;
  final List<DebtModel> settledDebts;
  final List<AmanahModel> activeAmanah;
  final List<AmanahModel> returnedAmanah;
  final double totalDebtsRemaining;
  final double totalAmanahRemaining;

  const DebtsLoaded({
    required this.activeDebts,
    required this.settledDebts,
    required this.activeAmanah,
    required this.returnedAmanah,
    required this.totalDebtsRemaining,
    required this.totalAmanahRemaining,
  });
}

class DebtsError extends DebtsState {
  final String message;
  const DebtsError(this.message);
}
