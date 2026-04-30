import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:raqib/core/theme/app_theme.dart';

import 'cubit/debts_cubit.dart';
import 'cubit/debts_state.dart';

class AddDebtAmanahScreen extends StatefulWidget {
  const AddDebtAmanahScreen({super.key});

  @override
  State<AddDebtAmanahScreen> createState() => _AddDebtAmanahScreenState();
}

class _AddDebtAmanahScreenState extends State<AddDebtAmanahScreen> {
  bool _isDebt = true;
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DebtsCubit, DebtsState>(
      listener: (context, state) {
        if (state is DebtsError) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('إضافة دين أو أمانة')),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('دين لي (سلفته)')),
                      ButtonSegment(value: false, label: Text('أمانة عندي')),
                    ],
                    selected: {_isDebt},
                    onSelectionChanged: (set) =>
                        setState(() => _isDebt = set.first),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return AppTheme.primary;
                        }
                        return AppTheme.background;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.white;
                        }
                        return AppTheme.textSecondary;
                      }),
                      side: WidgetStateProperty.all(
                        const BorderSide(color: Color(0xFFDDE3EE)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'الاسم (الشخص)',
                      hintText: 'مثال: أحمد',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      prefixText: '\$ ',
                      labelText: 'المبلغ الإجمالي',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'مطلوب';
                      if (double.tryParse(v) == null || double.parse(v) <= 0) {
                        return 'مبلغ غير صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'التاريخ'),
                      child: Text(_formatDate(_date)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات (اختياري)',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('حفظ'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  String _formatDate(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final cubit = context.read<DebtsCubit>();
    final name = _nameCtrl.text.trim();
    final amount = double.parse(_amountCtrl.text.trim());
    final note = _noteCtrl.text.trim();

    if (_isDebt) {
      await cubit.addDebt(
        personName: name,
        totalAmount: amount,
        givenDate: _date,
        note: note,
      );
    } else {
      await cubit.addAmanah(
        personName: name,
        amount: amount,
        receivedDate: _date,
        note: note,
      );
    }

    if (mounted && cubit.state is! DebtsError) {
      context.pop(true);
    }
  }
}
