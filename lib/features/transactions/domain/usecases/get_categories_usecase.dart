import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/category_entity.dart';
import '../repositories/transaction_repository.dart';

class GetCategoriesUseCase {
  final TransactionRepository _repository;
  const GetCategoriesUseCase(this._repository);

  Future<Either<AppFailure, List<CategoryEntity>>> call() {
    return _repository.getCategories();
  }
}
