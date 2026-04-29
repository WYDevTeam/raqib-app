import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الميزانية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/budget/add'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildTotalBudget(context),
          const SizedBox(height: 24),
          Text(
            'تفاصيل الميزانية',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildBudgetCategory(
            context,
            name: 'الطعام والشراب',
            spent: 450,
            limit: 500,
            color: AppTheme.warning,
          ),
          _buildBudgetCategory(
            context,
            name: 'المواصلات',
            spent: 100,
            limit: 200,
            color: AppTheme.secondary,
          ),
          _buildBudgetCategory(
            context,
            name: 'الترفيه',
            spent: 150,
            limit: 100,
            color: AppTheme.error,
          ),
          _buildBudgetCategory(
            context,
            name: 'الفواتير',
            spent: 180,
            limit: 200,
            color: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBudget(BuildContext context) {
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
                '\$880 ',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppTheme.primary),
              ),
              Text(
                '/ \$1,000',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.textDisabled),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              value: 0.88,
              backgroundColor: AppTheme.background,
              color: AppTheme.primary,
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'متبقي \$120 هذا الشهر',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCategory(
    BuildContext context, {
    required String name,
    required double spent,
    required double limit,
    required Color color,
  }) {
    final double progress = (spent / limit).clamp(0.0, 1.0);
    final bool isOverBudget = spent > limit;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isOverBudget ? AppTheme.error.withValues(alpha: 0.5) : const Color(0xFFEFEFEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleMedium),
              Text(
                '\$${spent.toInt()} / \$${limit.toInt()}',
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
              color: isOverBudget ? AppTheme.error : color,
              minHeight: 8,
            ),
          ),
          if (isOverBudget) ...[
            const SizedBox(height: 8),
            Text(
              'تجاوزت الميزانية بـ \$${(spent - limit).toInt()}!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.error),
            ),
          ],
        ],
      ),
    );
  }
}
