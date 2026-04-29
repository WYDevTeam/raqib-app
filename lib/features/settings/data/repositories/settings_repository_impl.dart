import 'package:hive/hive.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../domain/repositories/settings_repository.dart';
import '../models/app_settings_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final Box<AppSettingsModel> _box;
  const SettingsRepositoryImpl(this._box);

  AppSettingsModel get _settings => _box.get('settings') ?? AppSettingsModel();

  @override
  bool isOnboardingCompleted() => _settings.onboardingCompleted;

  @override
  Future<Either<AppFailure, void>> completeOnboarding() async {
    try {
      final s = _settings;
      s.onboardingCompleted = true;
      await _box.put('settings', s);
      return const Right(null);
    } catch (e) {
      return Left(AppFailure('فشل حفظ الإعدادات: $e'));
    }
  }
}
