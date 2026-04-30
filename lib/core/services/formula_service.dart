import 'dart:convert';

import 'package:math_expressions/math_expressions.dart';

import 'calculations_service.dart';

class FormulaService {
  final CalculationsService _calc;
  FormulaService(this._calc);

  double evaluate(String formulaJson) {
    try {
      final formula = jsonDecode(formulaJson) as List<dynamic>;
      if (formula.isEmpty) return 0;

      final expressionParts = <String>[];
      for (final element in formula) {
        final type = element['type'] as String;
        switch (type) {
          case 'variable':
            final val = _getVariableValue(element['key'] as String);
            expressionParts.add(val.toString());
          case 'operator':
          case 'paren':
            expressionParts.add(element['value'] as String);
          case 'number':
            expressionParts.add(element['value'].toString());
        }
      }

      final expression = expressionParts.join(' ');
      final exp = Parser().parse(expression);
      return exp.evaluate(EvaluationType.REAL, ContextModel()) as double;
    } catch (_) {
      return 0;
    }
  }

  double _getVariableValue(String key) {
    final pnl = _calc.getMonthlyPnL(DateTime.now());
    final assets = _calc.getAssetsByType();
    return switch (key) {
      'liquid_cash' => _calc.getLiquidCash(),
      'gold_value' => assets['gold'] ?? 0,
      'silver_value' => assets['silver'] ?? 0,
      'crypto_value' => assets['crypto'] ?? 0,
      'total_assets' => _calc.getTotalAssetsValue(),
      'real_income' => pnl.income,
      'real_expenses' => pnl.expenses,
      'real_pnl' => pnl.income - pnl.expenses,
      'realized_pnl' => _calc.getTotalRealizedPnL(),
      'unrealized_pnl' => _calc.getTotalUnrealizedPnL(),
      'debts_owed' => _calc.getTotalDebtsOwed(),
      'amanah_held' => _calc.getTotalAmanah(),
      'net_worth' => _calc.getNetWorthConservative(),
      _ => 0,
    };
  }
}
