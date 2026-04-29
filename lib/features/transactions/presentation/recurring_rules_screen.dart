import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/app_card.dart';
import '../domain/entities/category_entity.dart';
import '../domain/entities/recurring_rule_entity.dart';
import '../domain/entities/transaction_filter.dart'; // This was usually in TransactionFilter, but let's check if I actually need it. Wait, I added it previously?
import '../domain/usecases/get_categories_usecase.dart';
import '../domain/utils/recurrence_utils.dart';
import 'cubit/recurring_cubit.dart';
import 'cubit/recurring_state.dart';

class RecurringRulesScreen extends StatelessWidget {
  const RecurringRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RecurringCubit>()..loadRules(),
      child: const _RecurringRulesView(),
    );
  }
}

class _RecurringRulesView extends StatefulWidget {
  const _RecurringRulesView();

  @override
  State<_RecurringRulesView> createState() => _RecurringRulesViewState();
}

class _RecurringRulesViewState extends State<_RecurringRulesView> {
  List<CategoryEntity> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final result = await sl<GetCategoriesUseCase>()();
    result.fold((_) {}, (cats) {
      if (mounted) setState(() => _categories = cats);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المعاملات المتكررة'),
        centerTitle: true,
      ),
      body: BlocBuilder<RecurringCubit, RecurringState>(
        builder: (context, state) {
          if (state is RecurringInitial || state is RecurringProcessing) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is RecurringError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<RecurringCubit>().loadRules(),
            );
          }
          if (state is RecurringLoaded) {
            final active = state.activeRules;
            final inactive = state.inactiveRules;

            if (active.isEmpty && inactive.isEmpty) {
              return _EmptyView();
            }

            return RefreshIndicator(
              onRefresh: () => context.read<RecurringCubit>().loadRules(),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Stats banner ─────────────────────────────────────────
                  _StatsBanner(active: active.length, inactive: inactive.length),
                  const SizedBox(height: 24),

                  // ── Active rules ─────────────────────────────────────────
                  if (active.isNotEmpty) ...[
                    _SectionHeader(
                      label: 'القواعد النشطة',
                      icon: Icons.autorenew,
                      color: AppTheme.secondary,
                      count: active.length,
                    ),
                    const SizedBox(height: 12),
                    ...active.map((rule) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RuleCard(
                            rule: rule,
                            categories: _categories,
                            onStop: () => _confirmStop(context, rule),
                          ),
                        )),
                  ],

                  // ── Inactive rules ───────────────────────────────────────
                  if (inactive.isNotEmpty) ...[
                    if (active.isNotEmpty) const SizedBox(height: 8),
                    _SectionHeader(
                      label: 'القواعد المتوقفة',
                      icon: Icons.pause_circle_outline,
                      color: AppTheme.textSecondary,
                      count: inactive.length,
                    ),
                    const SizedBox(height: 12),
                    ...inactive.map((rule) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RuleCard(
                            rule: rule,
                            categories: _categories,
                            onResume: () =>
                                context.read<RecurringCubit>().resumeRule(rule),
                          ),
                        )),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Future<void> _confirmStop(
      BuildContext context, RecurringRuleEntity rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إيقاف القاعدة المتكررة'),
        content: const Text(
          'سيتم إيقاف توليد المعاملات الجديدة.\n'
          'المعاملات المُولَّدة سابقاً لن تُحذَف.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'إيقاف',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<RecurringCubit>().stopRule(rule);
    }
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _StatsBanner extends StatelessWidget {
  final int active;
  final int inactive;
  const _StatsBanner({required this.active, required this.inactive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.12),
            AppTheme.secondary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          _StatItem(
            count: active,
            label: 'نشطة',
            color: AppTheme.secondary,
            icon: Icons.check_circle_outline,
          ),
          const SizedBox(width: 20),
          Container(width: 1, height: 40, color: AppTheme.textDisabled),
          const SizedBox(width: 20),
          _StatItem(
            count: inactive,
            label: 'متوقفة',
            color: AppTheme.textSecondary,
            icon: Icons.pause_circle_outline,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;
  const _StatItem(
      {required this.count,
      required this.label,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int count;
  const _SectionHeader(
      {required this.label,
      required this.icon,
      required this.color,
      required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: color)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }
}

class _RuleCard extends StatelessWidget {
  final RecurringRuleEntity rule;
  final List<CategoryEntity> categories;
  final VoidCallback? onStop;
  final VoidCallback? onResume;

  const _RuleCard({
    required this.rule,
    required this.categories,
    this.onStop,
    this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final cat =
        categories.where((c) => c.id == rule.categoryId).firstOrNull;
    final isActive = rule.isActive;
    final accentColor = isActive ? AppTheme.primary : AppTheme.textDisabled;

    // Next occurrence (only for active rules)
    DateTime? nextOcc;
    if (isActive) {
      final anchor = rule.lastGeneratedDate ?? rule.startDate;
      nextOcc = RecurrenceUtils.nextOccurrenceAfter(anchor, rule.frequency);
      // Clamp to endDate
      if (rule.endDate != null && nextOcc.isAfter(rule.endDate!)) {
        nextOcc = null;
      }
    }

    final isExpired = rule.endDate != null &&
        rule.endDate!.isBefore(DateTime.now());

    return Opacity(
      opacity: isActive ? 1.0 : 0.65,
      child: AppCard(
        borderColor: accentColor.withValues(alpha: 0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ─────────────────────────────────────────────
            Row(
              children: [
                // Category icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      cat?.emoji ?? '📋',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              cat?.name ?? 'غير مصنّف',
                              style: Theme.of(context).textTheme.titleSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.textDisabled
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'متوقفة',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textSecondary),
                              ),
                            ),
                          if (isActive && isExpired)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.warning.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'منتهية',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.warning),
                              ),
                            ),
                        ],
                      ),
                      if (rule.description.isNotEmpty)
                        Text(
                          rule.description,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                AmountText(amount: rule.amount, isIncome: rule.isIncome),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Details row ─────────────────────────────────────────────
            Row(
              children: [
                _DetailChip(
                  icon: Icons.repeat,
                  label: rule.frequency.arabicLabel,
                  color: accentColor,
                ),
                const SizedBox(width: 8),
                _DetailChip(
                  icon: Icons.calendar_today_outlined,
                  label:
                      'بدأ: ${RecurrenceUtils.formatDate(rule.startDate)}',
                  color: accentColor,
                ),
              ],
            ),
            if (nextOcc != null) ...[
              const SizedBox(height: 8),
              _DetailChip(
                icon: Icons.schedule,
                label: 'القادم: ${RecurrenceUtils.formatDate(nextOcc)}',
                color: AppTheme.secondary,
              ),
            ],
            if (rule.endDate != null) ...[
              const SizedBox(height: 8),
              _DetailChip(
                icon: Icons.event_busy_outlined,
                label:
                    'ينتهي: ${RecurrenceUtils.formatDate(rule.endDate!)}',
                color: isExpired ? AppTheme.error : AppTheme.textSecondary,
              ),
            ],
            if (rule.lastGeneratedDate != null) ...[
              const SizedBox(height: 8),
              _DetailChip(
                icon: Icons.check_circle_outline,
                label:
                    'آخر توليد: ${RecurrenceUtils.formatDate(rule.lastGeneratedDate!)}',
                color: AppTheme.textSecondary,
              ),
            ],

            const SizedBox(height: 14),

            // ── Action button ───────────────────────────────────────────
            if (onStop != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onStop,
                  icon: const Icon(Icons.stop_circle_outlined, size: 18),
                  label: const Text('إيقاف القاعدة'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                    padding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            if (onResume != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onResume,
                  icon: const Icon(Icons.play_circle_outline, size: 18),
                  label: const Text('استئناف القاعدة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    padding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _DetailChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.autorenew,
              size: 64,
              color: AppTheme.textDisabled.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('لا توجد معاملات متكررة',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'أضِف معاملة وفعّل "اجعلها متكررة"',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

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
          ElevatedButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }
}
