import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../data/category_service.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  bool _isIncome = false;
  bool _isRecurring = false;
  DateTime? _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة معاملة'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _isIncome = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isIncome ? AppTheme.error : AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: !_isIncome ? AppTheme.error : const Color(0xFFEFEFEF)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'مصروف',
                          style: TextStyle(
                            color: !_isIncome ? Colors.white : AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _isIncome = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isIncome ? AppTheme.secondary : AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _isIncome ? AppTheme.secondary : const Color(0xFFEFEFEF)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'دخل',
                          style: TextStyle(
                            color: _isIncome ? Colors.white : AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: _isIncome ? AppTheme.secondary : AppTheme.error,
                ),
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  labelText: 'المبلغ',
                  labelStyle: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'الوصف',
                  hintText: 'مثال: راتب، إيجار، قهوة',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'الفئة',
                ),
                items: CategoryService.categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) {},
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'التاريخ',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedDate != null 
                        ? '${_selectedDate!.year}/${_selectedDate!.month}/${_selectedDate!.day}' 
                        : 'اختر التاريخ',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('اجعلها متكررة'),
                subtitle: const Text('شهرياً في نفس اليوم'),
                value: _isRecurring,
                onChanged: (val) => setState(() => _isRecurring = val),
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppTheme.primary,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حفظ المعاملة'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
