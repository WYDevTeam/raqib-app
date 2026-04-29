import '../../domain/entities/category_entity.dart';

sealed class CategoryState {
  const CategoryState();
}

final class CategoryInitial extends CategoryState {
  const CategoryInitial();
}

final class CategoryLoading extends CategoryState {
  const CategoryLoading();
}

final class CategoryLoaded extends CategoryState {
  final List<CategoryEntity> categories;
  const CategoryLoaded(this.categories);
}

final class CategoryError extends CategoryState {
  final String message;
  const CategoryError(this.message);
}

final class CategoryOperationSuccess extends CategoryState {
  const CategoryOperationSuccess();
}
