import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/category_entity.dart';
import '../../domain/usecases/add_category_usecase.dart';
import '../../domain/usecases/delete_category_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/update_category_usecase.dart';
import 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  final GetCategoriesUseCase _getCategories;
  final AddCategoryUseCase _addCategory;
  final UpdateCategoryUseCase _updateCategory;
  final DeleteCategoryUseCase _deleteCategory;

  // Cache the last loaded list so errors don't blank the screen.
  List<CategoryEntity> _lastCategories = [];

  CategoryCubit(
    this._getCategories,
    this._addCategory,
    this._updateCategory,
    this._deleteCategory,
  ) : super(const CategoryInitial());

  Future<void> loadCategories() async {
    emit(const CategoryLoading());
    final result = await _getCategories();
    result.fold(
      (failure) => emit(CategoryError(failure.message, _lastCategories)),
      (categories) {
        _lastCategories = categories;
        emit(CategoryLoaded(categories));
      },
    );
  }

  /// Returns true on success, false on failure (error emitted as state).
  Future<bool> addCategory(CategoryEntity category) async {
    final result = await _addCategory(category);
    bool success = false;
    result.fold(
      (failure) => emit(CategoryError(failure.message, _lastCategories)),
      (_) => success = true,
    );
    if (success) await loadCategories();
    return success;
  }

  /// Returns true on success, false on failure.
  Future<bool> updateCategory(CategoryEntity category) async {
    final result = await _updateCategory(category);
    bool success = false;
    result.fold(
      (failure) => emit(CategoryError(failure.message, _lastCategories)),
      (_) => success = true,
    );
    if (success) await loadCategories();
    return success;
  }

  /// Returns true on success (deleted), false when blocked (has transactions).
  Future<bool> deleteCategory(String id) async {
    final result = await _deleteCategory(id);
    bool success = false;
    result.fold(
      (failure) => emit(CategoryError(failure.message, _lastCategories)),
      (_) => success = true,
    );
    if (success) await loadCategories();
    return success;
  }
}
