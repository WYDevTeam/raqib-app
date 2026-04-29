import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../features/transactions/domain/entities/transaction_entity.dart';
import '../../../../features/transactions/domain/usecases/add_transaction_usecase.dart';
import '../../../../features/investments/data/models/asset_model.dart';
import '../../../../features/investments/data/models/asset_transaction_model.dart';
import '../../../../features/settings/domain/usecases/complete_onboarding_usecase.dart';
import 'package:hive/hive.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  final CompleteOnboardingUseCase _completeOnboarding;
  final AddTransactionUseCase _addTransaction;
  final Box<AssetModel> _assetBox;
  final Box<AssetTransactionModel> _assetTxBox;

  static const String _openingBalanceCategoryId = 'opening_balance';

  OnboardingCubit({
    required CompleteOnboardingUseCase completeOnboarding,
    required AddTransactionUseCase addTransaction,
    required Box<AssetModel> assetBox,
    required Box<AssetTransactionModel> assetTxBox,
  })  : _completeOnboarding = completeOnboarding,
        _addTransaction = addTransaction,
        _assetBox = assetBox,
        _assetTxBox = assetTxBox,
        super(const OnboardingIdle());

  /// Skip — just mark onboarding complete.
  Future<void> skip() async {
    emit(const OnboardingLoading());
    final result = await _completeOnboarding();
    result.fold(
      (f) => emit(OnboardingError(f.message)),
      (_) => emit(const OnboardingDone()),
    );
  }

  /// Save initial assets, then mark onboarding complete.
  Future<void> saveInitialAssets({
    required double cash,
    required double goldGrams,
    required double goldCostPerGram,
    required double silverGrams,
    required double silverCostPerGram,
    required double cryptoUsdt,
    required double cryptoCostPerUsdt,
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

      if (goldGrams > 0) {
        await _saveAsset(
          name: 'ذهب',
          type: 'gold',
          symbol: 'XAU',
          quantity: goldGrams,
          unit: 'غرام',
          costPerUnit: goldCostPerGram,
        );
      }

      if (silverGrams > 0) {
        await _saveAsset(
          name: 'فضة',
          type: 'silver',
          symbol: 'XAG',
          quantity: silverGrams,
          unit: 'غرام',
          costPerUnit: silverCostPerGram,
        );
      }

      if (cryptoUsdt > 0) {
        await _saveAsset(
          name: 'كريبتو (USDT)',
          type: 'crypto',
          symbol: 'USDT',
          quantity: cryptoUsdt,
          unit: 'USDT',
          costPerUnit: cryptoCostPerUsdt,
        );
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

  Future<void> _saveAsset({
    required String name,
    required String type,
    required String symbol,
    required double quantity,
    required String unit,
    required double costPerUnit,
  }) async {
    final assetId = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    final totalCost = quantity * costPerUnit;

    final asset = AssetModel(
      id: assetId,
      name: name,
      type: type,
      symbol: symbol,
      quantity: quantity,
      unit: unit,
      totalCost: totalCost,
      currentValuePerUnit: costPerUnit,
      createdAtMs: now,
    );
    await _assetBox.put(assetId, asset);

    final tx = AssetTransactionModel(
      id: const Uuid().v4(),
      assetId: assetId,
      isBuy: true,
      quantity: quantity,
      pricePerUnit: costPerUnit,
      dateMs: now,
      note: 'رصيد افتتاحي',
    );
    await _assetTxBox.put(tx.id, tx);
  }
}
