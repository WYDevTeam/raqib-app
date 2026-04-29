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

// Carries the last known categories so the UI can still display the list.
final class CategoryError extends CategoryState {
  final String message;
  final List<CategoryEntity> categories;
  const CategoryError(this.message, [this.categories = const []]);
}

final class CategoryOperationSuccess extends CategoryState {
  const CategoryOperationSuccess();
}
