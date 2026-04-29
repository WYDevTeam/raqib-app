import 'package:hive/hive.dart';

import '../../domain/entities/asset_entity.dart';
import '../../domain/entities/asset_transaction_entity.dart';
import '../../domain/repositories/investments_repository.dart';
import '../models/asset_model.dart';
import '../models/asset_transaction_model.dart';

class InvestmentsRepositoryImpl implements InvestmentsRepository {
  final Box<AssetModel> _assetBox;
  final Box<AssetTransactionModel> _txBox;

  const InvestmentsRepositoryImpl({
    required Box<AssetModel> assetBox,
    required Box<AssetTransactionModel> txBox,
  })  : _assetBox = assetBox,
        _txBox = txBox;

  @override
  List<AssetEntity> getAssets() {
    return _assetBox.values.map(_toEntity).toList()
      ..sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
  }

  @override
  List<AssetTransactionEntity> getTransactions(String assetId) {
    return _txBox.values
        .where((t) => t.assetId == assetId)
        .map(_txToEntity)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<void> addAsset(AssetEntity entity) async {
    final model = AssetModel(
      id: entity.id,
      name: entity.name,
      type: entity.type,
      symbol: entity.symbol,
      quantity: 0,
      unit: entity.unit,
      totalCost: 0,
      currentValuePerUnit: entity.currentValuePerUnit,
      realizedPnL: 0,
      createdAtMs: entity.createdAtMs,
      note: entity.note,
    );
    await _assetBox.put(model.id, model);
  }

  @override
  Future<void> deleteAsset(String id) async {
    await _assetBox.delete(id);
    final txIds = _txBox.values
        .where((t) => t.assetId == id)
        .map((t) => t.id)
        .toList();
    for (final txId in txIds) {
      await _txBox.delete(txId);
    }
  }

  @override
  Future<void> addTransaction(AssetTransactionEntity tx) async {
    final model = AssetTransactionModel(
      id: tx.id,
      assetId: tx.assetId,
      isBuy: tx.isBuy,
      quantity: tx.quantity,
      pricePerUnit: tx.pricePerUnit,
      dateMs: tx.date.millisecondsSinceEpoch,
      note: tx.note,
    );
    await _txBox.put(model.id, model);
    await _recalculateAsset(tx.assetId);
  }

  @override
  Future<void> deleteTransaction(String txId) async {
    final tx = _txBox.get(txId);
    final assetId = tx?.assetId;
    await _txBox.delete(txId);
    if (assetId != null) await _recalculateAsset(assetId);
  }

  // ── P&L recalculation (avg-cost method) ──────────────────────────────────

  Future<void> _recalculateAsset(String assetId) async {
    final txs = _txBox.values
        .where((t) => t.assetId == assetId)
        .toList()
      ..sort((a, b) => a.dateMs.compareTo(b.dateMs));

    double qty = 0, cost = 0, realized = 0;
    for (final tx in txs) {
      if (tx.isBuy) {
        qty += tx.quantity;
        cost += tx.quantity * tx.pricePerUnit;
      } else {
        if (qty > 0) {
          final avgCost = cost / qty;
          realized += (tx.pricePerUnit - avgCost) * tx.quantity;
          cost -= avgCost * tx.quantity;
          qty -= tx.quantity;
        }
      }
    }

    final asset = _assetBox.get(assetId);
    if (asset != null) {
      asset.quantity = qty.clamp(0, double.infinity);
      asset.totalCost = cost.clamp(0, double.infinity);
      asset.realizedPnL = realized;
      await asset.save();
    }
  }

  AssetEntity _toEntity(AssetModel m) => AssetEntity(
        id: m.id,
        name: m.name,
        type: m.type,
        symbol: m.symbol,
        quantity: m.quantity,
        unit: m.unit,
        totalCost: m.totalCost,
        currentValuePerUnit: m.currentValuePerUnit,
        realizedPnL: m.realizedPnL,
        lastPriceUpdateMs: m.lastPriceUpdateMs,
        createdAtMs: m.createdAtMs,
        note: m.note,
      );

  AssetTransactionEntity _txToEntity(AssetTransactionModel m) =>
      AssetTransactionEntity(
        id: m.id,
        assetId: m.assetId,
        isBuy: m.isBuy,
        quantity: m.quantity,
        pricePerUnit: m.pricePerUnit,
        date: m.date,
        note: m.note,
      );
}
