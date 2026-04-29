import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

import 'widgets/filter_transactions_sheet.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  void _showAddTransaction(BuildContext context) {
    context.push('/transactions/add');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المعاملات اليومية'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDDE3EE)),
                ),
                child: const TabBar(
                  indicator: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textSecondary,
                  dividerColor: Colors.transparent,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    Tab(text: 'سجل المعاملات'),
                    Tab(text: 'المتكررة'),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (context) => const FilterTransactionsSheet(),
                );
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSummaryCards(context),
                const SizedBox(height: 24),
                Text('اليوم', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _buildTransactionTile(
                  context,
                  'قهوة',
                  'Food & Drink',
                  '-\$5.00',
                  false,
                ),
                _buildTransactionTile(
                  context,
                  'راتب شهري',
                  'Income',
                  '+\$3,000.00',
                  true,
                ),
                const SizedBox(height: 24),
                Text('أمس', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _buildTransactionTile(
                  context,
                  'بنزين',
                  'Transport',
                  '-\$45.00',
                  false,
                ),
                _buildTransactionTile(
                  context,
                  'سوبر ماركت',
                  'Groceries',
                  '-\$120.00',
                  false,
                ),
              ],
            ),
            ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildRecurringTile(
                  context,
                  'إيجار المنزل',
                  'سكن',
                  '-\$500.00',
                  false,
                  'يوم 1 من كل شهر',
                ),
                _buildRecurringTile(
                  context,
                  'راتب شهري',
                  'دخل أساسي',
                  '+\$3,000.00',
                  true,
                  'يوم 25 من كل شهر',
                ),
                _buildRecurringTile(
                  context,
                  'اشتراك إنترنت',
                  'خدمات',
                  '-\$40.00',
                  false,
                  'يوم 15 من كل شهر',
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddTransaction(context),
          backgroundColor: AppTheme.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.secondary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الدخل الحقيقي',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '+\$3,000.00',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppTheme.secondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المصاريف الحقيقية',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '-\$170.00',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppTheme.error),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    String title,
    String category,
    String amount,
    bool isIncome,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              color: isIncome
                  ? AppTheme.secondary.withValues(alpha: 0.1)
                  : AppTheme.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? AppTheme.secondary : AppTheme.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(category, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isIncome ? AppTheme.secondary : AppTheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringTile(
    BuildContext context,
    String title,
    String category,
    String amount,
    bool isIncome,
    String schedule,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.autorenew,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '$category • $schedule',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.primary),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isIncome ? AppTheme.secondary : AppTheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
