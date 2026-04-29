import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

class InvestmentsScreen extends StatelessWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الاستثمارات والأصول'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'محفظة الأصول'),
              Tab(text: 'سجل العمليات'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.push('/investments/add'),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildTotalCard(context),
                const SizedBox(height: 24),
                Text(
                  'محفظة الأصول',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildAssetCard(
                  context,
                  name: 'ذهب (Gold)',
                  icon: Icons.diamond,
                  iconColor: Colors.amber,
                  quantity: '50 غرام',
                  cost: '\$3,500.00',
                  currentValue: '\$4,200.00',
                  pnl: '+\$700.00',
                  isPositivePnl: true,
                ),
                _buildAssetCard(
                  context,
                  name: 'فضة (Silver)',
                  icon: Icons.diamond_outlined,
                  iconColor: Colors.grey,
                  quantity: '100 غرام',
                  cost: '\$100.00',
                  currentValue: '\$90.00',
                  pnl: '-\$10.00',
                  isPositivePnl: false,
                ),
                _buildAssetCard(
                  context,
                  name: 'بتكوين (BTC)',
                  icon: Icons.currency_bitcoin,
                  iconColor: Colors.orange,
                  quantity: '0.05 BTC',
                  cost: '\$2,000.00',
                  currentValue: '\$3,100.00',
                  pnl: '+\$1,100.00',
                  isPositivePnl: true,
                ),
                _buildAssetCard(
                  context,
                  name: 'شقة سكنية (أصل مخصص)',
                  icon: Icons.home,
                  iconColor: AppTheme.primary,
                  quantity: '1 عقار',
                  cost: '\$50,000.00',
                  currentValue: '\$65,000.00',
                  pnl: '+\$15,000.00',
                  isPositivePnl: true,
                ),
              ],
            ),
            ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildTransactionLogTile(
                  context,
                  'ذهب (Gold)',
                  'شراء - 10 غرام',
                  '-\$700.00',
                  'اليوم',
                  true,
                ),
                _buildTransactionLogTile(
                  context,
                  'بتكوين (BTC)',
                  'شراء - 0.01 BTC',
                  '-\$600.00',
                  'أمس',
                  true,
                ),
                _buildTransactionLogTile(
                  context,
                  'أسهم',
                  'بيع',
                  '+\$1,200.00',
                  '15/04/2026',
                  false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(BuildContext context) {
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
          Text(
            'إجمالي قيمة الأصول',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '\$72,390.00',
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    'التكلفة (Cost)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$55,600.00',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              Container(width: 1, height: 40, color: const Color(0xFFEFEFEF)),
              Column(
                children: [
                  Text(
                    'الربح الورقي',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+\$16,790.00',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.secondary,
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
    BuildContext context, {
    required String name,
    required IconData icon,
    required Color iconColor,
    required String quantity,
    required String cost,
    required String currentValue,
    required String pnl,
    required bool isPositivePnl,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          context.push('/investments/details', extra: {'assetName': name});
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
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      quantity,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                currentValue,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                    Text(
                      'التكلفة',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(cost, style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'الربح/الخسارة',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      pnl,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isPositivePnl
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
    BuildContext context,
    String assetName,
    String type,
    String amount,
    String date,
    bool isBuy,
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
              color: isBuy
                  ? AppTheme.primary.withValues(alpha: 0.1)
                  : AppTheme.secondary.withValues(alpha: 0.1),
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
                Text(assetName, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '$type • $date',
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
        ],
      ),
    );
  }
}
