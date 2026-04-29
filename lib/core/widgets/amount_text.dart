import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

class AmountText extends StatelessWidget {
  final double amount;
  final bool isIncome;
  final String currency;
  final TextStyle? style;

  const AmountText({
    super.key,
    required this.amount,
    required this.isIncome,
    this.currency = 'USD',
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? AppTheme.secondary : AppTheme.error;
    final prefix = isIncome ? '+' : '-';
    final formatted = NumberFormat('#,##0.##').format(amount);
    final base = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        );
    return Text(
      '$prefix$formatted $currency',
      style: style != null ? style!.copyWith(color: color) : base,
    );
  }
}
