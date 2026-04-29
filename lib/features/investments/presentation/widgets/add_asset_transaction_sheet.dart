import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/services/api_service.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../domain/entities/asset_entity.dart';
import '../../domain/entities/asset_transaction_entity.dart';
import '../cubit/investments_cubit.dart';

class AddAssetTransactionSheet extends StatefulWidget {
  final AssetEntity asset;

  const AddAssetTransactionSheet({super.key, required this.asset});

  @override
  State<AddAssetTransactionSheet> createState() =>
      _AddAssetTransactionSheetState();
}

class _AddAssetTransactionSheetState
    extends State<AddAssetTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  bool _isBuy = true;
  DateTime _selectedDate = DateTime.now();
  bool _isLoadingPrice = false;

  @override
  void initState() {
    super.initState();
    _priceController.text =
        widget.asset.currentValuePerUnit.toStringAsFixed(4);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  double get _total {
    final qty = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    return qty * price;
  }

  bool get _canAutoPrice => widget.asset.type != 'other';

  Future<void> _loadPrice() async {
    setState(() => _isLoadingPrice = true);
    try {
      final api = sl<ApiService>();
      double price = 0;
      switch (widget.asset.type) {
        case 'gold':
          final prices = await api.getMetalsPrices();
          price = widget.asset.unit == 'غرام'
              ? (prices['gold_per_gram'] ?? 0)
              : (prices['gold_per_ounce'] ?? 0);
        case 'silver':
          final prices = await api.getMetalsPrices();
          price = widget.asset.unit == 'غرام'
              ? (prices['silver_per_gram'] ?? 0)
              : (prices['silver_per_ounce'] ?? 0);
        case 'crypto':
          final symbol = widget.asset.symbol.isNotEmpty
              ? widget.asset.symbol
              : 'BTCUSDT';
          price = await api.getCryptoPrice(symbol);
      }
      if (price > 0 && mounted) {
        _priceController.text = price.toStringAsFixed(4);
      }
    } finally {
      if (mounted) setState(() => _isLoadingPrice = false);
    }
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final qty = double.parse(_quantityController.text.trim());
    final price = double.parse(_priceController.text.trim());

    if (!_isBuy && qty > widget.asset.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يمكن بيع أكثر من الكمية المتاحة'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final tx = AssetTransactionEntity(
      id: const Uuid().v4(),
      assetId: widget.asset.id,
      isBuy: _isBuy,
      quantity: qty,
      pricePerUnit: price,
      date: _selectedDate,
    );
    await context.read<InvestmentsCubit>().addTransaction(tx);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'عملية على ${widget.asset.name}',
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
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Buy / Sell toggle ───────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _isBuy = true),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _isBuy
                                      ? AppTheme.primary
                                      : AppTheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _isBuy
                                        ? AppTheme.primary
                                        : const Color(0xFFEFEFEF),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'شراء',
                                  style: TextStyle(
                                    color: _isBuy
                                        ? Colors.white
                                        : AppTheme.textPrimary,
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !_isBuy
                                      ? AppTheme.error
                                      : AppTheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: !_isBuy
                                        ? AppTheme.error
                                        : const Color(0xFFEFEFEF),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'بيع',
                                  style: TextStyle(
                                    color: !_isBuy
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Quantity + Price ────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _quantityController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: InputDecoration(
                                labelText: 'الكمية',
                                suffixText: widget.asset.unit,
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'أدخل الكمية';
                                final n = double.tryParse(v);
                                if (n == null || n <= 0) return 'غير صالح';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'سعر الوحدة',
                                prefixText: '\$ ',
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'أدخل السعر';
                                final n = double.tryParse(v);
                                if (n == null || n <= 0) return 'غير صالح';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      if (_canAutoPrice) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed:
                                _isLoadingPrice ? null : _loadPrice,
                            icon: _isLoadingPrice
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.refresh, size: 16),
                            label: const Text('تحميل السعر الحالي'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // ── Date ───────────────────────────────────────
                      GestureDetector(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'التاريخ',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(DateFormat('dd/MM/yyyy')
                              .format(_selectedDate)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Total ───────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('الإجمالي',
                                style:
                                    Theme.of(context).textTheme.bodyMedium),
                            Text(
                              '\$${NumberFormat('#,##0.##').format(_total)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: AppTheme.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _save,
                        child: const Text('حفظ العملية'),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

