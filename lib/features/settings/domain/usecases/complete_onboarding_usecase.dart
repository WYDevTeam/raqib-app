import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../repositories/settings_repository.dart';

class CompleteOnboardingUseCase {
  final SettingsRepository _repository;
  const CompleteOnboardingUseCase(this._repository);

  Future<Either<AppFailure, void>> call() => _repository.completeOnboarding();
}
