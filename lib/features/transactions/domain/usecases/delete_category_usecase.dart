import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../repositories/transaction_repository.dart';

class DeleteCategoryUseCase {
  final TransactionRepository _repository;
  const DeleteCategoryUseCase(this._repository);

  Future<Either<AppFailure, void>> call(String categoryId) async {
    final hasTransactions =
        await _repository.categoryHasTransactions(categoryId);
    if (hasTransactions) {
      return const Left(
          AppFailure('لا يمكن حذف فئة تحتوي على معاملات مسجّلة'));
    }
    return _repository.deleteCategory(categoryId);
  }
}
