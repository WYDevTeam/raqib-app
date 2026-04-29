enum CategoryType {
  income,
  expense,
  both;

  String get arabicLabel => switch (this) {
        CategoryType.income => 'دخل',
        CategoryType.expense => 'مصروف',
        CategoryType.both => 'الكلاهما',
      };

  int get hiveValue => index;

  static CategoryType fromInt(int v) => switch (v) {
        0 => CategoryType.income,
        1 => CategoryType.expense,
        _ => CategoryType.both,
      };
}

class CategoryEntity {
  final String id;
  final String name;
  final int iconCodePoint;
  final int colorValue;
  final CategoryType type;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    required this.type,
  });

  CategoryEntity copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    int? colorValue,
    CategoryType? type,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      type: type ?? this.type,
    );
  }
}
