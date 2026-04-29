class ReminderItem {
  final String personName;
  final double amount;
  final bool isDebt; // true = debt owed to you, false = amanah held by you

  const ReminderItem({
    required this.personName,
    required this.amount,
    required this.isDebt,
  });
}
