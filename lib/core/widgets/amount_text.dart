import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AmountText extends StatelessWidget {
  final double amount;
  final bool isIncome;
  final TextStyle? style;

  const AmountText({
    super.key,
    required this.amount,
    required this.isIncome,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? AppTheme.secondary : AppTheme.error;
    final prefix = isIncome ? '+' : '-';
    final base = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        );
    return Text(
      '$prefix${amount.toStringAsFixed(2)}',
      style: style != null ? style!.copyWith(color: color) : base,
    );
  }
}
