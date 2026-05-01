import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../data/models/amanah_model.dart';
import '../../data/models/debt_model.dart';

abstract class DebtsRepository {
  Future<Either<AppFailure, List<DebtModel>>> getDebts();
  Future<Either<AppFailure, void>> addDebt(DebtModel debt);
  Future<Either<AppFailure, void>> recordDebtPayment(String debtId, double amount);
  Future<Either<AppFailure, void>> settleDebt(String debtId);
  Future<Either<AppFailure, void>> updateDebt(DebtModel debt);

  Future<Either<AppFailure, List<AmanahModel>>> getAmanah();
  Future<Either<AppFailure, void>> addAmanah(AmanahModel amanah);
  Future<Either<AppFailure, void>> recordAmanahReturn(String amanahId, double amount);
  Future<Either<AppFailure, void>> settleAmanah(String amanahId);
  Future<Either<AppFailure, void>> updateAmanah(AmanahModel amanah);
}
