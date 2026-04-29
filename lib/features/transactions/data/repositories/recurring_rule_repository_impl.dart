import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/recurring_rule_entity.dart';
import '../../domain/repositories/recurring_rule_repository.dart';
import '../datasources/recurring_rule_hive_datasource.dart';
import '../models/recurring_rule_model.dart';

class RecurringRuleRepositoryImpl implements RecurringRuleRepository {
  final RecurringRuleHiveDatasource _ds;
  const RecurringRuleRepositoryImpl(this._ds);

  @override
  Future<Either<AppFailure, List<RecurringRuleEntity>>> getRules() async {
    try {
      final models = _ds.getRules();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(AppFailure('فشل تحميل القواعد المتكررة: $e'));
    }
  }

  @override
  Future<Either<AppFailure, void>> addRule(RecurringRuleEntity rule) async {
    try {
      await _ds.addRule(RecurringRuleModel.fromEntity(rule));
      return const Right(null);
    } catch (e) {
      return Left(AppFailure('فشل حفظ القاعدة المتكررة: $e'));
    }
  }

  @override
  Future<Either<AppFailure, void>> updateRule(RecurringRuleEntity rule) async {
    try {
      await _ds.updateRule(RecurringRuleModel.fromEntity(rule));
      return const Right(null);
    } catch (e) {
      return Left(AppFailure('فشل تحديث القاعدة المتكررة: $e'));
    }
  }

  @override
  Future<Either<AppFailure, void>> deleteRule(String id) async {
    try {
      await _ds.deleteRule(id);
      return const Right(null);
    } catch (e) {
      return Left(AppFailure('فشل حذف القاعدة المتكررة: $e'));
    }
  }
}
