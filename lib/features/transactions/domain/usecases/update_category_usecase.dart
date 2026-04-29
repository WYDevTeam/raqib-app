import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/category_entity.dart';
import '../repositories/transaction_repository.dart';

class UpdateCategoryUseCase {
  final TransactionRepository _repository;
  const UpdateCategoryUseCase(this._repository);

  Future<Either<AppFailure, void>> call(CategoryEntity category) async {
    final catsResult = await _repository.getCategories();
    bool hasDuplicate = false;
    catsResult.fold(
      (_) {},
      (cats) {
        hasDuplicate = cats.any(
          (c) =>
              c.name.trim().toLowerCase() ==
                  category.name.trim().toLowerCase() &&
              c.id != category.id,
        );
      },
    );
    if (hasDuplicate) {
      return Left(AppFailure('توجد فئة بهذا الاسم مسبقاً'));
    }
    return _repository.updateCategory(category);
  }
}
