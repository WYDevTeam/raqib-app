import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/app_card.dart';
import '../domain/entities/category_entity.dart';
import '../domain/entities/transaction_entity.dart';
import '../domain/entities/transaction_filter.dart';
import 'cubit/transactions_cubit.dart';
import 'cubit/transactions_state.dart';
import 'widgets/filter_transactions_sheet.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TransactionsCubit>()..loadTransactions(),
      child: const _TransactionsView(),
    );
  }
}

class _TransactionsView extends StatelessWidget {
  const _TransactionsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionsCubit, TransactionsState>(
      builder: (context, state) {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('المعاملات'),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
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
                          fontWeight: FontWeight.bold, fontSize: 13),
                      tabs: [
                        Tab(text: 'سجل المعاملات'),
                        Tab(text: 'المتكررة'),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                if (state is TransactionsLoaded)
                  Badge(
                    isLabelVisible: state.activeFilter != null,
                    child: IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: () => _showFilter(context, state),
                    ),
                  ),
              ],
            ),
            body: switch (state) {
              TransactionsInitial() =>
                const Center(child: CircularProgressIndicator()),
              TransactionsLoading() =>
                const Center(child: CircularProgressIndicator()),
              TransactionsError(:final message) =>
                _ErrorView(message: message),
              TransactionsLoaded() => _LoadedTabView(state: state),
            },
            floatingActionButton: FloatingActionButton(
              onPressed: () => _pushAdd(context, state),
              backgroundColor: AppTheme.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  void _pushAdd(BuildContext context, TransactionsState state) {
    final cubit = context.read<TransactionsCubit>();
    final filter =
        state is TransactionsLoaded ? state.activeFilter : null;
    context
        .push('/transactions/add')
        .then((_) => cubit.loadTransactions(filter: filter));
  }

  void _showFilter(BuildContext context, TransactionsLoaded state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FilterTransactionsSheet(
        categories: state.categories,
        activeFilter: state.activeFilter,
        onApply: (filter) =>
            context.read<TransactionsCubit>().loadTransactions(filter: filter),
      ),
    );
  }
}

// ── Loaded content ──────────────────────────────────────────────────────────

class _LoadedTabView extends StatelessWidget {
  final TransactionsLoaded state;
  const _LoadedTabView({required this.state});

  @override
  Widget build(BuildContext context) {
    final regular = state.transactions.where((t) => !t.isRecurring).toList();
    final recurring =
        state.transactions.where((t) => t.isRecurring).toList();

    return Column(
      children: [
        if (state.activeFilter != null)
          _FilterBanner(
            filter: state.activeFilter!,
            categories: state.categories,
            onClear: () => context
                .read<TransactionsCubit>()
                .loadTransactions(filter: null),
          ),
        Expanded(
          child: TabBarView(
            children: [
              RefreshIndicator(
                onRefresh: () => context
                    .read<TransactionsCubit>()
                    .loadTransactions(filter: state.activeFilter),
                child: regular.isEmpty
                    ? _EmptyState(
                        message: state.activeFilter != null
                            ? 'لا توجد نتائج للفلتر المطبّق'
                            : 'لا توجد معاملات',
                        sub: state.activeFilter != null
                            ? 'جرّب تغيير الفلتر أو إعادة تعيينه'
                            : 'اضغط + لإضافة معاملتك الأولى',
                        icon: state.activeFilter != null
                            ? Icons.search_off
                            : Icons.receipt_long_outlined,
                      )
                    : _TransactionsList(
                        transactions: regular,
                        categories: state.categories,
                      ),
              ),
              RefreshIndicator(
                onRefresh: () => context
                    .read<TransactionsCubit>()
                    .loadTransactions(filter: state.activeFilter),
                child: recurring.isEmpty
                    ? _EmptyState(
                        message: 'لا توجد معاملات متكررة',
                        sub: 'فعّل "اجعلها متكررة" عند إضافة معاملة',
                        icon: Icons.autorenew,
                      )
                    : _RecurringList(
                        transactions: recurring,
                        categories: state.categories,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TransactionsList extends StatelessWidget {
  final List<TransactionEntity> transactions;
  final List<CategoryEntity> categories;
  const _TransactionsList(
      {required this.transactions, required this.categories});

  @override
  Widget build(BuildContext context) {
    final totalIncome = transactions
        .where((t) => t.isIncome)
        .fold<double>(0, (s, t) => s + t.amount);
    final totalExpense = transactions
        .where((t) => !t.isIncome)
        .fold<double>(0, (s, t) => s + t.amount);

    final grouped = <String, List<TransactionEntity>>{};
    for (final t in transactions) {
      grouped.putIfAbsent(_dateKey(t.date), () => []).add(t);
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SummaryRow(totalIncome: totalIncome, totalExpense: totalExpense),
        const SizedBox(height: 20),
        for (final entry in grouped.entries) ...[
          Text(_dateLabel(entry.key),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          for (final t in entry.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TransactionTile(
                transaction: t,
                category: categories
                    .where((c) => c.id == t.categoryId)
                    .firstOrNull,
              ),
            ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _dateLabel(String key) {
    final parts = key.split('-');
    final date = DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'اليوم';
    if (d == today.subtract(const Duration(days: 1))) return 'أمس';
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// ── Transaction tile ─────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final TransactionEntity transaction;
  final CategoryEntity? category;
  const _TransactionTile({required this.transaction, this.category});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TransactionsCubit>();
    return AppCard(
      onTap: () {
        context
            .push('/transactions/add', extra: transaction)
            .then((_) => cubit.loadTransactions());
      },
      onLongPress: () => _confirmDelete(context, cubit),
      child: Row(
        children: [
          _CategoryIcon(category: category),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category?.name ?? 'غير مصنّف',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (transaction.description.isNotEmpty)
                  Text(
                    transaction.description,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AmountText(
                  amount: transaction.amount,
                  isIncome: transaction.isIncome),
              Text(_shortDate(transaction.date),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  String _shortDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    if (day == today) return 'اليوم';
    if (day == today.subtract(const Duration(days: 1))) return 'أمس';
    return '${d.day}/${d.month}/${d.year}';
  }

  Future<void> _confirmDelete(
      BuildContext context, TransactionsCubit cubit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المعاملة'),
        content: const Text('هل أنت متأكد من حذف هذه المعاملة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('حذف', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) cubit.deleteTransaction(transaction.id);
  }
}

class _CategoryIcon extends StatelessWidget {
  final CategoryEntity? category;
  const _CategoryIcon({this.category});

  @override
  Widget build(BuildContext context) {
    final color =
        category != null ? Color(category!.colorValue) : AppTheme.primary;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(category?.emoji ?? '📦',
            style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}

// ── Recurring list ────────────────────────────────────────────────────────────

class _RecurringList extends StatelessWidget {
  final List<TransactionEntity> transactions;
  final List<CategoryEntity> categories;
  const _RecurringList(
      {required this.transactions, required this.categories});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: transactions.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final t = transactions[i];
        final cat =
            categories.where((c) => c.id == t.categoryId).firstOrNull;
        final cubit = context.read<TransactionsCubit>();
        return AppCard(
          borderColor: AppTheme.primary.withValues(alpha: 0.3),
          onTap: () => context
              .push('/transactions/add', extra: t)
              .then((_) => cubit.loadTransactions()),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.autorenew,
                    color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat?.name ?? 'غير مصنّف',
                        style: Theme.of(context).textTheme.titleSmall),
                    Text(
                      '${cat?.emoji ?? ''} ${t.frequency?.arabicLabel ?? 'متكررة'}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.primary),
                    ),
                  ],
                ),
              ),
              AmountText(amount: t.amount, isIncome: t.isIncome),
            ],
          ),
        );
      },
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  const _SummaryRow(
      {required this.totalIncome, required this.totalExpense});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _SummaryCard(
                label: 'إجمالي الدخل',
                amount: totalIncome,
                isIncome: true)),
        const SizedBox(width: 12),
        Expanded(
            child: _SummaryCard(
                label: 'إجمالي المصروف',
                amount: totalExpense,
                isIncome: false)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final bool isIncome;
  const _SummaryCard(
      {required this.label, required this.amount, required this.isIncome});

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? AppTheme.secondary : AppTheme.error;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          AmountText(amount: amount, isIncome: isIncome),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final String sub;
  final IconData icon;
  const _EmptyState(
      {required this.message, required this.sub, required this.icon});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: AppTheme.textDisabled),
              const SizedBox(height: 16),
              Text(message,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(sub,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Filter banner ─────────────────────────────────────────────────────────────

class _FilterBanner extends StatelessWidget {
  final TransactionFilter filter;
  final List<CategoryEntity> categories;
  final VoidCallback onClear;

  const _FilterBanner({
    required this.filter,
    required this.categories,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];

    if (filter.isIncome == true) parts.add('دخل فقط');
    if (filter.isIncome == false) parts.add('مصروف فقط');

    if (filter.startDate != null || filter.endDate != null) {
      final from = filter.startDate != null
          ? '${filter.startDate!.day}/${filter.startDate!.month}'
          : '';
      final to = filter.endDate != null
          ? '${filter.endDate!.day}/${filter.endDate!.month}'
          : '';
      if (from.isNotEmpty && to.isNotEmpty) {
        parts.add('$from → $to');
      } else if (from.isNotEmpty) {
        parts.add('من $from');
      } else {
        parts.add('حتى $to');
      }
    }

    if (filter.categoryIds != null && filter.categoryIds!.isNotEmpty) {
      final names = filter.categoryIds!
          .map((id) => categories.where((c) => c.id == id).firstOrNull?.name)
          .whereType<String>()
          .join('، ');
      if (names.isNotEmpty) parts.add(names);
    }

    return Material(
      color: AppTheme.primary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.filter_list_rounded,
                size: 15, color: AppTheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                parts.isEmpty ? 'فلتر مفعّل' : parts.join(' • '),
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.close, size: 13, color: AppTheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

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
          ElevatedButton(
            onPressed: () =>
                context.read<TransactionsCubit>().loadTransactions(),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
