import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import 'cubit/onboarding_cubit.dart';
import 'cubit/onboarding_state.dart';

// ── Local data models ─────────────────────────────────────────────────────────

class _PersonEntry {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController amountCtrl = TextEditingController();
  void dispose() {
    nameCtrl.dispose();
    amountCtrl.dispose();
  }
}

class _MetalEntry {
  final TextEditingController qtyCtrl = TextEditingController();
  final TextEditingController costCtrl = TextEditingController();
  void dispose() {
    qtyCtrl.dispose();
    costCtrl.dispose();
  }
}

class _CryptoEntry {
  final TextEditingController nameCtrl = TextEditingController(text: 'Bitcoin');
  final TextEditingController symbolCtrl = TextEditingController(text: 'BTC');
  final TextEditingController qtyCtrl = TextEditingController();
  final TextEditingController costCtrl = TextEditingController();
  void dispose() {
    nameCtrl.dispose();
    symbolCtrl.dispose();
    qtyCtrl.dispose();
    costCtrl.dispose();
  }
}

class _CustomAsset {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController valueCtrl = TextEditingController();
  void dispose() {
    nameCtrl.dispose();
    valueCtrl.dispose();
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class InitialAssetsScreen extends StatefulWidget {
  const InitialAssetsScreen({super.key});

  @override
  State<InitialAssetsScreen> createState() => _InitialAssetsScreenState();
}

class _InitialAssetsScreenState extends State<InitialAssetsScreen> {
  final _pageController = PageController();
  int _step = 0;
  static const int _totalSteps = 4;

  // Step 0 — Cash
  final _cashCtrl = TextEditingController();

  // Step 1 — Assets
  bool _goldOn = false;
  final List<_MetalEntry> _goldEntries = [_MetalEntry()];
  bool _silverOn = false;
  final List<_MetalEntry> _silverEntries = [_MetalEntry()];
  bool _cryptoOn = false;
  final List<_CryptoEntry> _cryptoEntries = [_CryptoEntry()];
  final List<_CustomAsset> _customAssets = [];

  // Step 2 — Amanah
  final List<_PersonEntry> _amanahList = [];

  // Step 3 — Debts owed to user
  final List<_PersonEntry> _debtsList = [];

  @override
  void dispose() {
    _pageController.dispose();
    _cashCtrl.dispose();
    for (final e in _goldEntries) e.dispose();
    for (final e in _silverEntries) e.dispose();
    for (final e in _cryptoEntries) e.dispose();
    for (final a in _customAssets) a.dispose();
    for (final e in _amanahList) e.dispose();
    for (final e in _debtsList) e.dispose();
    super.dispose();
  }

  double _parseCtrl(TextEditingController c) =>
      double.tryParse(c.text.trim()) ?? 0;

  void _goTo(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _next() => _goTo(_step + 1);
  void _prev() {
    if (_step > 0) {
      _goTo(_step - 1);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _skip() {
    setState(() {
      if (_step == 1) {
        _goldOn = false;
        _silverOn = false;
        _cryptoOn = false;
        _customAssets.clear();
      } else if (_step == 2) {
        _amanahList.clear();
      } else if (_step == 3) {
        _debtsList.clear();
      }
    });

    if (_isLastStep) {
      _finish();
    } else {
      _next();
    }
  }

  Future<void> _finish() async {
    final cubit = context.read<OnboardingCubit>();

    final assets = <OnboardingAsset>[];

    if (_goldOn) {
      for (final entry in _goldEntries) {
        final qty = _parseCtrl(entry.qtyCtrl);
        if (qty > 0) {
          assets.add(OnboardingAsset(
            name: 'ذهب',
            type: 'gold',
            symbol: 'XAU',
            unit: 'غرام',
            quantity: qty,
            costPerUnit: _parseCtrl(entry.costCtrl),
          ));
        }
      }
    }
    if (_silverOn) {
      for (final entry in _silverEntries) {
        final qty = _parseCtrl(entry.qtyCtrl);
        if (qty > 0) {
          assets.add(OnboardingAsset(
            name: 'فضة',
            type: 'silver',
            symbol: 'XAG',
            unit: 'غرام',
            quantity: qty,
            costPerUnit: _parseCtrl(entry.costCtrl),
          ));
        }
      }
    }
    if (_cryptoOn) {
      for (final entry in _cryptoEntries) {
        final qty = _parseCtrl(entry.qtyCtrl);
        if (qty > 0) {
          final name = entry.nameCtrl.text.trim().isEmpty
              ? 'كريبتو'
              : entry.nameCtrl.text.trim();
          final symbol = entry.symbolCtrl.text.trim().toUpperCase().isEmpty
              ? 'CRYPTO'
              : entry.symbolCtrl.text.trim().toUpperCase();
          assets.add(OnboardingAsset(
            name: name,
            type: 'crypto',
            symbol: '${symbol}USDT',
            unit: symbol,
            quantity: qty,
            costPerUnit: _parseCtrl(entry.costCtrl),
          ));
        }
      }
    }
    for (final ca in _customAssets) {
      final name = ca.nameCtrl.text.trim();
      final value = _parseCtrl(ca.valueCtrl);
      if (name.isNotEmpty && value > 0) {
        assets.add(OnboardingAsset(
          name: name,
          type: 'other',
          symbol: '',
          unit: 'وحدة',
          quantity: 1,
          costPerUnit: value,
        ));
      }
    }

    final amanah = _amanahList
        .where((e) =>
            e.nameCtrl.text.trim().isNotEmpty &&
            _parseCtrl(e.amountCtrl) > 0)
        .map((e) => OnboardingPerson(
              name: e.nameCtrl.text.trim(),
              amount: _parseCtrl(e.amountCtrl),
            ))
        .toList();

    final debts = _debtsList
        .where((e) =>
            e.nameCtrl.text.trim().isNotEmpty &&
            _parseCtrl(e.amountCtrl) > 0)
        .map((e) => OnboardingPerson(
              name: e.nameCtrl.text.trim(),
              amount: _parseCtrl(e.amountCtrl),
            ))
        .toList();

    await cubit.saveInitialData(
      cash: _parseCtrl(_cashCtrl),
      assets: assets,
      amanah: amanah,
      debts: debts,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingCubit, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingDone) context.go('/dashboard');
        if (state is OnboardingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: BlocBuilder<OnboardingCubit, OnboardingState>(
        builder: (context, state) {
          final loading = state is OnboardingLoading;
          return PopScope(
            canPop: _step == 0,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _prev();
            },
            child: Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: loading ? null : _prev,
                ),
                title: Text(_stepTitle),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Row(
                      children: List.generate(_totalSteps, (index) {
                        final isActive = index <= _step;
                        return Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppTheme.primary
                                  : AppTheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.primary.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
              body: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StepCash(cashCtrl: _cashCtrl),
                  _StepAssets(
                    goldOn: _goldOn,
                    onGoldToggle: (v) => setState(() => _goldOn = v),
                    goldEntries: _goldEntries,
                    onAddGold: () => setState(() => _goldEntries.add(_MetalEntry())),
                    onRemoveGold: (i) => setState(() {
                      _goldEntries[i].dispose();
                      _goldEntries.removeAt(i);
                    }),
                    silverOn: _silverOn,
                    onSilverToggle: (v) => setState(() => _silverOn = v),
                    silverEntries: _silverEntries,
                    onAddSilver: () => setState(() => _silverEntries.add(_MetalEntry())),
                    onRemoveSilver: (i) => setState(() {
                      _silverEntries[i].dispose();
                      _silverEntries.removeAt(i);
                    }),
                    cryptoOn: _cryptoOn,
                    onCryptoToggle: (v) => setState(() => _cryptoOn = v),
                    cryptoEntries: _cryptoEntries,
                    onAddCrypto: () => setState(() => _cryptoEntries.add(_CryptoEntry())),
                    onRemoveCrypto: (i) => setState(() {
                      _cryptoEntries[i].dispose();
                      _cryptoEntries.removeAt(i);
                    }),
                    customAssets: _customAssets,
                    onAddCustom: () => setState(() =>
                        _customAssets.add(_CustomAsset())),
                    onRemoveCustom: (i) => setState(() {
                      _customAssets[i].dispose();
                      _customAssets.removeAt(i);
                    }),
                  ),
                  _StepPersonList(
                    title: 'أمانات عندك',
                    hint: 'اسم صاحب الأمانة',
                    addLabel: '+ إضافة أمانة',
                    entries: _amanahList,
                    onAdd: () =>
                        setState(() => _amanahList.add(_PersonEntry())),
                    onRemove: (i) => setState(() {
                      _amanahList[i].dispose();
                      _amanahList.removeAt(i);
                    }),
                  ),
                  _StepPersonList(
                    title: 'ديون لك عند الناس',
                    hint: 'اسم المدين',
                    addLabel: '+ إضافة دين',
                    entries: _debtsList,
                    onAdd: () =>
                        setState(() => _debtsList.add(_PersonEntry())),
                    onRemove: (i) => setState(() {
                      _debtsList[i].dispose();
                      _debtsList.removeAt(i);
                    }),
                  ),
                ],
              ),
              bottomNavigationBar: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Row(
                    children: [
                      if (_step > 0) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: loading ? null : _skip,
                            child: const Text('تخطى'),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        flex: _step > 0 ? 2 : 1,
                        child: ElevatedButton(
                          onPressed: loading ? null : (_isLastStep ? _finish : _next),
                          child: loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_isLastStep ? 'حفظ وابدأ' : 'التالي'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool get _isLastStep => _step == _totalSteps - 1;

  String get _stepTitle => switch (_step) {
        0 => 'الكاش الجاهز',
        1 => 'الأصول',
        2 => 'الأمانات',
        3 => 'الديون لك',
        _ => '',
      };
}

// ── Step 0: Cash ──────────────────────────────────────────────────────────────

class _StepCash extends StatelessWidget {
  final TextEditingController cashCtrl;
  const _StepCash({required this.cashCtrl});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'كم عندك كاش جاهز الآن؟',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'يشمل كل نقود في متناول يدك — حساب بنكي، محفظة، إلخ',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: cashCtrl,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              prefixText: '\$ ',
              hintText: '0.00',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 1: Assets ────────────────────────────────────────────────────────────

class _StepAssets extends StatelessWidget {
  final bool goldOn;
  final ValueChanged<bool> onGoldToggle;
  final List<_MetalEntry> goldEntries;
  final VoidCallback onAddGold;
  final ValueChanged<int> onRemoveGold;
  final bool silverOn;
  final ValueChanged<bool> onSilverToggle;
  final List<_MetalEntry> silverEntries;
  final VoidCallback onAddSilver;
  final ValueChanged<int> onRemoveSilver;
  final bool cryptoOn;
  final ValueChanged<bool> onCryptoToggle;
  final List<_CryptoEntry> cryptoEntries;
  final VoidCallback onAddCrypto;
  final ValueChanged<int> onRemoveCrypto;
  final List<_CustomAsset> customAssets;
  final VoidCallback onAddCustom;
  final ValueChanged<int> onRemoveCustom;

  const _StepAssets({
    required this.goldOn,
    required this.onGoldToggle,
    required this.goldEntries,
    required this.onAddGold,
    required this.onRemoveGold,
    required this.silverOn,
    required this.onSilverToggle,
    required this.silverEntries,
    required this.onAddSilver,
    required this.onRemoveSilver,
    required this.cryptoOn,
    required this.onCryptoToggle,
    required this.cryptoEntries,
    required this.onAddCrypto,
    required this.onRemoveCrypto,
    required this.customAssets,
    required this.onAddCustom,
    required this.onRemoveCustom,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'أضف أصولك الحالية (اختياري)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          _MetalSection(
            icon: '🟡',
            title: 'ذهب',
            enabled: goldOn,
            onToggle: onGoldToggle,
            entries: goldEntries,
            onAdd: onAddGold,
            onRemove: onRemoveGold,
          ),
          _MetalSection(
            icon: '⚪',
            title: 'فضة',
            enabled: silverOn,
            onToggle: onSilverToggle,
            entries: silverEntries,
            onAdd: onAddSilver,
            onRemove: onRemoveSilver,
          ),
          _CryptoSection(
            enabled: cryptoOn,
            onToggle: onCryptoToggle,
            entries: cryptoEntries,
            onAdd: onAddCrypto,
            onRemove: onRemoveCrypto,
          ),
          ...customAssets.asMap().entries.map((e) => _CustomAssetCard(
                asset: e.value,
                onRemove: () => onRemoveCustom(e.key),
              )),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onAddCustom,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('إضافة أصل مخصص'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _MetalSection extends StatelessWidget {
  final String icon, title;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final List<_MetalEntry> entries;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _MetalSection({
    required this.icon,
    required this.title,
    required this.enabled,
    required this.onToggle,
    required this.entries,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled
              ? AppTheme.primary.withValues(alpha: 0.4)
              : const Color(0xFFEFEFEF),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => onToggle(!enabled),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(title,
                        style: Theme.of(context).textTheme.titleSmall),
                  ),
                  Switch(
                    value: enabled,
                    onChanged: onToggle,
                    activeThumbColor: AppTheme.primary,
                  ),
                ],
              ),
            ),
          ),
          if (enabled) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ...entries.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _MetalEntryCard(
                          entry: e.value,
                          index: e.key,
                          canRemove: entries.length > 1,
                          onRemove: () => onRemove(e.key),
                        ),
                      )),
                  OutlinedButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('إضافة شراء آخر'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetalEntryCard extends StatelessWidget {
  final _MetalEntry entry;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;

  const _MetalEntryCard({
    required this.entry,
    required this.index,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'شراء ${index + 1}',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
              const Spacer(),
              if (canRemove)
                GestureDetector(
                  onTap: onRemove,
                  child: const Icon(Icons.close,
                      size: 18, color: AppTheme.error),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: entry.qtyCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'الكمية',
                    suffixText: 'غرام',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: entry.costCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'سعر الغرام',
                    suffixText: '\$',
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CryptoSection extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final List<_CryptoEntry> entries;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _CryptoSection({
    required this.enabled,
    required this.onToggle,
    required this.entries,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled
              ? AppTheme.primary.withValues(alpha: 0.4)
              : const Color(0xFFEFEFEF),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => onToggle(!enabled),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('₿', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('كريبتو',
                        style: Theme.of(context).textTheme.titleSmall),
                  ),
                  Switch(
                    value: enabled,
                    onChanged: onToggle,
                    activeThumbColor: AppTheme.primary,
                  ),
                ],
              ),
            ),
          ),
          if (enabled) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ...entries.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CryptoEntryCard(
                          entry: e.value,
                          index: e.key,
                          canRemove: entries.length > 1,
                          onRemove: () => onRemove(e.key),
                        ),
                      )),
                  OutlinedButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('إضافة عملة أخرى'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CryptoEntryCard extends StatelessWidget {
  final _CryptoEntry entry;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;

  const _CryptoEntryCard({
    required this.entry,
    required this.index,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'عملة ${index + 1}',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
              const Spacer(),
              if (canRemove)
                GestureDetector(
                  onTap: onRemove,
                  child: const Icon(Icons.close,
                      size: 18, color: AppTheme.error),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: entry.nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'الاسم',
                    hintText: 'Bitcoin',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: entry.symbolCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'الرمز',
                    hintText: 'BTC',
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: entry.qtyCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'الكمية',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: entry.costCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'سعر الشراء',
                    suffixText: '\$',
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssetSection extends StatelessWidget {
  final String icon, title;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final List<Widget> fields;

  const _AssetSection({
    required this.icon,
    required this.title,
    required this.enabled,
    required this.onToggle,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled
              ? AppTheme.primary.withValues(alpha: 0.4)
              : const Color(0xFFEFEFEF),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => onToggle(!enabled),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
                bottom: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(title,
                        style:
                            Theme.of(context).textTheme.titleSmall),
                  ),
                  Switch(
                    value: enabled,
                    onChanged: onToggle,
                    activeThumbColor: AppTheme.primary,
                  ),
                ],
              ),
            ),
          ),
          if (enabled) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: fields
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: f,
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, suffix;
  final bool isText;
  const _FieldRow({
    required this.ctrl,
    required this.label,
    required this.suffix,
    this.isText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: isText
          ? TextInputType.text
          : const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix.isEmpty ? null : suffix,
      ),
    );
  }
}

class _CustomAssetCard extends StatelessWidget {
  final _CustomAsset asset;
  final VoidCallback onRemove;
  const _CustomAssetCard({required this.asset, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text('أصل مخصص',
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              IconButton(
                icon: const Icon(Icons.close,
                    color: AppTheme.error, size: 20),
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: asset.nameCtrl,
            decoration: const InputDecoration(labelText: 'اسم الأصل'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: asset.valueCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'القيمة الحالية',
              suffixText: '\$',
            ),
          ),
        ],
      ),
    );
  }
}

// ── Steps 2 & 3: Person list (Amanah / Debts) ────────────────────────────────

class _StepPersonList extends StatelessWidget {
  final String title, hint, addLabel;
  final List<_PersonEntry> entries;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _StepPersonList({
    required this.title,
    required this.hint,
    required this.addLabel,
    required this.entries,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'اختياري — تقدر تتخطى هذه الخطوة',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          ...entries.asMap().entries.map(
                (e) => _PersonEntryCard(
                  entry: e.value,
                  nameHint: hint,
                  onRemove: () => onRemove(e.key),
                ),
              ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: Text(addLabel),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _PersonEntryCard extends StatelessWidget {
  final _PersonEntry entry;
  final String nameHint;
  final VoidCallback onRemove;

  const _PersonEntryCard({
    required this.entry,
    required this.nameHint,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close,
                    color: AppTheme.error, size: 20),
                onPressed: onRemove,
              ),
            ],
          ),
          TextField(
            controller: entry.nameCtrl,
            decoration: InputDecoration(labelText: nameHint),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: entry.amountCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'المبلغ',
              prefixText: '\$ ',
            ),
          ),
        ],
      ),
    );
  }
}
