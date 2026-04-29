import 'package:hive/hive.dart';

import '../models/recurring_rule_model.dart';

class RecurringRuleHiveDatasource {
  final Box<RecurringRuleModel> _box;
  const RecurringRuleHiveDatasource(this._box);

  List<RecurringRuleModel> getRules() => _box.values.toList();

  Future<void> addRule(RecurringRuleModel model) async {
    await _box.put(model.id, model);
  }

  Future<void> updateRule(RecurringRuleModel model) async {
    await _box.put(model.id, model);
  }

  Future<void> deleteRule(String id) async {
    await _box.delete(id);
  }
}
