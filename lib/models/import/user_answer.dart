class UserAnswer {
  final String ambiguousItemId;
  final String chosenOption;
  final String? customText; // لو اختار "غير ذلك"

  const UserAnswer({
    required this.ambiguousItemId,
    required this.chosenOption,
    this.customText,
  });
}
