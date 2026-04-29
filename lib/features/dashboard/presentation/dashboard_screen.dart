import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import 'widgets/edit_overview_sheet.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, bool> _overviewItems = {
    'الكاش الفعلي': true,
    'الربح الحقيقي (P&L)': true,
    'إجمالي المعادن': true,
    'أمانات عندي': true,
    'الديون المستحقة': false,
    'ميزانية التسوق': false,
  };

  bool _isConservativeMode = true;

  void _showFormulaBuilder() {
    context.push('/dashboard/formula-builder');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('راقب'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/subscription'),
            icon: const Icon(Icons.workspace_premium, color: Color(0xFFFFD700)),
            label: const Text(
              'Pro',
              style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
            ),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700).withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/dashboard/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildNetWorthCard(context),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'نظرة عامة',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.edit_note, color: AppTheme.primary),
                onPressed: () async {
                  final result = await showModalBottomSheet<Map<String, bool>>(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) => EditOverviewSheet(initialItems: _overviewItems),
                  );
                  if (result != null) {
                    setState(() {
                      _overviewItems = result;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDynamicOverviewGrid(context),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'بطاقات مخصصة',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('إضافة معادلة'),
                onPressed: _showFormulaBuilder,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCustomFormulaCard(context, 'الفائض بعد احتياط 10%', '\$280', 'الدخل الفعلي - (المصاريف الفعلية * 1.1)'),
        ],
      ),
    );
  }

  Widget _buildDynamicOverviewGrid(BuildContext context) {
    final Map<String, Widget Function(BuildContext)> widgetMap = {
      'الكاش الفعلي': (ctx) => _buildSummaryCard(ctx, 'الكاش الفعلي', '\$3,500', Icons.attach_money, AppTheme.primary),
      'الربح الحقيقي (P&L)': (ctx) => _buildSummaryCard(ctx, 'الربح الحقيقي (P&L)', '+\$420', Icons.trending_up, AppTheme.secondary),
      'إجمالي المعادن': (ctx) => _buildSummaryCard(ctx, 'إجمالي المعادن', '\$1,200', Icons.diamond, Colors.amber),
      'أمانات عندي': (ctx) => _buildAmanatCard(ctx),
      'الديون المستحقة': (ctx) => _buildDebtsCard(ctx),
      'ميزانية التسوق': (ctx) => _buildBudgetCard(ctx),
    };

    final activeWidgets = _overviewItems.entries
        .where((entry) => entry.value)
        .map((entry) => widgetMap[entry.key]!(context))
        .toList();

    List<Widget> rows = [];
    for (int i = 0; i < activeWidgets.length; i += 2) {
      if (i + 1 < activeWidgets.length) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              children: [
                Expanded(child: activeWidgets[i]),
                const SizedBox(width: 16),
                Expanded(child: activeWidgets[i + 1]),
              ],
            ),
          ),
        );
      } else {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              children: [
                Expanded(child: activeWidgets[i]),
                const SizedBox(width: 16),
                const Spacer(),
              ],
            ),
          ),
        );
      }
    }

    if (rows.isEmpty) {
      return const Center(child: Text('لم يتم اختيار أي بطاقة للظهور', style: TextStyle(color: Colors.grey)));
    }

    return Column(children: rows);
  }

  Widget _buildNetWorthCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF1E56C8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'صافي الثروة الحقيقي',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isConservativeMode ? 'متحفظ' : 'كلي',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: _isConservativeMode,
                      onChanged: (val) {
                        setState(() {
                          _isConservativeMode = val;
                        });
                      },
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppTheme.secondary,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isConservativeMode ? '\$12,450.00' : '\$13,200.00',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white.withValues(alpha: 0.8), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isConservativeMode 
                    ? 'لا يتضمن الديون التي لك (\$750)'
                    : 'يتضمن كافة الديون التي لك',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmanatCard(BuildContext context) {
    return _buildSummaryCard(context, 'أمانات عندي', '\$2,000.00', Icons.lock_outline, AppTheme.error);
  }

  Widget _buildDebtsCard(BuildContext context) {
    return _buildSummaryCard(context, 'الديون المستحقة', '\$1,500.00', Icons.money_off, AppTheme.warning);
  }

  Widget _buildBudgetCard(BuildContext context) {
    return _buildSummaryCard(context, 'ميزانية التسوق', '\$300.00', Icons.shopping_bag_outlined, Colors.purple);
  }

  Widget _buildCustomFormulaCard(BuildContext context, String title, String amount, String formula) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  formula,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.primary),
          ),
        ],
      ),
    );
  }
}
