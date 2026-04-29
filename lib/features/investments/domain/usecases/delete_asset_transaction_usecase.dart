import '../repositories/investments_repository.dart';

class DeleteAssetTransactionUseCase {
  final InvestmentsRepository _repo;
  const DeleteAssetTransactionUseCase(this._repo);

  Future<void> call(String txId) => _repo.deleteTransaction(txId);
}
