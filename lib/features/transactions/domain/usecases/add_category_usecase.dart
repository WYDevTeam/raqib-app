import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/category_entity.dart';
import '../repositories/transaction_repository.dart';

class AddCategoryUseCase {
  final TransactionRepository _repository;
  const AddCategoryUseCase(this._repository);

  Future<Either<AppFailure, void>> call(CategoryEntity category) {
    return _repository.addCategory(category);
  }
}
