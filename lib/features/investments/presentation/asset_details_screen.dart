import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../domain/entities/asset_entity.dart';
import '../domain/entities/asset_transaction_entity.dart';
import 'cubit/investments_cubit.dart';
import 'cubit/investments_state.dart';
import 'widgets/add_asset_transaction_sheet.dart';

class AssetDetailsScreen extends StatelessWidget {
  final String assetId;

  const AssetDetailsScreen({super.key, required this.assetId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<InvestmentsCubit>()..loadInvestments(),
      child: _AssetDetailsView(assetId: assetId),
    );
  }
}

class _AssetDetailsView extends StatefulWidget {
  final String assetId;
  const _AssetDetailsView({required this.assetId});

  @override
  State<_AssetDetailsView> createState() => _AssetDetailsViewState();
}

class _AssetDetailsViewState extends State<_AssetDetailsView> {
  bool _isRefreshingPrice = false;
  bool _hasAutoFetched = false;

  Future<void> _refreshPrice(AssetEntity asset) async {
    if (_isRefreshingPrice) return;
    setState(() => _isRefreshingPrice = true);
    try {
      final api = sl<ApiService>();
      double price = 0;
      switch (asset.type) {
        case 'gold':
          final prices = await api.getMetalsPrices();
          price = asset.unit == 'غرام'
              ? (prices['gold_per_gram'] ?? 0)
              : (prices['gold_per_ounce'] ?? 0);
        case 'silver':
          final prices = await api.getMetalsPrices();
          price = asset.unit == 'غرام'
              ? (prices['silver_per_gram'] ?? 0)
              : (prices['silver_per_ounce'] ?? 0);
        case 'platinum':
          final prices = await api.getMetalsPrices();
          price = asset.unit == 'غرام'
              ? (prices['platinum_per_gram'] ?? 0)
              : (prices['platinum_per_ounce'] ?? 0);
        case 'palladium':
          final prices = await api.getMetalsPrices();
          price = asset.unit == 'غرام'
              ? (prices['palladium_per_gram'] ?? 0)
              : (prices['palladium_per_ounce'] ?? 0);
        case 'crypto':
          final symbol =
              asset.symbol.isNotEmpty ? asset.symbol : 'BTCUSDT';
          price = await api.getCryptoPrice(symbol);
      }
      if (price > 0 && mounted) {
        await context.read<InvestmentsCubit>().updatePrice(asset.id, price);
      }
    } finally {
      if (mounted) setState(() => _isRefreshingPrice = false);
    }
  }

  void _showAddTransaction(BuildContext context, AssetEntity asset) {
    final cubit = context.read<InvestmentsCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => BlocProvider.value(
        value: cubit,
        child: AddAssetTransactionSheet(asset: asset),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AssetEntity asset,
  ) async {
    final cubit = context.read<InvestmentsCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الأصل'),
        content: Text('هل تريد حذف "${asset.name}" وجميع عملياته؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await cubit.deleteAsset(asset.id);
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InvestmentsCubit, InvestmentsState>(
      listenWhen: (prev, curr) =>
          prev is! InvestmentsLoaded && curr is InvestmentsLoaded,
      listener: (ctx, state) {
        if (!_hasAutoFetched && state is InvestmentsLoaded) {
          _hasAutoFetched = true;
          final asset = state.assets
              .where((a) => a.id == widget.assetId)
              .firstOrNull;
          if (asset != null && asset.type != 'other') {
            _refreshPrice(asset);
          }
        }
      },
      builder: (context, state) {
        if (state is InvestmentsLoading || state is InvestmentsInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is! InvestmentsLoaded) {
          return const Scaffold(body: Center(child: Text('حدث خطأ')));
        }

        final asset =
            state.assets.where((a) => a.id == widget.assetId).firstOrNull;
        if (asset == null) {
          return const Scaffold(body: Center(child: Text('الأصل غير موجود')));
        }

        final txs = state.transactionsByAsset[widget.assetId] ?? [];
        final canRefresh = asset.type != 'other';

        return Scaffold(
          appBar: AppBar(
            title: Text(asset.name),
            actions: [
              if (canRefresh)
                _isRefreshingPrice
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'تحديث السعر',
                        onPressed: () => _refreshPrice(asset),
                      ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                onPressed: () => _confirmDelete(context, asset),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'asset_details_add_fab',
            onPressed: () => _showAddTransaction(context, asset),
            backgroundColor: AppTheme.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildOverviewCard(context, asset, txs),
                const SizedBox(height: 16),
                _buildValuationCard(context, asset),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'سجل العمليات',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (txs.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'لا توجد عمليات بعد',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  )
                else
                  ...txs.map(
                    (tx) => _buildTransactionTile(context, tx, asset.unit),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard(
    BuildContext context,
    AssetEntity asset,
    List<AssetTransactionEntity> txs,
  ) {
    final totalBought =
        txs.where((t) => t.isBuy).fold(0.0, (s, t) => s + t.quantity);
    final totalSold =
        txs.where((t) => !t.isBuy).fold(0.0, (s, t) => s + t.quantity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem(
                context,
                'المشتري',
                '${_fmtQty(totalBought)} ${asset.unit}',
              ),
              _statItem(
                context,
                'المباع',
                '${_fmtQty(totalSold)} ${asset.unit}',
              ),
              _statItem(
                context,
                'المتبقي',
                '${_fmtQty(asset.quantity)} ${asset.unit}',
                highlight: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'صافي التكلفة الحالية',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                _fmt(asset.totalCost),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'متوسط تكلفة الوحدة',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                _fmt(asset.avgCostPerUnit),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValuationCard(BuildContext context, AssetEntity asset) {
    final unrealized = asset.unrealizedPnL;
    final realized = asset.realizedPnL;
    final total = asset.totalPnL;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'سعر الوحدة الحالي',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                _fmt(asset.currentValuePerUnit),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (asset.lastPriceUpdateMs != null) ...[
            const SizedBox(height: 4),
            Text(
              'آخر تحديث: ${_fmtDateTime(asset.lastPriceUpdateMs!)}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'القيمة الحالية',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                _fmt(asset.currentTotalValue),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'ربح محقق',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${realized >= 0 ? '+' : ''}${_fmt(realized)}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: realized >= 0
                                  ? AppTheme.secondary
                                  : AppTheme.error,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: const Color(0xFFEFEFEF)),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'ربح غير محقق',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${unrealized >= 0 ? '+' : ''}${_fmt(unrealized)}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: unrealized >= 0
                                  ? AppTheme.secondary
                                  : AppTheme.error,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  const TextSpan(text: 'إجمالي الربح: '),
                  TextSpan(
                    text:
                        '${total >= 0 ? '+' : ''}${_fmt(total)} (${asset.unrealizedPnLPercent.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      color: total >= 0 ? AppTheme.secondary : AppTheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    AssetTransactionEntity tx,
    String unit,
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
                Text(
                  '${tx.isBuy ? 'شراء' : 'بيع'} ${_fmtQty(tx.quantity)} $unit',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${_fmt(tx.pricePerUnit)}/وحدة • ${DateFormat('dd/MM/yyyy').format(tx.date)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            _fmt(tx.totalAmount),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: tx.isBuy ? AppTheme.textPrimary : AppTheme.secondary,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: AppTheme.error,
              size: 20,
            ),
            onPressed: () =>
                context.read<InvestmentsCubit>().deleteTransaction(tx.id),
          ),
        ],
      ),
    );
  }

  Widget _statItem(
    BuildContext context,
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: highlight ? AppTheme.primary : AppTheme.textPrimary,
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

String _fmt(double v) {
  final abs = NumberFormat('#,##0.##').format(v.abs());
  return '${v < 0 ? '-' : ''}\$$abs';
}

String _fmtQty(double v) => NumberFormat('#,##0.##').format(v);

String _fmtDateTime(int ms) {
  final dt = DateTime.fromMillisecondsSinceEpoch(ms);
  return DateFormat('dd/MM/yyyy HH:mm').format(dt);
}
