import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import 'cubit/onboarding_cubit.dart';
import 'cubit/onboarding_state.dart';

class InitialAssetsScreen extends StatefulWidget {
  const InitialAssetsScreen({super.key});

  @override
  State<InitialAssetsScreen> createState() => _InitialAssetsScreenState();
}

class _InitialAssetsScreenState extends State<InitialAssetsScreen> {
  final _cashCtrl = TextEditingController();
  final _goldQtyCtrl = TextEditingController();
  final _goldCostCtrl = TextEditingController();
  final _silverQtyCtrl = TextEditingController();
  final _silverCostCtrl = TextEditingController();
  final _cryptoQtyCtrl = TextEditingController();
  final _cryptoCostCtrl = TextEditingController();

  @override
  void dispose() {
    _cashCtrl.dispose();
    _goldQtyCtrl.dispose();
    _goldCostCtrl.dispose();
    _silverQtyCtrl.dispose();
    _silverCostCtrl.dispose();
    _cryptoQtyCtrl.dispose();
    _cryptoCostCtrl.dispose();
    super.dispose();
  }

  double _parse(TextEditingController c) =>
      double.tryParse(c.text.trim()) ?? 0;

  Future<void> _save() async {
    await context.read<OnboardingCubit>().saveInitialAssets(
          cash: _parse(_cashCtrl),
          goldGrams: _parse(_goldQtyCtrl),
          goldCostPerGram: _parse(_goldCostCtrl),
          silverGrams: _parse(_silverQtyCtrl),
          silverCostPerGram: _parse(_silverCostCtrl),
          cryptoUsdt: _parse(_cryptoQtyCtrl),
          cryptoCostPerUsdt: _parse(_cryptoCostCtrl),
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
      child: Scaffold(
        appBar: AppBar(title: const Text('ما هي أصولك الحالية؟')),
        body: BlocBuilder<OnboardingCubit, OnboardingState>(
          builder: (context, state) {
            final loading = state is OnboardingLoading;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'ضع تقدير تقريبي — تقدر تعدّل لاحقاً',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 28),

                  _Section(
                    emoji: '💵',
                    title: 'الكاش الجاهز',
                    children: [
                      _AmountField(
                          controller: _cashCtrl,
                          label: 'المبلغ',
                          suffix: '\$'),
                    ],
                  ),

                  _Section(
                    emoji: '🟡',
                    title: 'الذهب',
                    children: [
                      _AmountField(
                          controller: _goldQtyCtrl,
                          label: 'الكمية',
                          suffix: 'غرام'),
                      const SizedBox(height: 12),
                      _AmountField(
                          controller: _goldCostCtrl,
                          label: 'سعر الشراء للغرام',
                          suffix: '\$'),
                    ],
                  ),

                  _Section(
                    emoji: '⚪',
                    title: 'الفضة',
                    children: [
                      _AmountField(
                          controller: _silverQtyCtrl,
                          label: 'الكمية',
                          suffix: 'غرام'),
                      const SizedBox(height: 12),
                      _AmountField(
                          controller: _silverCostCtrl,
                          label: 'سعر الشراء للغرام',
                          suffix: '\$'),
                    ],
                  ),

                  _Section(
                    emoji: '₿',
                    title: 'الكريبتو (USDT)',
                    children: [
                      _AmountField(
                          controller: _cryptoQtyCtrl,
                          label: 'الكمية',
                          suffix: 'USDT'),
                      const SizedBox(height: 12),
                      _AmountField(
                          controller: _cryptoCostCtrl,
                          label: 'متوسط سعر الشراء',
                          suffix: '\$'),
                    ],
                  ),

                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: loading ? null : _save,
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('حفظ وابدأ'),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String emoji;
  final String title;
  final List<Widget> children;
  const _Section(
      {required this.emoji, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleSmall),
          ]),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  const _AmountField(
      {required this.controller,
      required this.label,
      required this.suffix});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
      ),
    );
  }
}
