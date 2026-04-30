import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../data/models/amanah_model.dart';
import '../data/models/debt_model.dart';
import 'cubit/debts_cubit.dart';
import 'cubit/debts_state.dart';

class DebtsAmanahScreen extends StatelessWidget {
  const DebtsAmanahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DebtsCubit>()..load(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('الديون والأمانات'),
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
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    tabs: [
                      Tab(text: 'ديون أعطيتها (ملكك)'),
                      Tab(text: 'أمانات عندي (ليس لك)'),
                    ],
                  ),
                ),
              ),
            ),
          ),
          floatingActionButton: Builder(
            builder: (ctx) => FloatingActionButton(
              heroTag: 'debts_add_fab',
              onPressed: () async {
                final cubit = ctx.read<DebtsCubit>();
                final result = await ctx.push('/debts/add', extra: cubit);
                if (ctx.mounted && result == true) cubit.load();
              },
              backgroundColor: AppTheme.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
          body: BlocBuilder<DebtsCubit, DebtsState>(
            builder: (context, state) {
              return switch (state) {
                DebtsLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                DebtsError(:final message) => Center(child: Text(message)),
                DebtsLoaded() => TabBarView(
                  children: [
                    _DebtsGivenView(state: state),
                    _AmanahHeldView(state: state),
                  ],
                ),
              };
            },
          ),
        ),
      ),
    );
  }
}

class _DebtsGivenView extends StatefulWidget {
  final DebtsLoaded state;
  const _DebtsGivenView({required this.state});

  @override
  State<_DebtsGivenView> createState() => _DebtsGivenViewState();
}

class _DebtsGivenViewState extends State<_DebtsGivenView> {
  bool _showSettled = false;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
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
              Text(
                'إجمالي الديون لك',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '\$${state.totalDebtsRemaining.toStringAsFixed(2)}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppTheme.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (state.activeDebts.isEmpty && state.settledDebts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'لا توجد ديون',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ...state.activeDebts.map((debt) => _buildDebtCard(context, debt)),
        if (state.settledDebts.isNotEmpty) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () => setState(() => _showSettled = !_showSettled),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _showSettled ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ديون مسددة (${state.settledDebts.length})',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          if (_showSettled)
            ...state.settledDebts.map(
              (debt) => _buildDebtCard(context, debt, settled: true),
            ),
        ],
      ],
    );
  }

  Widget _buildDebtCard(
    BuildContext context,
    DebtModel debt, {
    bool settled = false,
  }) {
    final cubit = context.read<DebtsCubit>();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: settled ? AppTheme.background : AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                debt.personName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '\$${debt.totalAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: debt.progress,
              backgroundColor: AppTheme.background,
              color: settled ? AppTheme.secondary : AppTheme.primary,
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
                  Text(
                    'تم سداده',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '\$${debt.paidAmount.toStringAsFixed(2)}',
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: AppTheme.secondary),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('المتبقي', style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    '\$${debt.remainingAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: settled ? AppTheme.textSecondary : AppTheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (!settled) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showPaymentDialog(context, debt, cubit),
                    child: const Text('+ سداد جزئي'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => cubit.settleDebt(debt.id),
                    child: const Text('✓ سدد كاملاً'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showPaymentDialog(
    BuildContext context,
    DebtModel debt,
    DebtsCubit cubit,
  ) {
    final amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('سداد من ${debt.personName}'),
        content: TextField(
          controller: amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: '\$ ',
            labelText: 'المبلغ',
            hintText: 'المتبقي: \$${debt.remainingAmount.toStringAsFixed(2)}',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text);
              if (amount != null && amount > 0) {
                cubit.recordDebtPayment(debt.id, amount);
                Navigator.pop(dialogCtx);
              }
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }
}

class _AmanahHeldView extends StatefulWidget {
  final DebtsLoaded state;
  const _AmanahHeldView({required this.state});

  @override
  State<_AmanahHeldView> createState() => _AmanahHeldViewState();
}

class _AmanahHeldViewState extends State<_AmanahHeldView> {
  bool _showReturned = false;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
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
              Text(
                'إجمالي الأمانات عندك',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '\$${state.totalAmanahRemaining.toStringAsFixed(2)}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppTheme.error),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (state.activeAmanah.isEmpty && state.returnedAmanah.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'لا توجد أمانات',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ...state.activeAmanah.map((a) => _buildAmanahCard(context, a)),
        if (state.returnedAmanah.isNotEmpty) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () => setState(() => _showReturned = !_showReturned),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _showReturned ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'أمانات مُرجعة (${state.returnedAmanah.length})',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          if (_showReturned)
            ...state.returnedAmanah.map(
              (a) => _buildAmanahCard(context, a, returned: true),
            ),
        ],
      ],
    );
  }

  Widget _buildAmanahCard(
    BuildContext context,
    AmanahModel amanah, {
    bool returned = false,
  }) {
    final cubit = context.read<DebtsCubit>();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: returned ? AppTheme.background : AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                amanah.personName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '\$${amanah.amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: amanah.progress,
              backgroundColor: AppTheme.background,
              color: returned ? AppTheme.secondary : AppTheme.error,
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
                  Text(
                    'تم إرجاعه',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '\$${amanah.returnedAmount.toStringAsFixed(2)}',
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: AppTheme.secondary),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'متبقي عندي',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '\$${amanah.remainingAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: returned ? AppTheme.textSecondary : AppTheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (!returned) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showReturnDialog(context, amanah, cubit),
                    child: const Text('+ سداد جزئي'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => cubit.settleAmanah(amanah.id),
                    child: const Text('✓ رجعت كاملاً'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showReturnDialog(
    BuildContext context,
    AmanahModel amanah,
    DebtsCubit cubit,
  ) {
    final amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('إرجاع لـ ${amanah.personName}'),
        content: TextField(
          controller: amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: '\$ ',
            labelText: 'المبلغ',
            hintText: 'المتبقي: \$${amanah.remainingAmount.toStringAsFixed(2)}',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text);
              if (amount != null && amount > 0) {
                cubit.recordAmanahReturn(amanah.id, amount);
                Navigator.pop(dialogCtx);
              }
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }
}
