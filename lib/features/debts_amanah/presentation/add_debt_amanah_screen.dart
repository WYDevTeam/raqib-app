import 'package:flutter/material.dart';

class AddDebtAmanahScreen extends StatefulWidget {
  const AddDebtAmanahScreen({super.key});

  @override
  State<AddDebtAmanahScreen> createState() => _AddDebtAmanahScreenState();
}

class _AddDebtAmanahScreenState extends State<AddDebtAmanahScreen> {
  bool _isDebt = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة دين أو أمانة'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('دين لي (سلفته)')),
                  ButtonSegment(value: false, label: Text('أمانة عندي')),
                ],
                selected: {_isDebt},
                onSelectionChanged: (set) {
                  setState(() => _isDebt = set.first);
                },
              ),
              const SizedBox(height: 24),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'الاسم (الشخص)',
                  hintText: 'مثال: أحمد',
                ),
              ),
              const SizedBox(height: 16),
              const TextField(
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  labelText: 'المبلغ الإجمالي',
                ),
              ),
              const SizedBox(height: 16),
              const TextField(
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  labelText: 'تم سداده (اختياري)',
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
