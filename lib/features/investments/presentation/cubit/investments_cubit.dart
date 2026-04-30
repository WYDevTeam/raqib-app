import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/asset_entity.dart';
import '../../domain/entities/asset_transaction_entity.dart';
import '../../domain/usecases/add_asset_transaction_usecase.dart';
import '../../domain/usecases/add_asset_usecase.dart';
import '../../domain/usecases/delete_asset_transaction_usecase.dart';
import '../../domain/usecases/delete_asset_usecase.dart';
import '../../domain/usecases/get_asset_transactions_usecase.dart';
import '../../domain/usecases/get_assets_usecase.dart';
import '../../domain/usecases/update_asset_price_usecase.dart';
import 'investments_state.dart';

class InvestmentsCubit extends Cubit<InvestmentsState> {
  final GetAssetsUseCase _getAssets;
  final AddAssetUseCase _addAsset;
  final DeleteAssetUseCase _deleteAsset;
  final GetAssetTransactionsUseCase _getTransactions;
  final AddAssetTransactionUseCase _addTransaction;
  final DeleteAssetTransactionUseCase _deleteTransaction;
  final UpdateAssetPriceUseCase _updateAssetPrice;

  InvestmentsCubit(
    this._getAssets,
    this._addAsset,
    this._deleteAsset,
    this._getTransactions,
    this._addTransaction,
    this._deleteTransaction,
    this._updateAssetPrice,
  ) : super(const InvestmentsInitial());

  Future<void> loadInvestments() async {
    emit(const InvestmentsLoading());
    await _doLoad();
  }

  Future<void> refresh() => loadInvestments();

  Future<void> createAsset({
    required String name,
    required String type,
    required String symbol,
    required String unit,
    required double quantity,
    required double pricePerUnit,
    required DateTime date,
    String note = '',
  }) async {
    try {
      final assetId = const Uuid().v4();
      final entity = AssetEntity(
        id: assetId,
        name: name,
        type: type,
        symbol: symbol,
        quantity: 0,
        unit: unit,
        totalCost: 0,
        currentValuePerUnit: pricePerUnit,
        realizedPnL: 0,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
        note: note,
      );
      await _addAsset(entity);
      await _addTransaction(AssetTransactionEntity(
        id: const Uuid().v4(),
        assetId: assetId,
        isBuy: true,
        quantity: quantity,
        pricePerUnit: pricePerUnit,
        date: date,
      ));
      await _doLoad();
    } catch (e) {
      emit(InvestmentsError(e.toString()));
    }
  }

  Future<void> deleteAsset(String id) async {
    try {
      await _deleteAsset(id);
      await _doLoad();
    } catch (e) {
      emit(InvestmentsError(e.toString()));
    }
  }

  Future<void> addTransaction(AssetTransactionEntity tx) async {
    try {
      await _addTransaction(tx);
      await _doLoad();
    } catch (e) {
      emit(InvestmentsError(e.toString()));
    }
  }

  Future<void> deleteTransaction(String txId) async {
    try {
      await _deleteTransaction(txId);
      await _doLoad();
    } catch (e) {
      emit(InvestmentsError(e.toString()));
    }
  }

  Future<void> updatePrice(String assetId, double price) async {
    try {
      await _updateAssetPrice(assetId, price);
      await _doLoad();
    } catch (e) {
      emit(InvestmentsError(e.toString()));
    }
  }

  Future<void> _doLoad() async {
    final assets = _getAssets();
    final txsByAsset = <String, List<AssetTransactionEntity>>{};
    for (final asset in assets) {
      txsByAsset[asset.id] = _getTransactions(asset.id);
    }
    emit(InvestmentsLoaded(assets: assets, transactionsByAsset: txsByAsset));
  }
}
