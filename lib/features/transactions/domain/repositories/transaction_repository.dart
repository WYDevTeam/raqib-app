import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/category_entity.dart';
import '../entities/transaction_entity.dart';
import '../entities/transaction_filter.dart';

abstract class TransactionRepository {
  Future<Either<AppFailure, List<TransactionEntity>>> getTransactions({
    TransactionFilter? filter,
  });

  Future<Either<AppFailure, void>> addTransaction(TransactionEntity transaction);

  Future<Either<AppFailure, void>> updateTransaction(
      TransactionEntity transaction);

  Future<Either<AppFailure, void>> deleteTransaction(String id);

  Future<Either<AppFailure, List<CategoryEntity>>> getCategories();

  Future<Either<AppFailure, void>> addCategory(CategoryEntity category);

  Future<Either<AppFailure, void>> updateCategory(CategoryEntity category);

  Future<Either<AppFailure, void>> deleteCategory(String id);

  Future<bool> categoryHasTransactions(String categoryId);
}
