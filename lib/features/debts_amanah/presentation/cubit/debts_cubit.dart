import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/amanah_model.dart';
import '../../data/models/debt_model.dart';
import '../../domain/usecases/add_amanah_usecase.dart';
import '../../domain/usecases/add_debt_usecase.dart';
import '../../domain/usecases/get_amanah_usecase.dart';
import '../../domain/usecases/get_debts_usecase.dart';
import '../../domain/usecases/record_amanah_return_usecase.dart';
import '../../domain/usecases/record_debt_payment_usecase.dart';
import '../../domain/usecases/settle_amanah_usecase.dart';
import '../../domain/usecases/settle_debt_usecase.dart';
import 'debts_state.dart';

class DebtsCubit extends Cubit<DebtsState> {
  final GetDebtsUseCase _getDebts;
  final AddDebtUseCase _addDebt;
  final RecordDebtPaymentUseCase _recordDebtPayment;
  final SettleDebtUseCase _settleDebt;
  final GetAmanahUseCase _getAmanah;
  final AddAmanahUseCase _addAmanah;
  final RecordAmanahReturnUseCase _recordAmanahReturn;
  final SettleAmanahUseCase _settleAmanah;

  DebtsCubit(
    this._getDebts,
    this._addDebt,
    this._recordDebtPayment,
    this._settleDebt,
    this._getAmanah,
    this._addAmanah,
    this._recordAmanahReturn,
    this._settleAmanah,
  ) : super(const DebtsLoading());

  Future<void> load() async {
    emit(const DebtsLoading());
    final debtsResult = await _getDebts();
    final amanahResult = await _getAmanah();

    debtsResult.fold(
      (failure) => emit(DebtsError(failure.message)),
      (debts) => amanahResult.fold(
        (failure) => emit(DebtsError(failure.message)),
        (amanah) => emit(DebtsLoaded(
          activeDebts: debts.where((d) => !d.isSettled).toList(),
          settledDebts: debts.where((d) => d.isSettled).toList(),
          activeAmanah: amanah.where((a) => !a.isReturned).toList(),
          returnedAmanah: amanah.where((a) => a.isReturned).toList(),
          totalDebtsRemaining: debts
              .where((d) => !d.isSettled)
              .fold(0.0, (sum, d) => sum + d.remainingAmount),
          totalAmanahRemaining: amanah
              .where((a) => !a.isReturned)
              .fold(0.0, (sum, a) => sum + a.remainingAmount),
        )),
      ),
    );
  }

  Future<void> addDebt({
    required String personName,
    required double totalAmount,
    required DateTime givenDate,
    String note = '',
  }) async {
    final debt = DebtModel(
      id: const Uuid().v4(),
      personName: personName,
      totalAmount: totalAmount,
      paidAmount: 0.0,
      givenDateMs: givenDate.millisecondsSinceEpoch,
      note: note,
    );
    final result = await _addDebt(debt);
    if (result.isLeft) {
      result.fold((f) => emit(DebtsError(f.message)), (_) {});
      return;
    }
    await load();
  }

  Future<void> recordDebtPayment(String debtId, double amount) async {
    final result = await _recordDebtPayment(debtId, amount);
    if (result.isLeft) {
      result.fold((f) => emit(DebtsError(f.message)), (_) {});
      return;
    }
    await load();
  }

  Future<void> settleDebt(String debtId) async {
    final result = await _settleDebt(debtId);
    if (result.isLeft) {
      result.fold((f) => emit(DebtsError(f.message)), (_) {});
      return;
    }
    await load();
  }

  Future<void> addAmanah({
    required String personName,
    required double amount,
    required DateTime receivedDate,
    String note = '',
  }) async {
    final amanah = AmanahModel(
      id: const Uuid().v4(),
      personName: personName,
      amount: amount,
      receivedDateMs: receivedDate.millisecondsSinceEpoch,
      note: note,
    );
    final result = await _addAmanah(amanah);
    if (result.isLeft) {
      result.fold((f) => emit(DebtsError(f.message)), (_) {});
      return;
    }
    await load();
  }

  Future<void> recordAmanahReturn(String amanahId, double amount) async {
    final result = await _recordAmanahReturn(amanahId, amount);
    if (result.isLeft) {
      result.fold((f) => emit(DebtsError(f.message)), (_) {});
      return;
    }
    await load();
  }

  Future<void> settleAmanah(String amanahId) async {
    final result = await _settleAmanah(amanahId);
    if (result.isLeft) {
      result.fold((f) => emit(DebtsError(f.message)), (_) {});
      return;
    }
    await load();
  }
}
