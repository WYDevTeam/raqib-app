import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/entities/dashboard_widget_entity.dart';
import 'cubit/dashboard_cubit.dart';
import 'cubit/dashboard_state.dart';

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

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('راقب'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            onPressed: () {
              final cubit = context.read<DashboardCubit>();
              final s = cubit.state;
              final widgets =
                  s is DashboardLoaded ? s.widgets : <DashboardWidget>[];
              context
                  .push('/dashboard/customize', extra: widgets)
                  .then((_) => cubit.loadDashboard());
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/dashboard/settings'),
          ),
        ],
      ),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) => switch (state) {
          DashboardInitial() ||
          DashboardLoading() =>
            const Center(child: CircularProgressIndicator()),
          DashboardError(:final message) => _ErrorView(
              message: message,
              onRetry: () => context.read<DashboardCubit>().loadDashboard(),
            ),
          DashboardLoaded() => _LoadedView(state: state),
        },
      ),
    );
  }
}

// ── Loaded ────────────────────────────────────────────────────────────────────

class _LoadedView extends StatelessWidget {
  final DashboardLoaded state;
  const _LoadedView({required this.state});

  @override
  Widget build(BuildContext context) {
    final visible = state.visibleWidgets;
    final idSet = {for (final w in visible) w.id};

    return RefreshIndicator(
      onRefresh: () => context.read<DashboardCubit>().refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          if (idSet.contains('net_worth')) ...[
            _NetWorthCard(state: state),
            const SizedBox(height: 16),
          ],
          if (idSet.contains('pnl')) ...[
            _PnLCard(state: state),
            const SizedBox(height: 16),
          ],
          if (idSet.contains('assets')) ...[
            _AssetsCard(state: state),
            const SizedBox(height: 16),
          ],
          if (idSet.contains('reminders') &&
              state.summary.reminders.isNotEmpty) ...[
            _RemindersCard(state: state),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

// ── Net Worth Card ────────────────────────────────────────────────────────────

class _NetWorthCard extends StatelessWidget {
  final DashboardLoaded state;
  const _NetWorthCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final nw = state.displayedNetWorth;
    final isPositive = nw >= 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF1E56C8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'صافي الثروة',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            _fmt(nw),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ModeChip(
                label: 'متحفظ',
                active: state.isConservativeMode,
                onTap: () {
                  if (!state.isConservativeMode) {
                    context.read<DashboardCubit>().toggleConservativeMode();
                  }
                },
              ),
              const SizedBox(width: 8),
              _ModeChip(
                label: 'إجمالي',
                active: !state.isConservativeMode,
                onTap: () {
                  if (state.isConservativeMode) {
                    context.read<DashboardCubit>().toggleConservativeMode();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  state.isConservativeMode
                      ? 'لا يشمل الديون التي لك (${_fmt(state.summary.totalDebtsOwed)})'
                      : 'يشمل الديون التي لك (${_fmt(state.summary.totalDebtsOwed)})',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ModeChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppTheme.primary : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── P&L Card ──────────────────────────────────────────────────────────────────

class _PnLCard extends StatelessWidget {
  final DashboardLoaded state;
  const _PnLCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state.summary;
    final pnl = s.realPnLThisMonth;
    final isPositive = pnl >= 0;
    final color = isPositive ? AppTheme.secondary : AppTheme.error;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text('الربح والخسارة الحقيقية',
                  style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${isPositive ? '+' : ''}${_fmt(pnl)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text('هذا الشهر',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PnLRow(
                  label: 'دخل',
                  value: s.monthlyIncome,
                  color: AppTheme.secondary),
              _PnLRow(
                  label: 'مصروف',
                  value: s.monthlyExpenses,
                  color: AppTheme.error),
            ],
          ),
        ],
      ),
    );
  }
}

class _PnLRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _PnLRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(_fmt(value),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ── Assets Card ───────────────────────────────────────────────────────────────

class _AssetsCard extends StatelessWidget {
  final DashboardLoaded state;
  const _AssetsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state.summary;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('أصولي', style: Theme.of(context).textTheme.titleSmall),
              Text(_fmt(s.totalAssetsValue),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _AssetRow(emoji: '💵', label: 'كاش', value: s.liquidCash),
          if (s.goldValue > 0)
            _AssetRow(emoji: '🟡', label: 'ذهب', value: s.goldValue),
          if (s.silverValue > 0)
            _AssetRow(emoji: '⚪', label: 'فضة', value: s.silverValue),
          if (s.cryptoValue > 0)
            _AssetRow(emoji: '₿', label: 'كريبتو', value: s.cryptoValue),
          if (s.otherAssetsValue > 0)
            _AssetRow(emoji: '📦', label: 'أخرى', value: s.otherAssetsValue),
        ],
      ),
    );
  }
}

class _AssetRow extends StatelessWidget {
  final String emoji;
  final String label;
  final double value;
  const _AssetRow(
      {required this.emoji, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ]),
          Text(_fmt(value),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Reminders Card ────────────────────────────────────────────────────────────

class _RemindersCard extends StatelessWidget {
  final DashboardLoaded state;
  const _RemindersCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.notifications_outlined,
                size: 18, color: AppTheme.warning),
            const SizedBox(width: 8),
            Text('تذكيرات', style: Theme.of(context).textTheme.titleSmall),
          ]),
          const SizedBox(height: 12),
          for (final r in state.summary.reminders)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Text(r.isDebt ? '💸' : '🤝',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      r.isDebt
                          ? '${r.personName} مدين لك'
                          : 'أمانة عند ${r.personName}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ]),
                  Text(_fmt(r.amount),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Shared card container ─────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: child,
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmt(double v) {
  final formatted = NumberFormat('#,##0.##').format(v.abs());
  return '${v < 0 ? '-' : ''}\$$formatted';
}
