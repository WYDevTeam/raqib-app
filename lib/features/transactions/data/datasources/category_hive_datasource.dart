import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/category_model.dart';

class CategoryHiveDatasource {
  final Box<CategoryModel> _box;
  const CategoryHiveDatasource(this._box);

  List<CategoryModel> getCategories() => _box.values.toList();

  Future<void> addCategory(CategoryModel model) async {
    await _box.put(model.id, model);
  }

  Future<void> updateCategory(CategoryModel model) async {
    await _box.put(model.id, model);
  }

  Future<void> deleteCategory(String id) async {
    await _box.delete(id);
  }

  Future<void> seedDefaultsIfEmpty() async {
    if (_box.isNotEmpty) return;
    const uuid = Uuid();
    final defaults = [
      CategoryModel(
          id: uuid.v4(),
          name: 'طعام وشراب',
          iconCodePoint: Icons.restaurant.codePoint,
          colorValue: 0xFFFF6B6B,
          typeValue: 1),
      CategoryModel(
          id: uuid.v4(),
          name: 'مواصلات',
          iconCodePoint: Icons.directions_car.codePoint,
          colorValue: 0xFF4ECDC4,
          typeValue: 1),
      CategoryModel(
          id: uuid.v4(),
          name: 'سكن',
          iconCodePoint: Icons.home.codePoint,
          colorValue: 0xFF45B7D1,
          typeValue: 1),
      CategoryModel(
          id: uuid.v4(),
          name: 'دخل أساسي',
          iconCodePoint: Icons.account_balance_wallet.codePoint,
          colorValue: 0xFF10C469,
          typeValue: 0),
      CategoryModel(
          id: uuid.v4(),
          name: 'ترفيه',
          iconCodePoint: Icons.sports_esports.codePoint,
          colorValue: 0xFFF9C74F,
          typeValue: 1),
      CategoryModel(
          id: uuid.v4(),
          name: 'صحة',
          iconCodePoint: Icons.local_hospital.codePoint,
          colorValue: 0xFFFF9A9A,
          typeValue: 1),
      CategoryModel(
          id: uuid.v4(),
          name: 'تعليم',
          iconCodePoint: Icons.school.codePoint,
          colorValue: 0xFF7EC8E3,
          typeValue: 1),
      CategoryModel(
          id: uuid.v4(),
          name: 'تسوق',
          iconCodePoint: Icons.shopping_bag.codePoint,
          colorValue: 0xFFBB86FC,
          typeValue: 1),
      CategoryModel(
          id: uuid.v4(),
          name: 'راتب',
          iconCodePoint: Icons.payments.codePoint,
          colorValue: 0xFF2E6FF2,
          typeValue: 0),
    ];
    for (final cat in defaults) {
      await _box.put(cat.id, cat);
    }
  }
}
