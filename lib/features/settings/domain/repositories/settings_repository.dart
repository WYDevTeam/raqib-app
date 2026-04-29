import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';

abstract class SettingsRepository {
  Future<Either<AppFailure, void>> completeOnboarding();
  bool isOnboardingCompleted();
}
