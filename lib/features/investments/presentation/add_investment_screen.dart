import 'package:flutter/material.dart';

class AddInvestmentScreen extends StatefulWidget {
  const AddInvestmentScreen({super.key});

  @override
  State<AddInvestmentScreen> createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends State<AddInvestmentScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة أصل / استثمار'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'نوع الأصل',
                ),
                items: const [
                  DropdownMenuItem(value: 'Gold', child: Text('ذهب')),
                  DropdownMenuItem(value: 'Silver', child: Text('فضة')),
                  DropdownMenuItem(value: 'Crypto', child: Text('عملات رقمية')),
                  DropdownMenuItem(value: 'Other', child: Text('أخرى')),
                ],
                onChanged: (val) {},
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'الاسم أو الوصف',
                  hintText: 'مثال: سبيكة 50 جرام',
                ),
              ),
              const SizedBox(height: 16),
              const TextField(
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  labelText: 'تكلفة الشراء',
                ),
              ),
              const SizedBox(height: 16),
              const TextField(
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'الكمية',
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حفظ الأصل'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
