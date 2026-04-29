sealed class Either<L, R> {
  const Either();

  void fold(void Function(L) onLeft, void Function(R) onRight);

  bool get isLeft => this is Left<L, R>;
  bool get isRight => this is Right<L, R>;
}

final class Left<L, R> extends Either<L, R> {
  final L value;
  const Left(this.value);

  @override
  void fold(void Function(L) onLeft, void Function(R) onRight) => onLeft(value);
}

final class Right<L, R> extends Either<L, R> {
  final R value;
  const Right(this.value);

  @override
  void fold(void Function(L) onLeft, void Function(R) onRight) => onRight(value);
}
