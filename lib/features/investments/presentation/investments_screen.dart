import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../domain/entities/asset_entity.dart';
import '../domain/entities/asset_transaction_entity.dart';
import 'cubit/investments_cubit.dart';
import 'cubit/investments_state.dart';

class InvestmentsScreen extends StatelessWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<InvestmentsCubit>()..loadInvestments(),
      child: const _InvestmentsView(),
    );
  }
}

class _InvestmentsView extends StatelessWidget {
  const _InvestmentsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvestmentsCubit, InvestmentsState>(
      builder: (context, state) {
        final loaded = state is InvestmentsLoaded ? state : null;
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('الاستثمارات والأصول'),
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
                      labelStyle:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      tabs: [
                        Tab(text: 'محفظة الأصول'),
                        Tab(text: 'سجل العمليات'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                final cubit = context.read<InvestmentsCubit>();
                context.push('/investments/add').then((_) {
                  if (context.mounted) cubit.loadInvestments();
                });
              },
              backgroundColor: AppTheme.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
            body: state is InvestmentsLoading && loaded == null
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    children: [
                      _buildPortfolioTab(context, loaded),
                      _buildTransactionsTab(context, loaded),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildPortfolioTab(BuildContext context, InvestmentsLoaded? state) {
    return RefreshIndicator(
      onRefresh: () => context.read<InvestmentsCubit>().refresh(),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildTotalCard(context, state),
          const SizedBox(height: 24),
          Text('محفظة الأصول',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          if (state == null || state.assets.isEmpty)
            _buildEmpty(context)
          else
            ...state.assets.map(
              (asset) => _buildAssetCard(context, asset, state),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab(
      BuildContext context, InvestmentsLoaded? state) {
    final txs = state?.allTransactions ?? [];
    if (txs.isEmpty) {
      return _buildEmpty(context, message: 'لا توجد عمليات بعد');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: txs.length,
      itemBuilder: (context, i) {
        final tx = txs[i];
        final assetName = state?.assets
                .where((a) => a.id == tx.assetId)
                .firstOrNull
                ?.name ??
            '';
        return _buildTransactionLogTile(context, tx, assetName);
      },
    );
  }

  Widget _buildTotalCard(BuildContext context, InvestmentsLoaded? state) {
    final totalValue = state?.totalCurrentValue ?? 0;
    final totalCost = state?.totalCost ?? 0;
    final unrealized = state?.totalUnrealizedPnL ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEFEFEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text('إجمالي قيمة الأصول',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          Text(
            state == null ? '---' : _fmt(totalValue),
            style: Theme.of(context)
                .textTheme
                .displaySmall
                ?.copyWith(color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text('التكلفة',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(state == null ? '---' : _fmt(totalCost),
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              Container(
                  width: 1, height: 40, color: const Color(0xFFEFEFEF)),
              Column(
                children: [
                  Text('الربح الورقي',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    state == null
                        ? '---'
                        : '${unrealized >= 0 ? '+' : ''}${_fmt(unrealized)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: unrealized >= 0
                              ? AppTheme.secondary
                              : AppTheme.error,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssetCard(
      BuildContext context, AssetEntity asset, InvestmentsLoaded state) {
    final icon = _iconForType(asset.type);
    final color = _colorForType(asset.type);
    final pnl = asset.unrealizedPnL;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          final cubit = context.read<InvestmentsCubit>();
          context.push('/investments/details', extra: asset.id).then((_) {
            if (context.mounted) cubit.loadInvestments();
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEFEFEF)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(asset.name,
                            style:
                                Theme.of(context).textTheme.titleMedium),
                        Text(
                          '${_fmtQty(asset.quantity)} ${asset.unit}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _fmt(asset.currentTotalValue),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('التكلفة',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text(_fmt(asset.totalCost),
                            style: Theme.of(context).textTheme.titleSmall),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('الربح/الخسارة',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text(
                          '${pnl >= 0 ? '+' : ''}${_fmt(pnl)} (${asset.unrealizedPnLPercent.toStringAsFixed(1)}%)',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                color: pnl >= 0
                                    ? AppTheme.secondary
                                    : AppTheme.error,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionLogTile(
      BuildContext context, AssetTransactionEntity tx, String assetName) {
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
              color: tx.isBuy
                  ? AppTheme.primary.withValues(alpha: 0.1)
                  : AppTheme.secondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              tx.isBuy ? Icons.add_shopping_cart : Icons.sell,
              color: tx.isBuy ? AppTheme.primary : AppTheme.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(assetName,
                    style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '${tx.isBuy ? 'شراء' : 'بيع'} ${_fmtQty(tx.quantity)} • ${DateFormat('dd/MM/yyyy').format(tx.date)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            _fmt(tx.totalAmount),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: tx.isBuy
                      ? AppTheme.textPrimary
                      : AppTheme.secondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, {String? message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(Icons.account_balance_wallet_outlined,
                size: 64, color: AppTheme.textDisabled),
            const SizedBox(height: 16),
            Text(
              message ?? 'لا توجد أصول بعد',
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 8),
            const Text(
              'اضغط + لإضافة أصل جديد',
              style:
                  TextStyle(color: AppTheme.textDisabled, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconForType(String type) => switch (type) {
      'gold' => Icons.diamond,
      'silver' => Icons.diamond_outlined,
      'platinum' => Icons.circle,
      'palladium' => Icons.circle_outlined,
      'crypto' => Icons.currency_bitcoin,
      _ => Icons.account_balance,
    };

Color _colorForType(String type) => switch (type) {
      'gold' => Colors.amber,
      'silver' => Colors.blueGrey,
      'platinum' => const Color(0xFF78909C),
      'palladium' => const Color(0xFF546E7A),
      'crypto' => Colors.orange,
      _ => AppTheme.primary,
    };

String _fmt(double v) {
  final abs = NumberFormat('#,##0.##').format(v.abs());
  return '${v < 0 ? '-' : ''}\$$abs';
}

String _fmtQty(double v) => NumberFormat('#,##0.##').format(v);
