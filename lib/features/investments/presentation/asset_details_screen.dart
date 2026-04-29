import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'widgets/add_asset_transaction_sheet.dart';

class AssetDetailsScreen extends StatefulWidget {
  final String assetName;

  const AssetDetailsScreen({
    super.key,
    required this.assetName,
  });

  @override
  State<AssetDetailsScreen> createState() => _AssetDetailsScreenState();
}

class _AssetDetailsScreenState extends State<AssetDetailsScreen> {
  final TextEditingController _currentPriceController = TextEditingController(text: '100.00'); // Mock initial price

  @override
  void dispose() {
    _currentPriceController.dispose();
    super.dispose();
  }

  void _showAddTransaction() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddAssetTransactionSheet(assetName: widget.assetName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assetName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildOverviewCard(context),
            const SizedBox(height: 16),
            _buildValuationCard(context),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'سجل العمليات',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ElevatedButton.icon(
                  onPressed: _showAddTransaction,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إضافة'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTransactionLogTile(context, 'شراء - 10 غرام', '-\$700.00', 'اليوم', true),
            _buildTransactionLogTile(context, 'شراء - 5 غرام', '-\$340.00', 'أمس', true),
            _buildTransactionLogTile(context, 'بيع - 2 غرام', '+\$150.00', '15/04/2026', false),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context) {
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
              _buildStatItem(context, 'شراء (Bought)', '15.00g'),
              _buildStatItem(context, 'بيع (Sold)', '2.00g'),
              _buildStatItem(context, 'متبقي (Held)', '13.00g', isHighlight: true),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('صافي المستثمر (Net Invested)', style: Theme.of(context).textTheme.bodyMedium),
              Text('\$890.00', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isHighlight ? AppTheme.primary : AppTheme.textPrimary,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildValuationCard(BuildContext context) {
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
          Text('السعر الحالي للوحدة', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _currentPriceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              prefixText: '\$ ',
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('القيمة الحالية (Current Value)', style: Theme.of(context).textTheme.bodyMedium),
              Text('\$1,300.00', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.secondary, fontWeight: FontWeight.bold)),
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
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('ربح محقق (Realized)', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text('+\$50.00', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.secondary)),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: const Color(0xFFEFEFEF)),
                Expanded(
                  child: Column(
                    children: [
                      Text('ربح غير محقق (Unrealized)', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text('+\$360.00', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.secondary)),
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
                    text: '+\$410.00 (+46.0%)',
                    style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionLogTile(BuildContext context, String type, String amount, String date, bool isBuy) {
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
              color: isBuy ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.secondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isBuy ? Icons.add_shopping_cart : Icons.sell,
              color: isBuy ? AppTheme.primary : AppTheme.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isBuy ? AppTheme.textPrimary : AppTheme.secondary,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
            onPressed: () {
              // Delete transaction logic
            },
          ),
        ],
      ),
    );
  }
}
