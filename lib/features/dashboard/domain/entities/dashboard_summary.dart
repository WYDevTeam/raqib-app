import 'reminder_item.dart';

class DashboardSummary {
  final double liquidCash;
  final double netWorthConservative;
  final double netWorthTotal;
  final double realPnLThisMonth;
  final double monthlyIncome;
  final double monthlyExpenses;
  final double goldValue;
  final double silverValue;
  final double cryptoValue;
  final double otherAssetsValue;
  final double totalAssetsValue;
  final double totalAmanah;
  final double totalDebtsOwed;
  final List<ReminderItem> reminders;

  const DashboardSummary({
    required this.liquidCash,
    required this.netWorthConservative,
    required this.netWorthTotal,
    required this.realPnLThisMonth,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.goldValue,
    required this.silverValue,
    required this.cryptoValue,
    required this.otherAssetsValue,
    required this.totalAssetsValue,
    required this.totalAmanah,
    required this.totalDebtsOwed,
    required this.reminders,
  });
}
