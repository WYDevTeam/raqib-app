import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../domain/usecases/get_asset_transactions_usecase.dart';
import '../domain/usecases/add_asset_transaction_usecase.dart';
import '../domain/usecases/add_asset_usecase.dart';
import '../domain/usecases/delete_asset_transaction_usecase.dart';
import '../domain/usecases/delete_asset_usecase.dart';
import '../domain/usecases/get_assets_usecase.dart';
import 'cubit/investments_cubit.dart';

class AddInvestmentScreen extends StatelessWidget {
  const AddInvestmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InvestmentsCubit(
        sl<GetAssetsUseCase>(),
        sl<AddAssetUseCase>(),
        sl<DeleteAssetUseCase>(),
        sl<GetAssetTransactionsUseCase>(),
        sl<AddAssetTransactionUseCase>(),
        sl<DeleteAssetTransactionUseCase>(),
      ),
      child: const _AddInvestmentView(),
    );
  }
}

class _AddInvestmentView extends StatefulWidget {
  const _AddInvestmentView();

  @override
  State<_AddInvestmentView> createState() => _AddInvestmentViewState();
}

class _AddInvestmentViewState extends State<_AddInvestmentView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _symbolController = TextEditingController();
  final _unitController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  String _selectedType = 'gold';
  DateTime _selectedDate = DateTime.now();
  bool _isLoadingPrice = false;

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    _unitController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String get _autoSymbol => switch (_selectedType) {
        'gold' => 'XAU',
        'silver' => 'XAG',
        _ => _symbolController.text.trim().toUpperCase(),
      };

  String get _autoUnit => switch (_selectedType) {
        'gold' => 'غرام',
        'silver' => 'غرام',
        _ => _unitController.text.trim(),
      };

  double get _total {
    final qty = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    return qty * price;
  }

  Future<void> _loadPrice() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoadingPrice = true);
    try {
      final api = sl<ApiService>();
      double price = 0;
      switch (_selectedType) {
        case 'gold':
          final prices = await api.getMetalsPrices();
          price = prices['gold_per_gram'] ?? 0;
        case 'silver':
          final prices = await api.getMetalsPrices();
          price = prices['silver_per_gram'] ?? 0;
        case 'crypto':
          final symbol = _symbolController.text.trim().toUpperCase();
          if (symbol.isNotEmpty) price = await api.getCryptoPrice(symbol);
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

    await context.read<InvestmentsCubit>().createAsset(
          name: _nameController.text.trim(),
          type: _selectedType,
          symbol: _autoSymbol,
          unit: _autoUnit,
          quantity: qty,
          pricePerUnit: price,
          date: _selectedDate,
        );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final showSymbol = _selectedType == 'crypto';
    final showUnit = _selectedType == 'crypto' || _selectedType == 'other';
    final canAutoPrice =
        _selectedType == 'gold' || _selectedType == 'silver' || _selectedType == 'crypto';

    return Scaffold(
      appBar: AppBar(title: const Text('إضافة أصل / استثمار')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Type ──────────────────────────────────────────────────
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'نوع الأصل'),
                items: const [
                  DropdownMenuItem(value: 'gold', child: Text('ذهب')),
                  DropdownMenuItem(value: 'silver', child: Text('فضة')),
                  DropdownMenuItem(
                      value: 'crypto', child: Text('عملات رقمية')),
                  DropdownMenuItem(value: 'other', child: Text('أخرى')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _selectedType = v);
                },
              ),
              const SizedBox(height: 16),

              // ── Name ──────────────────────────────────────────────────
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم',
                  hintText: 'مثال: سبيكة ذهب، BTC',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'أدخل الاسم' : null,
              ),
              const SizedBox(height: 16),

              // ── Symbol (crypto only) ───────────────────────────────────
              if (showSymbol) ...[
                TextFormField(
                  controller: _symbolController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'رمز التداول',
                    hintText: 'مثال: BTCUSDT',
                  ),
                  validator: (v) => showSymbol &&
                          (v == null || v.trim().isEmpty)
                      ? 'أدخل رمز التداول'
                      : null,
                ),
                const SizedBox(height: 16),
              ],

              // ── Unit (crypto / other) ─────────────────────────────────
              if (showUnit) ...[
                TextFormField(
                  controller: _unitController,
                  decoration: const InputDecoration(
                    labelText: 'وحدة القياس',
                    hintText: 'مثال: BTC، متر مربع، قطعة',
                  ),
                  validator: (v) => showUnit &&
                          (v == null || v.trim().isEmpty)
                      ? 'أدخل وحدة القياس'
                      : null,
                ),
                const SizedBox(height: 16),
              ],

              // ── Quantity ──────────────────────────────────────────────
              TextFormField(
                controller: _quantityController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'الكمية',
                  suffixText: _selectedType == 'gold' || _selectedType == 'silver'
                      ? 'غرام'
                      : null,
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'أدخل الكمية';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'كمية غير صالحة';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Price per unit ────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'سعر الوحدة',
                        prefixText: '\$ ',
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'أدخل السعر';
                        final n = double.tryParse(v);
                        if (n == null || n <= 0) return 'سعر غير صالح';
                        return null;
                      },
                    ),
                  ),
                  if (canAutoPrice) ...[
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: OutlinedButton(
                        onPressed: _isLoadingPrice ? null : _loadPrice,
                        child: _isLoadingPrice
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2))
                            : const Text('تحميل'),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // ── Date ─────────────────────────────────────────────────
              GestureDetector(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'تاريخ الشراء',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 24),

              // ── Total ─────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('الإجمالي',
                        style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                      '\$${NumberFormat('#,##0.##').format(_total)}',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: AppTheme.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _save,
                child: const Text('حفظ الأصل'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
