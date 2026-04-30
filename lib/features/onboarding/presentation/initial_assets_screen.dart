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
  final _goldQtyCtrl = TextEditingController();
  final _goldCostCtrl = TextEditingController();
  bool _silverOn = false;
  final _silverQtyCtrl = TextEditingController();
  final _silverCostCtrl = TextEditingController();
  bool _cryptoOn = false;
  final _cryptoNameCtrl = TextEditingController(text: 'Bitcoin');
  final _cryptoSymbolCtrl = TextEditingController(text: 'BTC');
  final _cryptoQtyCtrl = TextEditingController();
  final _cryptoCostCtrl = TextEditingController();
  final List<_CustomAsset> _customAssets = [];

  // Step 2 — Amanah
  final List<_PersonEntry> _amanahList = [];

  // Step 3 — Debts owed to user
  final List<_PersonEntry> _debtsList = [];

  @override
  void dispose() {
    _pageController.dispose();
    _cashCtrl.dispose();
    _goldQtyCtrl.dispose();
    _goldCostCtrl.dispose();
    _silverQtyCtrl.dispose();
    _silverCostCtrl.dispose();
    _cryptoNameCtrl.dispose();
    _cryptoSymbolCtrl.dispose();
    _cryptoQtyCtrl.dispose();
    _cryptoCostCtrl.dispose();
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

  Future<void> _finish() async {
    final cubit = context.read<OnboardingCubit>();

    final assets = <OnboardingAsset>[];

    if (_goldOn && _parseCtrl(_goldQtyCtrl) > 0) {
      assets.add(OnboardingAsset(
        name: 'ذهب',
        type: 'gold',
        symbol: 'XAU',
        unit: 'غرام',
        quantity: _parseCtrl(_goldQtyCtrl),
        costPerUnit: _parseCtrl(_goldCostCtrl),
      ));
    }
    if (_silverOn && _parseCtrl(_silverQtyCtrl) > 0) {
      assets.add(OnboardingAsset(
        name: 'فضة',
        type: 'silver',
        symbol: 'XAG',
        unit: 'غرام',
        quantity: _parseCtrl(_silverQtyCtrl),
        costPerUnit: _parseCtrl(_silverCostCtrl),
      ));
    }
    if (_cryptoOn && _parseCtrl(_cryptoQtyCtrl) > 0) {
      final name = _cryptoNameCtrl.text.trim().isEmpty
          ? 'كريبتو'
          : _cryptoNameCtrl.text.trim();
      final symbol = _cryptoSymbolCtrl.text.trim().toUpperCase().isEmpty
          ? 'CRYPTO'
          : _cryptoSymbolCtrl.text.trim().toUpperCase();
      assets.add(OnboardingAsset(
        name: name,
        type: 'crypto',
        symbol: '${symbol}USDT',
        unit: symbol,
        quantity: _parseCtrl(_cryptoQtyCtrl),
        costPerUnit: _parseCtrl(_cryptoCostCtrl),
      ));
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
                  preferredSize: const Size.fromHeight(6),
                  child: LinearProgressIndicator(
                    value: (_step + 1) / _totalSteps,
                    backgroundColor:
                        AppTheme.primary.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                    minHeight: 4,
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
                    goldQtyCtrl: _goldQtyCtrl,
                    goldCostCtrl: _goldCostCtrl,
                    silverOn: _silverOn,
                    onSilverToggle: (v) => setState(() => _silverOn = v),
                    silverQtyCtrl: _silverQtyCtrl,
                    silverCostCtrl: _silverCostCtrl,
                    cryptoOn: _cryptoOn,
                    onCryptoToggle: (v) => setState(() => _cryptoOn = v),
                    cryptoNameCtrl: _cryptoNameCtrl,
                    cryptoSymbolCtrl: _cryptoSymbolCtrl,
                    cryptoQtyCtrl: _cryptoQtyCtrl,
                    cryptoCostCtrl: _cryptoCostCtrl,
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
                            onPressed: loading ? null : _next,
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
  final TextEditingController goldQtyCtrl, goldCostCtrl;
  final bool silverOn;
  final ValueChanged<bool> onSilverToggle;
  final TextEditingController silverQtyCtrl, silverCostCtrl;
  final bool cryptoOn;
  final ValueChanged<bool> onCryptoToggle;
  final TextEditingController cryptoNameCtrl, cryptoSymbolCtrl,
      cryptoQtyCtrl, cryptoCostCtrl;
  final List<_CustomAsset> customAssets;
  final VoidCallback onAddCustom;
  final ValueChanged<int> onRemoveCustom;

  const _StepAssets({
    required this.goldOn,
    required this.onGoldToggle,
    required this.goldQtyCtrl,
    required this.goldCostCtrl,
    required this.silverOn,
    required this.onSilverToggle,
    required this.silverQtyCtrl,
    required this.silverCostCtrl,
    required this.cryptoOn,
    required this.onCryptoToggle,
    required this.cryptoNameCtrl,
    required this.cryptoSymbolCtrl,
    required this.cryptoQtyCtrl,
    required this.cryptoCostCtrl,
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
          _AssetSection(
            icon: '🟡',
            title: 'ذهب',
            enabled: goldOn,
            onToggle: onGoldToggle,
            fields: [
              _FieldRow(ctrl: goldQtyCtrl, label: 'الكمية', suffix: 'غرام'),
              _FieldRow(
                  ctrl: goldCostCtrl,
                  label: 'سعر شراء الغرام',
                  suffix: '\$'),
            ],
          ),
          _AssetSection(
            icon: '⚪',
            title: 'فضة',
            enabled: silverOn,
            onToggle: onSilverToggle,
            fields: [
              _FieldRow(ctrl: silverQtyCtrl, label: 'الكمية', suffix: 'غرام'),
              _FieldRow(
                  ctrl: silverCostCtrl,
                  label: 'سعر شراء الغرام',
                  suffix: '\$'),
            ],
          ),
          _AssetSection(
            icon: '₿',
            title: 'كريبتو',
            enabled: cryptoOn,
            onToggle: onCryptoToggle,
            fields: [
              _FieldRow(
                  ctrl: cryptoNameCtrl,
                  label: 'اسم العملة',
                  suffix: '',
                  isText: true),
              _FieldRow(
                  ctrl: cryptoSymbolCtrl,
                  label: 'الرمز',
                  suffix: '',
                  isText: true),
              _FieldRow(ctrl: cryptoQtyCtrl, label: 'الكمية', suffix: ''),
              _FieldRow(
                  ctrl: cryptoCostCtrl,
                  label: 'سعر الشراء للوحدة',
                  suffix: '\$'),
            ],
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
