import 'package:hive/hive.dart';

import '../../features/debts_amanah/data/models/amanah_model.dart';
import '../../features/debts_amanah/data/models/debt_model.dart';
import '../../features/investments/data/models/asset_model.dart';
import '../../features/settings/data/models/app_settings_model.dart';
import '../../features/transactions/data/models/transaction_model.dart';

class CalculationsService {
  final Box<TransactionModel> _txBox;
  final Box<AmanahModel> _amanahBox;
  final Box<DebtModel> _debtBox;
  final Box<AssetModel> _assetBox;
  final Box<AppSettingsModel> _settingsBox;

  const CalculationsService({
    required Box<TransactionModel> txBox,
    required Box<AmanahModel> amanahBox,
    required Box<DebtModel> debtBox,
    required Box<AssetModel> assetBox,
    required Box<AppSettingsModel> settingsBox,
  })  : _txBox = txBox,
        _amanahBox = amanahBox,
        _debtBox = debtBox,
        _assetBox = assetBox,
        _settingsBox = settingsBox;

  AppSettingsModel get _settings =>
      _settingsBox.get('settings') ?? AppSettingsModel();

  // ── Cash ───────────────────────────────────────────────────────────────────

  double getLiquidCash() {
    return _txBox.values.fold(
      0.0,
      (sum, t) => sum + (t.isIncome ? t.amount : -t.amount),
    );
  }

  // ── Assets ─────────────────────────────────────────────────────────────────

  double getTotalAssetsValue() {
    return _assetBox.values
        .fold(0.0, (sum, a) => sum + a.currentTotalValue);
  }

  Map<String, double> getAssetsByType() {
    final result = <String, double>{
      'gold': 0,
      'silver': 0,
      'crypto': 0,
      'other': 0,
    };
    for (final a in _assetBox.values) {
      final key = result.containsKey(a.type) ? a.type : 'other';
      result[key] = (result[key] ?? 0) + a.currentTotalValue;
    }
    return result;
  }

  // ── Amanah & Debts ─────────────────────────────────────────────────────────

  double getTotalAmanah() {
    return _amanahBox.values
        .where((a) => !a.isReturned)
        .fold(0.0, (sum, a) => sum + a.amount);
  }

  double getTotalDebtsOwed() {
    return _debtBox.values
        .where((d) => !d.isSettled)
        .fold(0.0, (sum, d) => sum + d.remainingAmount);
  }

  List<(String name, double amount)> getActiveDebts() {
    return _debtBox.values
        .where((d) => !d.isSettled)
        .map((d) => (d.personName, d.remainingAmount))
        .toList();
  }

  List<(String name, double amount)> getActiveAmanah() {
    return _amanahBox.values
        .where((a) => !a.isReturned)
        .map((a) => (a.personName, a.amount))
        .toList();
  }

  // ── Net Worth ──────────────────────────────────────────────────────────────

  double getNetWorthConservative() {
    double nw = getLiquidCash() + getTotalAssetsValue();
    if (_settings.amanahDeductedFromNetWorth) {
      nw -= getTotalAmanah();
    }
    return nw;
  }

  double getNetWorthTotal() {
    return getNetWorthConservative() + getTotalDebtsOwed();
  }

  // ── Monthly P&L ────────────────────────────────────────────────────────────

  ({double income, double expenses}) getMonthlyPnL(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    double income = 0;
    double expenses = 0;

    for (final t in _txBox.values) {
      if (!t.date.isBefore(start) && !t.date.isAfter(end)) {
        if (t.isIncome) {
          income += t.amount;
        } else {
          expenses += t.amount;
        }
      }
    }
    return (income: income, expenses: expenses);
  }
}
