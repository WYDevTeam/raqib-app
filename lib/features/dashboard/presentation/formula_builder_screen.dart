import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/formula_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../domain/entities/dashboard_widget_entity.dart';
import '../domain/usecases/save_custom_widget_usecase.dart';

const _kAvailableVariables = [
  {'key': 'liquid_cash', 'label': 'الكاش الجاهز'},
  {'key': 'gold_value', 'label': 'قيمة الذهب'},
  {'key': 'silver_value', 'label': 'قيمة الفضة'},
  {'key': 'crypto_value', 'label': 'قيمة الكريبتو'},
  {'key': 'total_assets', 'label': 'إجمالي الاستثمارات'},
  {'key': 'real_income', 'label': 'الدخل الحقيقي (الشهر)'},
  {'key': 'real_expenses', 'label': 'المصاريف الحقيقية (الشهر)'},
  {'key': 'real_pnl', 'label': 'الربح الحقيقي (الشهر)'},
  {'key': 'spending_rate', 'label': 'معدل الإنفاق'},
  {'key': 'investment_ratio', 'label': 'نسبة الاستثمار'},
  {'key': 'realized_pnl', 'label': 'الربح المحقق (الكل)'},
  {'key': 'unrealized_pnl', 'label': 'الربح الورقي (الكل)'},
  {'key': 'debts_owed', 'label': 'الديون المستحقة لي'},
  {'key': 'amanah_held', 'label': 'الأمانات عندي'},
  {'key': 'net_worth', 'label': 'صافي الثروة'},
];

// ── Validation helpers ────────────────────────────────────────────────────────

/// Types allowed as the NEXT element given the current formula tail.
/// Possible returned values: 'variable', 'number', 'open_paren', 'operator', 'close_paren'
Set<String> _allowedNextTypes(List<Map<String, dynamic>> elements) {
  if (elements.isEmpty) return {'variable', 'number', 'open_paren'};

  final last = elements.last;
  final type = last['type'] as String;

  if (type == 'variable' || type == 'number') {
    return {'operator', 'close_paren'};
  }
  if (type == 'operator') {
    return {'variable', 'number', 'open_paren'};
  }
  if (type == 'paren') {
    return last['value'] == '('
        ? {'variable', 'number', 'open_paren'}
        : {'operator', 'close_paren'};
  }
  return {};
}

int _openParenCount(List<Map<String, dynamic>> elements) {
  int count = 0;
  for (final e in elements) {
    if (e['type'] == 'paren') {
      count += e['value'] == '(' ? 1 : -1;
    }
  }
  return count;
}

bool _isFormulaValid(List<Map<String, dynamic>> elements) {
  if (elements.isEmpty) return false;
  final last = elements.last;
  final type = last['type'] as String;
  if (type == 'operator') return false;
  if (type == 'paren' && last['value'] == '(') return false;
  return _openParenCount(elements) == 0;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class FormulaBuilderScreen extends StatefulWidget {
  final String? initialTitle;
  final String? initialFormulaJson;

  const FormulaBuilderScreen({
    super.key,
    this.initialTitle,
    this.initialFormulaJson,
  });

  @override
  State<FormulaBuilderScreen> createState() => _FormulaBuilderScreenState();
}

class _FormulaBuilderScreenState extends State<FormulaBuilderScreen> {
  late List<Map<String, dynamic>> _formulaElements;
  late TextEditingController _titleController;
  String _displayFormat = 'number';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    if (widget.initialFormulaJson != null) {
      try {
        _formulaElements = (jsonDecode(widget.initialFormulaJson!) as List)
            .cast<Map<String, dynamic>>();
      } catch (_) {
        _formulaElements = [];
      }
    } else {
      _formulaElements = [];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  bool get _canSave => _isFormulaValid(_formulaElements);

  String? get _saveHint {
    if (_formulaElements.isEmpty) return null;
    final last = _formulaElements.last;
    final type = last['type'] as String;
    if (type == 'operator') return 'المعادلة لا يمكن أن تنتهي بعملية';
    if (type == 'paren' && last['value'] == '(') return 'قوس مفتوح ( بدون إغلاق';
    if (_openParenCount(_formulaElements) != 0) return 'الأقواس غير متوازنة';
    return null;
  }

  String get _preview {
    if (_formulaElements.isEmpty) return '\$0.00';
    if (!_canSave) return '---';
    try {
      final json = jsonEncode(_formulaElements);
      final result = sl<FormulaService>().evaluate(json);
      return _formatValue(result);
    } catch (_) {
      return 'خطأ';
    }
  }

  String _formatValue(double value) {
    final abs = NumberFormat('#,##0.##').format(value.abs());
    final base = '${value < 0 ? '-' : ''}\$$abs';
    return switch (_displayFormat) {
      'signed' => '${value >= 0 ? '+' : ''}${base.replaceFirst('-', '')}',
      'percent' => '${NumberFormat('#,##0.##').format(value)}%',
      _ => base,
    };
  }

  void _addElement(Map<String, dynamic> element) {
    setState(() => _formulaElements.add(element));
  }

  void _showAddElementSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AddElementSheet(
        currentElements: List.unmodifiable(_formulaElements),
        onAdd: (element) {
          _addElement(element);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أدخل اسماً للكارد'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final card = DashboardWidget(
      id: const Uuid().v4(),
      type: 'custom_formula',
      title: title,
      formulaJson: jsonEncode(_formulaElements),
      isVisible: true,
      sortOrder: 0,
      displayFormat: _displayFormat,
    );
    await sl<SaveCustomWidgetUseCase>()(card);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بناء / تعديل المعادلة'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'اسم المعادلة',
                  hintText: 'مثال: كاشي الحقيقي',
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'المعادلة:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._formulaElements.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: _buildFormulaChip(
                                entry.key, entry.value),
                          ),
                        ),
                    ActionChip(
                      label: const Icon(Icons.add, size: 16),
                      onPressed: _showAddElementSheet,
                      backgroundColor: AppTheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Color(0xFFEFEFEF)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'معاينة النتيجة:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      _preview,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: AppTheme.secondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'طريقة العرض:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              _DisplayFormatOption(
                label: 'رقم فقط  (مثال: \$3,500)',
                value: 'number',
                groupValue: _displayFormat,
                onChanged: (v) => setState(() => _displayFormat = v!),
              ),
              _DisplayFormatOption(
                label: 'رقم مع +/-  (مثال: +\$3,500)',
                value: 'signed',
                groupValue: _displayFormat,
                onChanged: (v) => setState(() => _displayFormat = v!),
              ),
              _DisplayFormatOption(
                label: 'نسبة مئوية  (مثال: 35.5%)',
                value: 'percent',
                groupValue: _displayFormat,
                onChanged: (v) => setState(() => _displayFormat = v!),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: (_isSaving || !_canSave) ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('حفظ المعادلة'),
              ),
              if (_saveHint != null) ...[
                const SizedBox(height: 8),
                Text(
                  _saveHint!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.error),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormulaChip(int index, Map<String, dynamic> element) {
    final type = element['type'] as String;
    final label = element['label'] as String? ?? '';
    final isOperator = type == 'operator' || type == 'paren';
    return InkWell(
      onTap: () => setState(() => _formulaElements.removeAt(index)),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isOperator
              ? AppTheme.primary.withValues(alpha: 0.1)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isOperator
                ? AppTheme.primary.withValues(alpha: 0.3)
                : const Color(0xFFEFEFEF),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isOperator ? AppTheme.primary : AppTheme.textPrimary,
                fontWeight:
                    isOperator ? FontWeight.bold : FontWeight.normal,
                fontFamily: isOperator ? 'monospace' : null,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.close,
                size: 14, color: AppTheme.error.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}

// ── Display format radio ──────────────────────────────────────────────────────

class _DisplayFormatOption extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _DisplayFormatOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: AppTheme.primary,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}

// ── Add element bottom sheet ──────────────────────────────────────────────────

class _AddElementSheet extends StatefulWidget {
  final List<Map<String, dynamic>> currentElements;
  final void Function(Map<String, dynamic> element) onAdd;

  const _AddElementSheet({
    required this.currentElements,
    required this.onAdd,
  });

  @override
  State<_AddElementSheet> createState() => _AddElementSheetState();
}

class _AddElementSheetState extends State<_AddElementSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _numberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  Set<String> get _allowed => _allowedNextTypes(widget.currentElements);
  int get _openParens => _openParenCount(widget.currentElements);

  bool get _canAddVariable => _allowed.contains('variable');
  bool get _canAddNumber => _allowed.contains('number');
  bool get _canAddOperator => _allowed.contains('operator');
  bool get _canAddOpenParen => _allowed.contains('open_paren');
  bool get _canAddCloseParen =>
      _allowed.contains('close_paren') && _openParens > 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'إضافة عنصر للمعادلة',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          // ── App-standard tab style ─────────────────────────────────────
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDDE3EE)),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: const BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondary,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'متغيرات'),
                Tab(text: 'عمليات'),
                Tab(text: 'رقم'),
                Tab(text: 'أقواس'),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 220,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVariablesTab(),
                _buildOperatorsTab(),
                _buildNumberTab(),
                _buildParensTab(),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildVariablesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _kAvailableVariables.map((v) {
          final enabled = _canAddVariable;
          return ActionChip(
            label: Text(v['label']!),
            onPressed: enabled
                ? () => widget.onAdd({
                      'type': 'variable',
                      'key': v['key'],
                      'label': v['label'],
                    })
                : null,
            backgroundColor:
                enabled ? AppTheme.surface : AppTheme.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: enabled
                    ? const Color(0xFFEFEFEF)
                    : const Color(0xFFDDE3EE),
              ),
            ),
            labelStyle: TextStyle(
              color: enabled
                  ? AppTheme.textPrimary
                  : AppTheme.textSecondary,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOperatorsTab() {
    final operators = [
      {'value': '+', 'label': '+'},
      {'value': '-', 'label': '-'},
      {'value': '*', 'label': '×'},
      {'value': '/', 'label': '÷'},
    ];
    return Center(
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: operators.map((op) {
          final enabled = _canAddOperator;
          return ActionChip(
            label: Text(
              op['label']!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: enabled
                    ? AppTheme.primary
                    : AppTheme.textSecondary,
              ),
            ),
            onPressed: enabled
                ? () => widget.onAdd({
                      'type': 'operator',
                      'value': op['value'],
                      'label': op['label'],
                    })
                : null,
            backgroundColor: enabled
                ? AppTheme.primary.withValues(alpha: 0.1)
                : AppTheme.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: enabled
                    ? AppTheme.primary.withValues(alpha: 0.3)
                    : const Color(0xFFDDE3EE),
              ),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 12),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNumberTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _numberController,
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
            decoration: const InputDecoration(
              labelText: 'أدخل رقماً ثابتاً',
              hintText: 'مثال: 100 أو -500',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _canAddNumber
                ? () {
                    final val =
                        double.tryParse(_numberController.text.trim());
                    if (val == null) return;
                    widget.onAdd({
                      'type': 'number',
                      'value': val,
                      'label': _numberController.text.trim(),
                    });
                  }
                : null,
            child: const Text('إضافة'),
          ),
          if (!_canAddNumber) ...[
            const SizedBox(height: 8),
            Text(
              'أضف عملية أولاً قبل الرقم',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParensTab() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _parenChip('(', _canAddOpenParen),
          const SizedBox(width: 24),
          _parenChip(')', _canAddCloseParen),
        ],
      ),
    );
  }

  Widget _parenChip(String paren, bool enabled) {
    return ActionChip(
      label: Text(
        paren,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: enabled ? AppTheme.primary : AppTheme.textSecondary,
        ),
      ),
      onPressed: enabled
          ? () => widget
              .onAdd({'type': 'paren', 'value': paren, 'label': paren})
          : null,
      backgroundColor:
          enabled ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: enabled
              ? AppTheme.primary.withValues(alpha: 0.3)
              : const Color(0xFFDDE3EE),
        ),
      ),
      padding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    );
  }
}
