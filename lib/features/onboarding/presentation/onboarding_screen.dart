import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import 'cubit/onboarding_cubit.dart';
import 'cubit/onboarding_state.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OnboardingCubit>(),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatelessWidget {
  const _OnboardingView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingCubit, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingDone) context.go('/dashboard');
        if (state is OnboardingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: BlocBuilder<OnboardingCubit, OnboardingState>(
        builder: (context, state) {
          final loading = state is OnboardingLoading;
          return Scaffold(
            body: SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    Icon(
                      Icons.account_balance_wallet,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'مرحباً بك في راقب',
                      style: Theme.of(context).textTheme.displaySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'نجمع كل أصولك، ديونك، واستثماراتك في مكان واحد، لتعرف قيمتك الحقيقية ببساطة.',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                    _buildOptionCard(
                      context,
                      icon: Icons.upload_file,
                      title: 'استورد Excel قديم',
                      subtitle: 'سنقوم بتحليل ملفك السابق تلقائياً',
                      onTap: loading
                          ? null
                          : () => context.push('/onboarding/import'),
                    ),
                    const SizedBox(height: 16),
                    _buildOptionCard(
                      context,
                      icon: Icons.edit_note,
                      title: 'أدخل أصولك الموجودة',
                      subtitle: 'أضف ما تملكه الآن خطوة بخطوة',
                      onTap: loading
                          ? null
                          : () => context.push(
                                '/onboarding/initial-assets',
                                extra: context.read<OnboardingCubit>(),
                              ),
                    ),
                    const SizedBox(height: 16),
                    _buildOptionCard(
                      context,
                      icon: Icons.rocket_launch,
                      title: 'ابدأ من الصفر',
                      subtitle: 'محفظة جديدة تماماً',
                      onTap: loading
                          ? null
                          : () =>
                              context.read<OnboardingCubit>().skip(),
                      isPrimary: true,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
        },
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool isPrimary = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isPrimary ? colorScheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border:
              isPrimary ? null : Border.all(color: const Color(0xFFEFEFEF)),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPrimary
                    ? Colors.white.withValues(alpha: 0.2)
                    : colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isPrimary ? Colors.white : colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: isPrimary
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                            ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style:
                        Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isPrimary
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : AppTheme.textSecondary,
                            ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color:
                  isPrimary ? Colors.white : AppTheme.textDisabled,
            ),
          ],
        ),
      ),
    );
  }
}
