import 'user_answer.dart';

class AmbiguousItem {
  final String id;

  /// 'category' | 'column' | 'amount_direction'
  final String type;

  /// الكاتيغوري أو العمود الغامض
  final String categoryName;

  /// السؤال المعروض للمستخدم (بالعربي)
  final String question;

  /// مثال حقيقي من بيانات الملف
  final String context;

  /// قائمة الخيارات
  final List<String> options;

  /// الخيار الافتراضي المقترح
  final String? defaultOption;

  /// يُملأ بعد إجابة المستخدم
  UserAnswer? answer;

  AmbiguousItem({
    required this.id,
    required this.type,
    required this.categoryName,
    required this.question,
    required this.context,
    required this.options,
    this.defaultOption,
    this.answer,
  });

  factory AmbiguousItem.fromJson(Map<String, dynamic> json) {
    return AmbiguousItem(
      id: json['id'] as String? ?? 'q_${json.hashCode}',
      type: json['type'] as String? ?? 'category',
      categoryName: json['category_name'] as String? ?? '',
      question: json['question'] as String? ?? '',
      context: json['context'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      defaultOption: json['default_option'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'category_name': categoryName,
        'question': question,
        'context': context,
        'options': options,
        'default_option': defaultOption,
      };
}
