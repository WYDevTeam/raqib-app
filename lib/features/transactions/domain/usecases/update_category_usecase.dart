import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/category_entity.dart';
import '../repositories/transaction_repository.dart';

class UpdateCategoryUseCase {
  final TransactionRepository _repository;
  const UpdateCategoryUseCase(this._repository);

  Future<Either<AppFailure, void>> call(CategoryEntity category) {
    return _repository.updateCategory(category);
  }
}
