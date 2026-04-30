import 'dart:math';

import 'package:hive/hive.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/calculations_service.dart';
import '../../../../core/services/formula_service.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/dashboard_widget_entity.dart';
import '../../domain/entities/reminder_item.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../models/dashboard_widget_model.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final CalculationsService _calc;
  final Box<DashboardWidgetModel> _widgetsBox;
  final ApiService _apiService;
  final FormulaService _formulaService;

  DashboardRepositoryImpl({
    required CalculationsService calc,
    required Box<DashboardWidgetModel> widgetsBox,
    required ApiService apiService,
    required FormulaService formulaService,
  })  : _calc = calc,
        _widgetsBox = widgetsBox,
        _apiService = apiService,
        _formulaService = formulaService;

  @override
  Future<Either<AppFailure, DashboardSummary>> getDashboardSummary() async {
    try {
      await _apiService.refreshAssetPrices(_calc.getAllAssets());

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

      final customWidgetValues = <String, double>{};
      for (final model in _widgetsBox.values.where(
        (m) => m.type == 'custom_formula' && m.formulaExpression.isNotEmpty,
      )) {
        customWidgetValues[model.id] =
            _formulaService.evaluate(model.formulaExpression);
      }

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
          customWidgetValues: customWidgetValues,
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
              type: m.type,
              formulaJson: m.formulaExpression.isEmpty ? null : m.formulaExpression,
              displayFormat: m.displayFormat,
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

  @override
  Future<Either<AppFailure, void>> saveCustomWidget(
      DashboardWidget widget) async {
    try {
      final maxOrder = _widgetsBox.isEmpty
          ? 0
          : _widgetsBox.values.map((w) => w.sortOrder).reduce(max) + 1;
      await _widgetsBox.put(
        widget.id,
        DashboardWidgetModel(
          id: widget.id,
          title: widget.title,
          formulaExpression: widget.formulaJson ?? '',
          isVisible: widget.isVisible,
          sortOrder: widget.sortOrder > 0 ? widget.sortOrder : maxOrder,
          type: widget.type,
          displayFormat: widget.displayFormat,
        ),
      );
      return const Right(null);
    } catch (e) {
      return Left(AppFailure('فشل حفظ الكارد: $e'));
    }
  }

  @override
  Future<Either<AppFailure, void>> deleteCustomWidget(String id) async {
    try {
      await _widgetsBox.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(AppFailure('فشل حذف الكارد: $e'));
    }
  }
}
