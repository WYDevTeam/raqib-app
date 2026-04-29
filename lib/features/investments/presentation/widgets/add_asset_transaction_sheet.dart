import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AddAssetTransactionSheet extends StatefulWidget {
  final String assetName;

  const AddAssetTransactionSheet({
    super.key,
    required this.assetName,
  });

  @override
  State<AddAssetTransactionSheet> createState() => _AddAssetTransactionSheetState();
}

class _AddAssetTransactionSheetState extends State<AddAssetTransactionSheet> {
  bool _isBuy = true;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  DateTime? _selectedDate = DateTime.now();

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'تسجيل عملية لـ ${widget.assetName}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Buy/Sell Toggle
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _isBuy = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isBuy ? AppTheme.primary : AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _isBuy ? AppTheme.primary : const Color(0xFFEFEFEF)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'شراء',
                              style: TextStyle(
                                color: _isBuy ? Colors.white : AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _isBuy = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isBuy ? AppTheme.error : AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: !_isBuy ? AppTheme.error : const Color(0xFFEFEFEF)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'بيع',
                              style: TextStyle(
                                color: !_isBuy ? Colors.white : AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'الكمية',
                            hintText: 'مثال: 10',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'سعر الوحدة',
                            prefixText: '\$ ',
                          ),
                        ),
                      ),
                    ],
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
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      // Handle saving the transaction
                      Navigator.pop(context);
                    },
                    child: const Text('حفظ العملية'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
