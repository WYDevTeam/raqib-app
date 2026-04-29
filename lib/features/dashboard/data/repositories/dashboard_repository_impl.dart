import 'package:hive/hive.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/services/calculations_service.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/dashboard_widget_entity.dart';
import '../../domain/entities/reminder_item.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../models/dashboard_widget_model.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final CalculationsService _calc;
  final Box<DashboardWidgetModel> _widgetsBox;

  const DashboardRepositoryImpl({
    required CalculationsService calc,
    required Box<DashboardWidgetModel> widgetsBox,
  })  : _calc = calc,
        _widgetsBox = widgetsBox;

  @override
  Future<Either<AppFailure, DashboardSummary>> getDashboardSummary() async {
    try {
      final now = DateTime.now();
      final pnl = _calc.getMonthlyPnL(now);
      final assets = _calc.getAssetsByType();

      final reminders = [
        ..._calc.getActiveDebts().map(
              (r) => ReminderItem(
                personName: r.$1,
                amount: r.$2,
                isDebt: true,
              ),
            ),
        ..._calc.getActiveAmanah().map(
              (r) => ReminderItem(
                personName: r.$1,
                amount: r.$2,
                isDebt: false,
              ),
            ),
      ];

      return Right(
        DashboardSummary(
          liquidCash: _calc.getLiquidCash(),
          netWorthConservative: _calc.getNetWorthConservative(),
          netWorthTotal: _calc.getNetWorthTotal(),
          realPnLThisMonth: pnl.income - pnl.expenses,
          monthlyIncome: pnl.income,
          monthlyExpenses: pnl.expenses,
          goldValue: assets['gold'] ?? 0,
          silverValue: assets['silver'] ?? 0,
          cryptoValue: assets['crypto'] ?? 0,
          otherAssetsValue: assets['other'] ?? 0,
          totalAssetsValue: _calc.getTotalAssetsValue(),
          totalAmanah: _calc.getTotalAmanah(),
          totalDebtsOwed: _calc.getTotalDebtsOwed(),
          reminders: reminders,
        ),
      );
    } catch (e) {
      return Left(AppFailure('فشل تحميل لوحة التحكم: $e'));
    }
  }

  @override
  Future<Either<AppFailure, List<DashboardWidget>>> getWidgets() async {
    try {
      final widgets = _widgetsBox.values
          .map(
            (m) => DashboardWidget(
              id: m.id,
              title: m.title,
              isVisible: m.isVisible,
              sortOrder: m.sortOrder,
            ),
          )
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return Right(widgets);
    } catch (e) {
      return Left(AppFailure('فشل تحميل إعدادات الواجهة: $e'));
    }
  }

  @override
  Future<Either<AppFailure, void>> updateWidgets(
      List<DashboardWidget> widgets) async {
    try {
      for (var i = 0; i < widgets.length; i++) {
        final w = widgets[i];
        final existing = _widgetsBox.get(w.id);
        if (existing != null) {
          existing.isVisible = w.isVisible;
          existing.sortOrder = i;
          await existing.save();
        } else {
          await _widgetsBox.put(
            w.id,
            DashboardWidgetModel(
              id: w.id,
              title: w.title,
              formulaExpression: '',
              isVisible: w.isVisible,
              sortOrder: i,
            ),
          );
        }
      }
      return const Right(null);
    } catch (e) {
      return Left(AppFailure('فشل حفظ إعدادات الواجهة: $e'));
    }
  }
}
