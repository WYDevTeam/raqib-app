sealed class OnboardingState {
  const OnboardingState();
}

final class OnboardingIdle extends OnboardingState {
  const OnboardingIdle();
}

final class OnboardingLoading extends OnboardingState {
  const OnboardingLoading();
}

final class OnboardingDone extends OnboardingState {
  const OnboardingDone();
}

final class OnboardingError extends OnboardingState {
  final String message;
  const OnboardingError(this.message);
}
