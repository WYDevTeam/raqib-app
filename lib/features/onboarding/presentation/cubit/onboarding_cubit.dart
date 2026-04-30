import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../../features/debts_amanah/data/models/amanah_model.dart';
import '../../../../features/debts_amanah/data/models/debt_model.dart';
import '../../../../features/investments/data/models/asset_model.dart';
import '../../../../features/investments/data/models/asset_transaction_model.dart';
import '../../../../features/settings/domain/usecases/complete_onboarding_usecase.dart';
import '../../../../features/transactions/domain/entities/transaction_entity.dart';
import '../../../../features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'onboarding_state.dart';

// ── Data transfer types ───────────────────────────────────────────────────────

class OnboardingAsset {
  final String name;
  final String type;
  final String symbol;
  final String unit;
  final double quantity;
  final double costPerUnit;

  const OnboardingAsset({
    required this.name,
    required this.type,
    required this.symbol,
    required this.unit,
    required this.quantity,
    required this.costPerUnit,
  });
}

class OnboardingPerson {
  final String name;
  final double amount;
  const OnboardingPerson({required this.name, required this.amount});
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class OnboardingCubit extends Cubit<OnboardingState> {
  final CompleteOnboardingUseCase _completeOnboarding;
  final AddTransactionUseCase _addTransaction;
  final Box<AssetModel> _assetBox;
  final Box<AssetTransactionModel> _assetTxBox;
  final Box<AmanahModel> _amanahBox;
  final Box<DebtModel> _debtBox;

  static const String _openingBalanceCategoryId = 'opening_balance';

  OnboardingCubit({
    required CompleteOnboardingUseCase completeOnboarding,
    required AddTransactionUseCase addTransaction,
    required Box<AssetModel> assetBox,
    required Box<AssetTransactionModel> assetTxBox,
    required Box<AmanahModel> amanahBox,
    required Box<DebtModel> debtBox,
  })  : _completeOnboarding = completeOnboarding,
        _addTransaction = addTransaction,
        _assetBox = assetBox,
        _assetTxBox = assetTxBox,
        _amanahBox = amanahBox,
        _debtBox = debtBox,
        super(const OnboardingIdle());

  Future<void> skip() async {
    emit(const OnboardingLoading());
    final result = await _completeOnboarding();
    result.fold(
      (f) => emit(OnboardingError(f.message)),
      (_) => emit(const OnboardingDone()),
    );
  }

  Future<void> saveInitialData({
    required double cash,
    required List<OnboardingAsset> assets,
    required List<OnboardingPerson> amanah,
    required List<OnboardingPerson> debts,
  }) async {
    emit(const OnboardingLoading());
    try {
      if (cash > 0) {
        await _addTransaction(
          TransactionEntity(
            id: const Uuid().v4(),
            amount: cash,
            categoryId: _openingBalanceCategoryId,
            description: 'رصيد افتتاحي',
            date: DateTime.now(),
            isIncome: true,
          ),
        );
      }

      for (final asset in assets) {
        await _saveAsset(asset);
      }

      final now = DateTime.now().millisecondsSinceEpoch;

      for (final entry in amanah) {
        final model = AmanahModel(
          id: const Uuid().v4(),
          personName: entry.name,
          amount: entry.amount,
          receivedDateMs: now,
          note: 'رصيد افتتاحي',
        );
        await _amanahBox.put(model.id, model);
      }

      for (final entry in debts) {
        final model = DebtModel(
          id: const Uuid().v4(),
          personName: entry.name,
          totalAmount: entry.amount,
          paidAmount: 0,
          givenDateMs: now,
          note: 'رصيد افتتاحي',
        );
        await _debtBox.put(model.id, model);
      }

      final result = await _completeOnboarding();
      result.fold(
        (f) => emit(OnboardingError(f.message)),
        (_) => emit(const OnboardingDone()),
      );
    } catch (e) {
      emit(OnboardingError('فشل حفظ البيانات: $e'));
    }
  }

  Future<void> _saveAsset(OnboardingAsset a) async {
    final assetId = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    await _assetBox.put(
      assetId,
      AssetModel(
        id: assetId,
        name: a.name,
        type: a.type,
        symbol: a.symbol,
        quantity: a.quantity,
        unit: a.unit,
        totalCost: a.quantity * a.costPerUnit,
        currentValuePerUnit: a.costPerUnit,
        createdAtMs: now,
      ),
    );

    await _assetTxBox.put(
      const Uuid().v4(),
      AssetTransactionModel(
        id: const Uuid().v4(),
        assetId: assetId,
        isBuy: true,
        quantity: a.quantity,
        pricePerUnit: a.costPerUnit,
        dateMs: now,
        note: 'رصيد افتتاحي',
      ),
    );
  }
}
