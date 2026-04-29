import '../repositories/settings_repository.dart';

class IsOnboardingCompletedUseCase {
  final SettingsRepository _repository;
  const IsOnboardingCompletedUseCase(this._repository);

  bool call() => _repository.isOnboardingCompleted();
}
