/// Shared in-memory category store.
/// Will be replaced by BLoC/Hive persistence in a future iteration.
class CategoryService {
  CategoryService._();

  static final List<String> _categories = [
    'طعام وشراب',
    'مواصلات',
    'سكن',
    'دخل أساسي',
    'ترفيه',
    'صحة',
    'تعليم',
  ];

  static List<String> get categories => List.unmodifiable(_categories);

  static void addCategory(String name) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty && !_categories.contains(trimmed)) {
      _categories.add(trimmed);
    }
  }

  static void removeCategory(String name) {
    _categories.remove(name);
  }
}
