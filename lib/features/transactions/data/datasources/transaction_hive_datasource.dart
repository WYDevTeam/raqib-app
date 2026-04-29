import 'package:hive/hive.dart';

import '../../domain/entities/transaction_filter.dart';
import '../models/transaction_model.dart';

class TransactionHiveDatasource {
  final Box<TransactionModel> _box;
  const TransactionHiveDatasource(this._box);

  List<TransactionModel> getTransactions({TransactionFilter? filter}) {
    final all = _box.values.toList();

    var result = all;
    if (filter != null) {
      result = all.where((t) {
        if (filter.isIncome != null && t.isIncome != filter.isIncome) {
          return false;
        }
        if (filter.startDate != null && t.date.isBefore(filter.startDate!)) {
          return false;
        }
        if (filter.endDate != null) {
          final endOfDay = DateTime(
            filter.endDate!.year,
            filter.endDate!.month,
            filter.endDate!.day,
            23,
            59,
            59,
          );
          if (t.date.isAfter(endOfDay)) return false;
        }
        if (filter.categoryIds != null &&
            filter.categoryIds!.isNotEmpty &&
            !filter.categoryIds!.contains(t.categoryId)) {
          return false;
        }
        return true;
      }).toList();
    }

    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  Future<void> addTransaction(TransactionModel model) async {
    await _box.put(model.id, model);
  }

  Future<void> updateTransaction(TransactionModel model) async {
    await _box.put(model.id, model);
  }

  Future<void> deleteTransaction(String id) async {
    await _box.delete(id);
  }

  bool transactionExistsForCategory(String categoryId) {
    return _box.values.any((t) => t.categoryId == categoryId);
  }
}
