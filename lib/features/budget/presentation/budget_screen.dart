import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import 'cubit/budget_cubit.dart';
import 'cubit/budget_state.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<BudgetCubit>()..loadBudgets(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(title: const Text('الميزانية')),
            floatingActionButton: FloatingActionButton(
              heroTag: 'budget_add_fab',
              onPressed: () async {
                await context.push('/budget/add');
                if (context.mounted) {
                  context.read<BudgetCubit>().loadBudgets();
                }
              },
              backgroundColor: AppTheme.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
            body: BlocBuilder<BudgetCubit, BudgetState>(
              builder: (context, state) {
                if (state is BudgetLoading || state is BudgetInitial) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is BudgetError) {
                  return Center(child: Text('Error: ${state.message}'));
                }

                if (state is BudgetLoaded) {
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildMonthSelector(context, state),
                      const SizedBox(height: 24),
                      _buildTotalBudget(context, state),
                      const SizedBox(height: 24),
                      if (state.summaries.isNotEmpty) ...[
                        Text(
                          'تفاصيل الميزانية',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        ...state.summaries.map(
                          (summary) => _buildBudgetCategory(context, summary),
                        ),
                      ] else ...[
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'لا توجد ميزانيات محددة لهذا الشهر. أضف ميزانية جديدة.',
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context, BudgetLoaded state) {
    // Format Arabic month and year e.g. "أبريل 2026"
    final formattedDate = DateFormat(
      'MMMM yyyy',
      'ar',
    ).format(state.currentMonth);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => context.read<BudgetCubit>().changeMonth(-1),
        ),
        Text(
          formattedDate,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => context.read<BudgetCubit>().changeMonth(1),
        ),
      ],
    );
  }

  Widget _buildTotalBudget(BuildContext context, BudgetLoaded state) {
    final double progress = state.totalAllocated > 0
        ? (state.totalSpent / state.totalAllocated).clamp(0.0, 1.0)
        : 0.0;
    final double remaining = state.totalAllocated - state.totalSpent;
    final bool isOverBudget = remaining < 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        children: [
          Text(
            'إجمالي الميزانية',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '\$${state.totalSpent.toStringAsFixed(0)} ',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: isOverBudget ? AppTheme.error : AppTheme.primary,
                ),
              ),
              Text(
                '/ \$${state.totalAllocated.toStringAsFixed(0)}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppTheme.textDisabled),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.background,
              color: isOverBudget ? AppTheme.error : AppTheme.primary,
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isOverBudget
                ? 'تجاوزت الميزانية بـ \$${(-remaining).toStringAsFixed(0)}!'
                : 'متبقي \$${remaining.toStringAsFixed(0)} هذا الشهر',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isOverBudget ? AppTheme.error : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCategory(BuildContext context, dynamic summary) {
    // using dynamic to avoid strict type casting in UI, it's actually BudgetSummary
    final String name = summary.category.name;
    final double spent = summary.spent;
    final double limit = summary.budget.monthlyTarget;
    final double progress = summary.progress.clamp(0.0, 1.0);
    final bool isOverBudget = summary.isOverBudget;

    // Color logic
    Color color = AppTheme.primary;
    if (summary.progress < 0.7) {
      color = AppTheme.secondary; // Green
    } else if (summary.progress < 0.9) {
      color = AppTheme.warning; // Yellow
    } else if (summary.progress <= 1.0) {
      color = Colors.orange; // Orange
    } else {
      color = AppTheme.error; // Red
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverBudget
              ? AppTheme.error.withValues(alpha: 0.5)
              : const Color(0xFFEFEFEF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    IconData(
                      summary.category.iconCodePoint,
                      fontFamily: 'MaterialIcons',
                    ),
                    size: 20,
                    color: Color(summary.category.colorValue),
                  ),
                  const SizedBox(width: 8),
                  Text(name, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              Text(
                '\$${spent.toInt()} / \$${limit.toInt()} (${(summary.progress * 100).toInt()}%)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isOverBudget ? AppTheme.error : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.background,
              color: color,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          if (isOverBudget)
            Text(
              'تجاوزت الميزانية بـ \$${(spent - limit).toInt()}!',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.error),
            )
          else
            Text(
              'متبقي: \$${(limit - spent).toInt()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}
