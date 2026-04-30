import 'package:hive/hive.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../domain/repositories/debts_repository.dart';
import '../models/amanah_model.dart';
import '../models/debt_model.dart';

class DebtsRepositoryImpl implements DebtsRepository {
  final Box<DebtModel> _debtBox;
  final Box<AmanahModel> _amanahBox;

  const DebtsRepositoryImpl({
    required Box<DebtModel> debtBox,
    required Box<AmanahModel> amanahBox,
  })  : _debtBox = debtBox,
        _amanahBox = amanahBox;

  // ── Debts ──────────────────────────────────────────────────────────────────

  @override
  Future<Either<AppFailure, List<DebtModel>>> getDebts() async {
    try {
      final debts = _debtBox.values.toList()
        ..sort((a, b) => b.givenDateMs.compareTo(a.givenDateMs));
      return Right(debts);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, void>> addDebt(DebtModel debt) async {
    try {
      await _debtBox.put(debt.id, debt);
      return const Right(null);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, void>> recordDebtPayment(String debtId, double amount) async {
    try {
      final debt = _debtBox.get(debtId);
      if (debt == null) return Left(const AppFailure('Debt not found'));
      debt.paidAmount = (debt.paidAmount + amount).clamp(0.0, debt.totalAmount);
      if (debt.paidAmount >= debt.totalAmount) debt.isSettled = true;
      await debt.save();
      return const Right(null);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, void>> settleDebt(String debtId) async {
    try {
      final debt = _debtBox.get(debtId);
      if (debt == null) return Left(const AppFailure('Debt not found'));
      debt.paidAmount = debt.totalAmount;
      debt.isSettled = true;
      await debt.save();
      return const Right(null);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // ── Amanah ─────────────────────────────────────────────────────────────────

  @override
  Future<Either<AppFailure, List<AmanahModel>>> getAmanah() async {
    try {
      final amanah = _amanahBox.values.toList()
        ..sort((a, b) => b.receivedDateMs.compareTo(a.receivedDateMs));
      return Right(amanah);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, void>> addAmanah(AmanahModel amanah) async {
    try {
      await _amanahBox.put(amanah.id, amanah);
      return const Right(null);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, void>> recordAmanahReturn(String amanahId, double amount) async {
    try {
      final amanah = _amanahBox.get(amanahId);
      if (amanah == null) return Left(const AppFailure('Amanah not found'));
      amanah.returnedAmount = (amanah.returnedAmount + amount).clamp(0.0, amanah.amount);
      if (amanah.returnedAmount >= amanah.amount) amanah.isReturned = true;
      await amanah.save();
      return const Right(null);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, void>> settleAmanah(String amanahId) async {
    try {
      final amanah = _amanahBox.get(amanahId);
      if (amanah == null) return Left(const AppFailure('Amanah not found'));
      amanah.returnedAmount = amanah.amount;
      amanah.isReturned = true;
      await amanah.save();
      return const Right(null);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }
}
