import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

class DebtsAmanahScreen extends StatelessWidget {
  const DebtsAmanahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الديون والأمانات'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'ديون أعطيتها (ملكك)'),
              Tab(text: 'أمانات عندي (ليس لك)'),
            ],
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textDisabled,
            indicatorColor: AppTheme.primary,
          ),
          actions: [
            IconButton(icon: const Icon(Icons.add), onPressed: () => context.push('/debts/add')),
          ],
        ),
        body: const TabBarView(
          children: [
            _DebtsGivenView(),
            _AmanahHeldView(),
          ],
        ),
      ),
    );
  }
}

class _DebtsGivenView extends StatelessWidget {
  const _DebtsGivenView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('إجمالي الديون لك', style: Theme.of(context).textTheme.titleMedium),
              Text('\$750.00', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.primary)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildDebtCard(
          context,
          name: 'أحمد (أخي)',
          totalAmount: '\$500.00',
          paidAmount: '\$100.00',
          remainingAmount: '\$400.00',
          progress: 0.2,
        ),
        _buildDebtCard(
          context,
          name: 'خالد',
          totalAmount: '\$250.00',
          paidAmount: '\$0.00',
          remainingAmount: '\$250.00',
          progress: 0.0,
        ),
      ],
    );
  }

  Widget _buildDebtCard(
    BuildContext context, {
    required String name,
    required String totalAmount,
    required String paidAmount,
    required String remainingAmount,
    required double progress,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleMedium),
              Text(totalAmount, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.background,
              color: AppTheme.primary,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('تم سداده', style: Theme.of(context).textTheme.bodySmall),
                  Text(paidAmount, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.secondary)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('المتبقي', style: Theme.of(context).textTheme.bodySmall),
                  Text(remainingAmount, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.error)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              child: const Text('تسجيل دفعة سداد'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmanahHeldView extends StatelessWidget {
  const _AmanahHeldView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('إجمالي الأمانات عندك', style: Theme.of(context).textTheme.titleMedium),
              Text('\$500.00', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.error)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEFEFEF)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock, color: AppTheme.error),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('أمانة صديقي محمد', style: Theme.of(context).textTheme.titleMedium),
                    Text('تم استلامها في 1 يناير', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Text('\$500.00', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}
