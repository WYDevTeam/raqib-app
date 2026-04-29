import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/category_chip.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/transaction_filter.dart';

class FilterTransactionsSheet extends StatefulWidget {
  final List<CategoryEntity> categories;
  final TransactionFilter? activeFilter;
  final void Function(TransactionFilter?) onApply;

  const FilterTransactionsSheet({
    super.key,
    required this.categories,
    required this.onApply,
    this.activeFilter,
  });

  @override
  State<FilterTransactionsSheet> createState() =>
      _FilterTransactionsSheetState();
}

class _FilterTransactionsSheetState extends State<FilterTransactionsSheet> {
  DateTime? _startDate;
  DateTime? _endDate;
  final Set<String> _selectedCategoryIds = {};
  bool? _isIncome;

  @override
  void initState() {
    super.initState();
    final f = widget.activeFilter;
    if (f != null) {
      _startDate = f.startDate;
      _endDate = f.endDate;
      _isIncome = f.isIncome;
      if (f.categoryIds != null) _selectedCategoryIds.addAll(f.categoryIds!);
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('ar'),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'اختر';
    return '${d.day}/${d.month}/${d.year}';
  }

  void _apply() {
    final filter = TransactionFilter(
      startDate: _startDate,
      endDate: _endDate,
      categoryIds:
          _selectedCategoryIds.isEmpty ? null : _selectedCategoryIds.toList(),
      isIncome: _isIncome,
    );
    widget.onApply(filter.isEmpty ? null : filter);
    Navigator.pop(context);
  }

  void _reset() => setState(() {
        _startDate = null;
        _endDate = null;
        _selectedCategoryIds.clear();
        _isIncome = null;
      });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textDisabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('تصفية المعاملات',
                    style: Theme.of(context).textTheme.titleLarge),
                TextButton(onPressed: _reset, child: const Text('إعادة تعيين')),
              ],
            ),
            const SizedBox(height: 20),
            Text('النوع', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            Row(
              children: [
                _TypeBtn(
                    label: 'الكل',
                    selected: _isIncome == null,
                    color: AppTheme.primary,
                    onTap: () => setState(() => _isIncome = null)),
                const SizedBox(width: 8),
                _TypeBtn(
                    label: 'دخل',
                    selected: _isIncome == true,
                    color: AppTheme.secondary,
                    onTap: () => setState(() => _isIncome = true)),
                const SizedBox(width: 8),
                _TypeBtn(
                    label: 'مصروف',
                    selected: _isIncome == false,
                    color: AppTheme.error,
                    onTap: () => setState(() => _isIncome = false)),
              ],
            ),
            const SizedBox(height: 20),
            Text('نطاق التاريخ', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _DateTile(
                        label: 'من',
                        value: _formatDate(_startDate),
                        onTap: () => _pickDate(true))),
                const SizedBox(width: 12),
                Expanded(
                    child: _DateTile(
                        label: 'إلى',
                        value: _formatDate(_endDate),
                        onTap: () => _pickDate(false))),
              ],
            ),
            if (widget.categories.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('الفئات', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.categories.map((cat) {
                  final sel = _selectedCategoryIds.contains(cat.id);
                  return CategoryChip(
                    emoji: cat.emoji,
                    label: cat.name,
                    color: Color(cat.colorValue),
                    isSelected: sel,
                    onTap: () => setState(() {
                      if (sel) {
                        _selectedCategoryIds.remove(cat.id);
                      } else {
                        _selectedCategoryIds.add(cat.id);
                      }
                    }),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 28),
            ElevatedButton(onPressed: _apply, child: const Text('تطبيق')),
          ],
        ),
      ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _TypeBtn(
      {required this.label,
      required this.selected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                selected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: selected ? color : AppTheme.textDisabled,
                width: selected ? 1.5 : 1),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? color : AppTheme.textSecondary,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _DateTile(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEFEFEF)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: AppTheme.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
