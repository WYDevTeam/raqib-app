import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_filter.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/category_hive_datasource.dart';
import '../datasources/transaction_hive_datasource.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionHiveDatasource _transactionDs;
  final CategoryHiveDatasource _categoryDs;

  const TransactionRepositoryImpl(this._transactionDs, this._categoryDs);

  @override
  Future<Either<AppFailure, List<TransactionEntity>>> getTransactions({
    TransactionFilter? filter,
  }) async {
    try {
      final models = _transactionDs.getTransactions(filter: filter);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(AppFailure('فشل تحميل المعاملات: $e'));
    }
  }

  @override
  Future<Either<AppFailure, void>> addTransaction(
      TransactionEntity transaction) async {
    try {
      await _transactionDs
          .addTransaction(TransactionModel.fromEntity(transaction));
      return const Right(null);
    } catch (e) {
      return Left(AppFailure('فشل حفظ المعاملة: $e'));
    }
  }

  @override
  Future<Either<AppFailure, void>> updateTransaction(
      TransactionEntity transaction) async {
    try {
      await _transactionDs
          .updateTransaction(TransactionModel.fromEntity(transaction));
      return const Right(null);
    } catch (e) {
      return Left(AppFailure('فشل تحديث المعاملة: $e'));
    }
  }

  @override
  Future<Either<AppFailure, void>> deleteTransaction(String id) async {
    try {
      await _transactionDs.deleteTransaction(id);
      return const Right(null);
    } catch (e) {
      return Left(AppFailure('فشل حذف المعاملة: $e'));
    }
  }

  @override
  Future<Either<AppFailure, List<CategoryEntity>>> getCategories() async {
    try {
      final models = _categoryDs.getCategories();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(AppFailure('فشل تحميل الفئات: $e'));
    }
  }

  @override
  Future<Either<AppFailure, void>> addCategory(CategoryEntity category) async {
    try {
      await _categoryDs.addCategory(CategoryModel.fromEntity(category));
      return const Right(null);
    } catch (e) {
      return Left(AppFailure('فشل حفظ الفئة: $e'));
    }
  }

  @override
  Future<Either<AppFailure, void>> updateCategory(
      CategoryEntity category) async {
    try {
      await _categoryDs.updateCategory(CategoryModel.fromEntity(category));
      return const Right(null);
    } catch (e) {
      return Left(AppFailure('فشل تحديث الفئة: $e'));
    }
  }

  @override
  Future<Either<AppFailure, void>> deleteCategory(String id) async {
    try {
      await _categoryDs.deleteCategory(id);
      return const Right(null);
    } catch (e) {
      return Left(AppFailure('فشل حذف الفئة: $e'));
    }
  }

  @override
  Future<bool> categoryHasTransactions(String categoryId) async {
    return _transactionDs.transactionExistsForCategory(categoryId);
  }
}
