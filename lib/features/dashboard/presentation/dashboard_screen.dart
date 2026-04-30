import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import 'cubit/dashboard_cubit.dart';
import 'cubit/dashboard_state.dart';
import 'widgets/edit_overview_sheet.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DashboardCubit>()..loadDashboard(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  Future<void> _showFormulaBuilder() async {
    await context.push('/dashboard/formula-builder');
    if (mounted) context.read<DashboardCubit>().refresh();
  }

  Future<void> _onRefresh() async {
    await context.read<DashboardCubit>().refresh();
  }

  String _formatWidgetValue(double value, String displayFormat) {
    return switch (displayFormat) {
      'signed' => '${value >= 0 ? '+' : ''}${_fmt(value)}',
      'percent' => '${NumberFormat('#,##0.##').format(value)}%',
      _ => _fmt(value),
    };
  }

  String _formulaDisplayText(String? formulaJson) {
    if (formulaJson == null || formulaJson.isEmpty) return '';
    try {
      final elements = jsonDecode(formulaJson) as List<dynamic>;
      return elements
          .map((e) => e['label'] as String? ?? '')
          .join(' ');
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        final loaded = state is DashboardLoaded ? state : null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('راقب'),
            actions: [
              TextButton.icon(
                onPressed: () => context.push('/subscription'),
                icon: const Icon(Icons.workspace_premium,
                    color: Color(0xFFFFD700)),
                label: const Text(
                  'Pro',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFFFD700).withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => context.go('/dashboard/settings'),
              ),
            ],
          ),
          body: state is DashboardLoading && loaded == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildNetWorthCard(context, loaded),
                      const SizedBox(height: 24),
                      _buildOverviewSection(context, loaded),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'بطاقات مخصصة',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('إضافة معادلة'),
                            onPressed: _showFormulaBuilder,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (loaded != null)
                        ...loaded.widgets
                            .where((w) => w.isCustomFormula)
                            .map((w) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildCustomFormulaCard(
                                    context,
                                    w.title,
                                    _formatWidgetValue(
                                      loaded.summary.customWidgetValues[w.id] ?? 0,
                                      w.displayFormat,
                                    ),
                                    _formulaDisplayText(w.formulaJson),
                                  ),
                                )),
                      if (loaded != null &&
                          loaded.widgets.where((w) => w.isCustomFormula).isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'أضف معادلة مخصصة لعرضها هنا',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildNetWorthCard(
      BuildContext context, DashboardLoaded? state) {
    final nw = state?.displayedNetWorth ?? 0;
    final isConservative = state?.isConservativeMode ?? true;
    final debtHeld = state?.summary.totalDebtsOwed ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF1E56C8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'صافي الثروة الحقيقي',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isConservative ? 'متحفظ' : 'كلي',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: isConservative,
                      onChanged: (_) => context
                          .read<DashboardCubit>()
                          .toggleConservativeMode(),
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppTheme.secondary,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor:
                          Colors.white.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            state == null ? '---' : _fmt(nw),
            style: Theme.of(context)
                .textTheme
                .displayMedium
                ?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white.withValues(alpha: 0.8),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isConservative
                      ? 'لا يتضمن الديون التي لك (${_fmt(debtHeld)})'
                      : 'يتضمن كافة الديون التي لك',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(
      BuildContext context, DashboardLoaded? state) {
    final summary = state?.summary;
    final widgets = state?.visibleWidgets ?? [];
    final idSet = {for (final w in widgets) w.id};

    final Map<String, Widget Function(BuildContext)> widgetMap = {
      'الكاش الفعلي': (ctx) => _buildSummaryCard(
            ctx,
            'الكاش الفعلي',
            summary == null ? '---' : _fmt(summary.liquidCash),
            Icons.attach_money,
            AppTheme.primary,
          ),
      'الربح الحقيقي (P&L)': (ctx) => _buildSummaryCard(
            ctx,
            'الربح الحقيقي (P&L)',
            summary == null
                ? '---'
                : '${summary.realPnLThisMonth >= 0 ? '+' : ''}${_fmt(summary.realPnLThisMonth)}',
            Icons.trending_up,
            summary != null && summary.realPnLThisMonth >= 0
                ? AppTheme.secondary
                : AppTheme.error,
          ),
      'إجمالي المعادن': (ctx) => _buildSummaryCard(
            ctx,
            'إجمالي المعادن',
            summary == null
                ? '---'
                : _fmt(summary.goldValue + summary.silverValue),
            Icons.diamond,
            Colors.amber,
          ),
      'أمانات عندي': (ctx) => _buildSummaryCard(
            ctx,
            'أمانات عندي',
            summary == null ? '---' : _fmt(summary.totalAmanah),
            Icons.lock_outline,
            AppTheme.error,
          ),
      'الديون المستحقة': (ctx) => _buildSummaryCard(
            ctx,
            'الديون المستحقة',
            summary == null ? '---' : _fmt(summary.totalDebtsOwed),
            Icons.money_off,
            AppTheme.warning,
          ),
    };

    final overviewItems = <String, bool>{
      'الكاش الفعلي': idSet.contains('cash'),
      'الربح الحقيقي (P&L)': idSet.contains('pnl'),
      'إجمالي المعادن': idSet.contains('assets'),
      'أمانات عندي': idSet.contains('reminders'),
      'الديون المستحقة': idSet.contains('debts'),
    };

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('نظرة عامة',
                style: Theme.of(context).textTheme.titleLarge),
            IconButton(
              icon: const Icon(Icons.edit_note,
                  color: AppTheme.primary),
              onPressed: () async {
                final cubit = context.read<DashboardCubit>();
                final result =
                    await showModalBottomSheet<Map<String, bool>>(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => EditOverviewSheet(
                      initialItems: overviewItems),
                );
                if (result != null) {
                  // Map result back to DashboardWidget list
                  final current = cubit.state;
                  if (current is! DashboardLoaded) return;
                  final updated = current.widgets.map((w) {
                    return switch (w.id) {
                      'cash' => w.copyWith(isVisible: result['الكاش الفعلي'] ?? true),
                      'pnl' => w.copyWith(isVisible: result['الربح الحقيقي (P&L)'] ?? true),
                      'assets' => w.copyWith(isVisible: result['إجمالي المعادن'] ?? true),
                      'reminders' => w.copyWith(isVisible: result['أمانات عندي'] ?? true),
                      'debts' => w.copyWith(isVisible: result['الديون المستحقة'] ?? true),
                      _ => w,
                    };
                  }).toList();
                  await cubit.saveWidgets(updated);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDynamicOverviewGrid(context, overviewItems, widgetMap),
      ],
    );
  }

  Widget _buildDynamicOverviewGrid(
    BuildContext context,
    Map<String, bool> overviewItems,
    Map<String, Widget Function(BuildContext)> widgetMap,
  ) {
    final active = overviewItems.entries
        .where((e) => e.value)
        .map((e) => widgetMap[e.key]!(context))
        .toList();

    if (active.isEmpty) {
      return const Center(
        child: Text(
          'لم يتم اختيار أي بطاقة للظهور',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final rows = <Widget>[];
    for (int i = 0; i < active.length; i += 2) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Expanded(child: active[i]),
              const SizedBox(width: 16),
              i + 1 < active.length
                  ? Expanded(child: active[i + 1])
                  : const Spacer(),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildCustomFormulaCard(
    BuildContext context,
    String title,
    String amount,
    String formula,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  formula,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: AppTheme.primary),
          ),
        ],
      ),
    );
  }
}

String _fmt(double v) {
  final abs = NumberFormat('#,##0.##').format(v.abs());
  return '${v < 0 ? '-' : ''}\$$abs';
}
