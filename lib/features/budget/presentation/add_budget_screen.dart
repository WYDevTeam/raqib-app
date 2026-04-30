import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../features/transactions/domain/entities/category_entity.dart';
import 'cubit/budget_cubit.dart';
import 'cubit/budget_state.dart';

class AddBudgetScreen extends StatefulWidget {
  const AddBudgetScreen({super.key});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _amountController = TextEditingController();
  String? _selectedCategoryId;
  bool _applyToAllUpcoming = true;

  late final BudgetCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<BudgetCubit>()..loadBudgets();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _save() {
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار الفئة')),
      );
      return;
    }
    
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال مبلغ صحيح')),
      );
      return;
    }

    _cubit.addBudget(
      categoryId: _selectedCategoryId!,
      monthlyTarget: amount,
      applyToAllUpcoming: _applyToAllUpcoming,
    ).then((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إضافة ميزانية شهرية'),
        ),
        body: BlocBuilder<BudgetCubit, BudgetState>(
          builder: (context, state) {
            if (state is BudgetLoading || state is BudgetInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is BudgetLoaded) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'الفئة',
                          hintText: 'اختر الفئة',
                        ),
                        items: state.availableCategories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat.id,
                            child: Row(
                              children: [
                                Icon(IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons'), color: Color(cat.colorValue), size: 20),
                                const SizedBox(width: 8),
                                Text(cat.name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedCategoryId = val),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          prefixText: '\$ ',
                          labelText: 'الحد الشهري (المبلغ)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('طبق على كل الأشهر القادمة'),
                        value: _applyToAllUpcoming,
                        onChanged: (val) => setState(() => _applyToAllUpcoming = val),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _save,
                        child: const Text('حفظ الميزانية'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return const Center(child: Text('حدث خطأ'));
          },
        ),
      ),
    );
  }
}
