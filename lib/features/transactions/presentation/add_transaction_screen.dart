import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/category_chip.dart';
import '../domain/entities/category_entity.dart';
import '../domain/entities/transaction_entity.dart';
import 'cubit/transactions_cubit.dart';
import 'cubit/transactions_state.dart';

class AddTransactionScreen extends StatelessWidget {
  final TransactionEntity? transaction;
  const AddTransactionScreen({super.key, this.transaction});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TransactionsCubit>()..loadTransactions(),
      child: _AddTransactionView(transaction: transaction),
    );
  }
}

class _AddTransactionView extends StatefulWidget {
  final TransactionEntity? transaction;
  const _AddTransactionView({this.transaction});

  @override
  State<_AddTransactionView> createState() => _AddTransactionViewState();
}

class _AddTransactionViewState extends State<_AddTransactionView> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  bool _isIncome = false;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;
  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    if (t != null) {
      _isIncome = t.isIncome;
      _amountController.text = t.amount.toString();
      _descController.text = t.description;
      _selectedCategoryId = t.categoryId;
      _selectedDate = t.date;
      _isRecurring = t.isRecurring;
      _frequency = t.frequency ?? RecurrenceFrequency.monthly;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _showCategoryPicker(BuildContext context, List<CategoryEntity> cats) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CategoryPickerSheet(
        categories: cats,
        selectedId: _selectedCategoryId,
        isIncome: _isIncome,
        onSelected: (id) => setState(() => _selectedCategoryId = id),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _isRecurring ? _selectedDate : (_selectedDate.isAfter(today) ? today : _selectedDate),
      firstDate: DateTime(2000),
      lastDate: _isRecurring ? DateTime(2100) : today,
      locale: const Locale('ar'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String _formatDate(DateTime d) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار فئة')),
      );
      return;
    }

    final amount = double.parse(_amountController.text.trim());
    final cubit = context.read<TransactionsCubit>();

    if (_isEditing) {
      final updated = widget.transaction!.copyWith(
        amount: amount,
        categoryId: _selectedCategoryId!,
        description: _descController.text.trim(),
        date: _selectedDate,
        isIncome: _isIncome,
        isRecurring: _isRecurring,
        frequency: _isRecurring ? _frequency : null,
      );
      await cubit.updateTransaction(updated);
    } else {
      final t = TransactionEntity(
        id: const Uuid().v4(),
        amount: amount,
        categoryId: _selectedCategoryId!,
        description: _descController.text.trim(),
        date: _selectedDate,
        isIncome: _isIncome,
        isRecurring: _isRecurring,
        frequency: _isRecurring ? _frequency : null,
      );
      await cubit.addTransaction(t);
    }

    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _confirmDelete(BuildContext context) async {
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
            child: const Text('حذف', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<TransactionsCubit>().deleteTransaction(widget.transaction!.id);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _isIncome ? AppTheme.secondary : AppTheme.error;

    return BlocBuilder<TransactionsCubit, TransactionsState>(
      builder: (context, state) {
        final categories =
            state is TransactionsLoaded ? state.categories : <CategoryEntity>[];
        final selectedCat = categories
            .where((c) => c.id == _selectedCategoryId)
            .firstOrNull;

        return Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? 'تعديل المعاملة' : 'معاملة جديدة'),
            actions: [
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                  tooltip: 'حذف المعاملة',
                  onPressed: () => _confirmDelete(context),
                ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Type toggle ──────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _TypeToggle(
                          label: 'مصروف',
                          isSelected: !_isIncome,
                          color: AppTheme.error,
                          onTap: () =>
                              setState(() => _isIncome = false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TypeToggle(
                          label: 'دخل',
                          isSelected: _isIncome,
                          color: AppTheme.secondary,
                          onTap: () =>
                              setState(() => _isIncome = true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Amount ──────────────────────────────────────────
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                    decoration: InputDecoration(
                      labelText: 'المبلغ',
                      prefixText: '\$ ',
                      prefixStyle: TextStyle(color: accentColor),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'أدخل المبلغ';
                      final n = double.tryParse(v);
                      if (n == null || n <= 0) return 'المبلغ يجب أن يكون أكبر من 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Category ─────────────────────────────────────────
                  GestureDetector(
                    onTap: () => _showCategoryPicker(context, categories),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'الفئة',
                        suffixIcon: const Icon(Icons.chevron_left),
                        errorText: null,
                      ),
                      child: selectedCat != null
                          ? Row(
                              children: [
                                Text(selectedCat.emoji,
                                    style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text(selectedCat.name),
                              ],
                            )
                          : Text(
                              'اختر فئة',
                              style: TextStyle(color: AppTheme.textDisabled),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Date ──────────────────────────────────────────────
                  if (!_isRecurring)
                    GestureDetector(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'تاريخ المعاملة',
                          suffixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(_formatDate(_selectedDate)),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // ── Description ───────────────────────────────────────
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'الوصف (اختياري)',
                      hintText: 'مثال: راتب مارس، قهوة الصباح...',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Recurring ─────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEFEFEF)),
                    ),
                    child: SwitchListTile(
                      title: const Text('اجعلها متكررة'),
                      value: _isRecurring,
                      onChanged: (v) =>
                          setState(() => _isRecurring = v),
                      activeThumbColor: AppTheme.primary,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),

                  if (_isRecurring) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: RecurrenceFrequency.values.map((f) {
                        final sel = _frequency == f;
                        return ChoiceChip(
                          label: Text(f.arabicLabel),
                          selected: sel,
                          onSelected: (_) =>
                              setState(() => _frequency = f),
                          selectedColor:
                              AppTheme.primary.withValues(alpha: 0.15),
                          side: BorderSide(
                              color:
                                  sel ? AppTheme.primary : AppTheme.textDisabled),
                          labelStyle: TextStyle(
                            color: sel
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                            fontWeight: sel
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ── Save button ───────────────────────────────────────
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor),
                    onPressed: () => _save(context),
                    child: Text(
                        _isEditing ? 'حفظ التعديلات' : 'حفظ المعاملة'),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Category picker sheet ─────────────────────────────────────────────────────

class _CategoryPickerSheet extends StatelessWidget {
  final List<CategoryEntity> categories;
  final String? selectedId;
  final bool isIncome;
  final void Function(String) onSelected;

  const _CategoryPickerSheet({
    required this.categories,
    required this.onSelected,
    required this.isIncome,
    this.selectedId,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = categories.where((c) {
      return c.type == CategoryType.both ||
          (isIncome && c.type == CategoryType.income) ||
          (!isIncome && c.type == CategoryType.expense);
    }).toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('اختر الفئة',
                  style: Theme.of(context).textTheme.titleLarge),
              TextButton(
                onPressed: () {
                  final router = GoRouter.of(context);
                  Navigator.pop(context);
                  router.push('/categories');
                },
                child: const Text('إدارة الفئات'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('لا توجد فئات، أضف فئة من إدارة الفئات'),
              ),
            )
          else
            Flexible(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: filtered.map((cat) {
                  return CategoryChip(
                    emoji: cat.emoji,
                    label: cat.name,
                    color: Color(cat.colorValue),
                    isSelected: cat.id == selectedId,
                    onTap: () {
                      onSelected(cat.id);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Type toggle ───────────────────────────────────────────────────────────────

class _TypeToggle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeToggle({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? color : const Color(0xFFEFEFEF)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
