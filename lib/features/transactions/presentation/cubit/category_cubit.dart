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
      (failure) => emit(CategoryError(failure.message)),
      (categories) => emit(CategoryLoaded(categories)),
    );
  }

  Future<void> addCategory(CategoryEntity category) async {
    final result = await _addCategory(category);
    result.fold(
      (failure) => emit(CategoryError(failure.message)),
      (_) => loadCategories(),
    );
  }

  Future<void> updateCategory(CategoryEntity category) async {
    final result = await _updateCategory(category);
    result.fold(
      (failure) => emit(CategoryError(failure.message)),
      (_) => loadCategories(),
    );
  }

  Future<bool> deleteCategory(String id) async {
    final result = await _deleteCategory(id);
    bool success = false;
    result.fold(
      (failure) => emit(CategoryError(failure.message)),
      (_) {
        success = true;
        loadCategories();
      },
    );
    return success;
  }
}
