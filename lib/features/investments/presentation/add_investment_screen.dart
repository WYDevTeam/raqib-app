import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import 'cubit/investments_cubit.dart';

// ── Pro gating ────────────────────────────────────────────────────────────────

const _kProTypes = {'platinum', 'palladium'};
const _kFreeCoins = {'BTCUSDT', 'ETHUSDT', 'BNBUSDT'};

// ── Popular crypto pairs ──────────────────────────────────────────────────────

typedef _CoinInfo = ({String symbol, String name, String unit});

const _kCoins = <_CoinInfo>[
  (symbol: 'BTCUSDT', name: 'Bitcoin', unit: 'BTC'),
  (symbol: 'ETHUSDT', name: 'Ethereum', unit: 'ETH'),
  (symbol: 'BNBUSDT', name: 'BNB', unit: 'BNB'),
  (symbol: 'SOLUSDT', name: 'Solana', unit: 'SOL'),
  (symbol: 'XRPUSDT', name: 'XRP', unit: 'XRP'),
  (symbol: 'DOGEUSDT', name: 'Dogecoin', unit: 'DOGE'),
  (symbol: 'ADAUSDT', name: 'Cardano', unit: 'ADA'),
  (symbol: 'AVAXUSDT', name: 'Avalanche', unit: 'AVAX'),
  (symbol: 'DOTUSDT', name: 'Polkadot', unit: 'DOT'),
  (symbol: 'LINKUSDT', name: 'Chainlink', unit: 'LINK'),
  (symbol: 'LTCUSDT', name: 'Litecoin', unit: 'LTC'),
  (symbol: 'UNIUSDT', name: 'Uniswap', unit: 'UNI'),
  (symbol: 'MATICUSDT', name: 'Polygon', unit: 'MATIC'),
  (symbol: 'TONUSDT', name: 'TON', unit: 'TON'),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class AddInvestmentScreen extends StatelessWidget {
  const AddInvestmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<InvestmentsCubit>(),
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
  _CoinInfo? _selectedCoin; // null = custom
  DateTime _selectedDate = DateTime.now();
  bool _isLoadingPrice = false;
  final _typeFieldKey = GlobalKey<FormFieldState<String>>();

  static const _metalTypes = {'gold', 'silver', 'platinum', 'palladium'};

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    _unitController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String get _autoName => switch (_selectedType) {
    'gold' => 'ذهب',
    'silver' => 'فضة',
    'platinum' => 'بلاتين',
    'palladium' => 'بلاديوم',
    'crypto' => _selectedCoin?.name ?? _symbolController.text.trim(),
    _ => _nameController.text.trim(),
  };

  String get _autoSymbol => switch (_selectedType) {
    'gold' => 'XAU',
    'silver' => 'XAG',
    'platinum' => 'XPT',
    'palladium' => 'XPD',
    'crypto' =>
      _selectedCoin?.symbol ?? _symbolController.text.trim().toUpperCase(),
    _ => '',
  };

  String get _autoUnit => switch (_selectedType) {
    'gold' || 'silver' || 'platinum' || 'palladium' => 'غرام',
    'crypto' => _selectedCoin?.unit ?? _unitController.text.trim(),
    _ => _unitController.text.trim(),
  };

  bool get _isMetal => _metalTypes.contains(_selectedType);
  bool get _canAutoPrice => _isMetal || _selectedType == 'crypto';

  double get _total {
    final qty = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    return qty * price;
  }

  Future<void> _showCryptoPicker() async {
    FocusScope.of(context).unfocus();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CryptoPickerSheet(
        selected: _selectedCoin,
        customSymbol: _symbolController.text,
        onProRequired: () => context.push('/subscription'),
        onSelected: (coin, customSymbol) {
          setState(() {
            _selectedCoin = coin;
            if (coin != null) {
              _symbolController.text = coin.symbol;
              _unitController.text = coin.unit;
            } else if (customSymbol != null) {
              _symbolController.text = customSymbol.toUpperCase();
              // strip USDT suffix for unit display
              _unitController.text = customSymbol.toUpperCase().replaceAll(
                RegExp(r'USDT$'),
                '',
              );
            }
          });
        },
      ),
    );
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
        case 'platinum':
          final prices = await api.getMetalsPrices();
          price = prices['platinum_per_gram'] ?? 0;
        case 'palladium':
          final prices = await api.getMetalsPrices();
          price = prices['palladium_per_gram'] ?? 0;
        case 'crypto':
          final symbol =
              _selectedCoin?.symbol ??
              _symbolController.text.trim().toUpperCase();
          if (symbol.isNotEmpty) price = await api.getCryptoPrice(symbol);
      }
      if (price > 0 && mounted) {
        _priceController.text = price.toStringAsFixed(4);
        setState(() {});
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
      name: _autoName,
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
    final showCryptoPicker = _selectedType == 'crypto';
    final showOtherUnit = _selectedType == 'other';

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
                key: _typeFieldKey,
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'نوع الأصل'),
                items: [
                  const DropdownMenuItem(value: 'gold', child: Text('ذهب')),
                  const DropdownMenuItem(value: 'silver', child: Text('فضة')),
                  DropdownMenuItem(
                    value: 'platinum',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [const Text('بلاتين'), _ProBadge()],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'palladium',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [const Text('بلاديوم'), _ProBadge()],
                    ),
                  ),
                  const DropdownMenuItem(
                    value: 'crypto',
                    child: Text('عملات رقمية'),
                  ),
                  const DropdownMenuItem(value: 'other', child: Text('أخرى')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  if (_kProTypes.contains(v)) {
                    // Revert FormField internal state back to current selection
                    _typeFieldKey.currentState?.didChange(_selectedType);
                    context.push('/subscription');
                    return;
                  }
                  setState(() {
                    _selectedType = v;
                    _selectedCoin = null;
                    _symbolController.clear();
                    _unitController.clear();
                    _priceController.clear();
                  });
                },
              ),
              const SizedBox(height: 16),

              // ── Name (other only) ─────────────────────────────────────
              if (_selectedType == 'other') ...[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم',
                    hintText: 'مثال: عقار، سيارة',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'أدخل الاسم' : null,
                ),
                const SizedBox(height: 16),
              ],

              // ── Crypto picker ─────────────────────────────────────────
              if (showCryptoPicker) ...[
                GestureDetector(
                  onTap: _showCryptoPicker,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'العملة',
                      suffixIcon: Icon(Icons.chevron_left),
                    ),
                    child: Text(
                      _selectedCoin != null
                          ? '${_selectedCoin!.name} (${_selectedCoin!.unit})'
                          : _symbolController.text.isNotEmpty
                          ? _symbolController.text
                          : 'اختر العملة',
                      style: TextStyle(
                        color:
                            _selectedCoin == null &&
                                _symbolController.text.isEmpty
                            ? AppTheme.textDisabled
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Unit (other only) ─────────────────────────────────────
              if (showOtherUnit) ...[
                TextFormField(
                  controller: _unitController,
                  decoration: const InputDecoration(
                    labelText: 'وحدة القياس',
                    hintText: 'مثال: متر مربع، قطعة',
                  ),
                  validator: (v) =>
                      showOtherUnit && (v == null || v.trim().isEmpty)
                      ? 'أدخل وحدة القياس'
                      : null,
                ),
                const SizedBox(height: 16),
              ],

              // ── Quantity ──────────────────────────────────────────────
              TextFormField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'الكمية',
                  suffixText: _isMetal ? 'غرام' : null,
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
                        decimal: true,
                      ),
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
                  if (_canAutoPrice) ...[
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
                                  strokeWidth: 2,
                                ),
                              )
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
                  child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
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
                    Text(
                      'الإجمالي',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '\$${NumberFormat('#,##0.##').format(_total)}',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: AppTheme.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(onPressed: _save, child: const Text('حفظ الأصل')),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Crypto picker sheet ───────────────────────────────────────────────────────

class _CryptoPickerSheet extends StatefulWidget {
  final _CoinInfo? selected;
  final String customSymbol;
  final void Function(_CoinInfo? coin, String? customSymbol) onSelected;
  final VoidCallback onProRequired;

  const _CryptoPickerSheet({
    required this.selected,
    required this.customSymbol,
    required this.onSelected,
    required this.onProRequired,
  });

  @override
  State<_CryptoPickerSheet> createState() => _CryptoPickerSheetState();
}

class _CryptoPickerSheetState extends State<_CryptoPickerSheet> {
  bool _showCustom = false;
  final _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.selected == null && widget.customSymbol.isNotEmpty) {
      _showCustom = true;
      _customController.text = widget.customSymbol;
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.textDisabled,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'اختر العملة',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () => setState(() => _showCustom = !_showCustom),
                  child: Text(_showCustom ? 'اختر من القائمة' : 'رمز مخصص'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_showCustom)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _customController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'رمز التداول',
                      hintText: 'مثال: BTCUSDT، ETHUSDT',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final sym = _customController.text.trim();
                      if (sym.isNotEmpty) {
                        widget.onSelected(null, sym);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('تأكيد'),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _kCoins.length,
                itemBuilder: (context, i) {
                  final coin = _kCoins[i];
                  final isSelected = widget.selected?.symbol == coin.symbol;
                  final isFree = _kFreeCoins.contains(coin.symbol);
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          coin.unit,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isFree
                                ? AppTheme.primary
                                : AppTheme.textDisabled,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      coin.name,
                      style: TextStyle(
                        color: isFree ? null : AppTheme.textSecondary,
                      ),
                    ),
                    subtitle: Text(
                      coin.symbol,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: AppTheme.primary,
                          )
                        : isFree
                        ? null
                        : _ProBadge(),
                    selected: isSelected,
                    onTap: () {
                      if (!isFree) {
                        Navigator.pop(context);
                        widget.onProRequired();
                        return;
                      }
                      widget.onSelected(coin, null);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ── Pro badge ─────────────────────────────────────────────────────────────────

class _ProBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.4),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 12),
          SizedBox(width: 3),
          Text(
            'Pro',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
