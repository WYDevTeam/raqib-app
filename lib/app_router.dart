import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/widgets/main_shell_screen.dart';
import 'features/budget/presentation/add_budget_screen.dart';
import 'features/budget/presentation/budget_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/dashboard/presentation/formula_builder_screen.dart';
import 'features/debts_amanah/presentation/add_debt_amanah_screen.dart';
import 'features/debts_amanah/presentation/debts_amanah_screen.dart';
import 'features/investments/presentation/add_investment_screen.dart';
import 'features/investments/presentation/asset_details_screen.dart';
import 'features/investments/presentation/investments_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/subscription/presentation/subscription_screen.dart';
import 'features/transactions/domain/entities/category_entity.dart';
import 'features/transactions/domain/entities/transaction_entity.dart';
import 'features/transactions/presentation/add_category_screen.dart';
import 'features/transactions/presentation/add_transaction_screen.dart';
import 'features/transactions/presentation/categories_management_screen.dart';
import 'features/transactions/presentation/recurring_rules_screen.dart';
import 'features/transactions/presentation/transactions_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/subscription',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SubscriptionScreen(),
    ),
    GoRoute(
      path: '/investments/add',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AddInvestmentScreen(),
    ),

    // ── Categories (root-level full-screen) ─────────────────────────────────
    GoRoute(
      path: '/categories',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CategoriesManagementScreen(),
      routes: [
        GoRoute(
          path: 'add',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final category = state.extra as CategoryEntity?;
            return AddCategoryScreen(category: category);
          },
        ),
      ],
    ),

    // ── Recurring Rules Management (root-level full-screen) ──────────────────
    GoRoute(
      path: '/recurring-rules',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RecurringRulesScreen(),
    ),

    // ── Bottom nav shell ─────────────────────────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShellScreen(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
              routes: [
                GoRoute(
                  path: 'settings',
                  builder: (context, state) => const SettingsScreen(),
                  routes: [
                    GoRoute(
                      path: 'formula-builder',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) {
                        final extra =
                            state.extra as Map<String, dynamic>?;
                        return FormulaBuilderScreen(
                          initialTitle: extra?['title'] as String?,
                          initialFormulaParts:
                              extra?['formulaParts'] as List<String>?,
                        );
                      },
                    ),
                  ],
                ),
                GoRoute(
                  path: 'formula-builder',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) =>
                      const FormulaBuilderScreen(),
                ),
              ],
            ),
          ],
        ),

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/transactions',
              builder: (context, state) => const TransactionsScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final transaction =
                        state.extra as TransactionEntity?;
                    return AddTransactionScreen(
                        transaction: transaction);
                  },
                ),
              ],
            ),
          ],
        ),

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/investments',
              builder: (context, state) => const InvestmentsScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const AddInvestmentScreen(),
                ),
                GoRoute(
                  path: 'details',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final extra =
                        state.extra as Map<String, dynamic>?;
                    return AssetDetailsScreen(
                      assetName: extra?['assetName'] as String? ??
                          'تفاصيل الأصل',
                    );
                  },
                ),
              ],
            ),
          ],
        ),

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/debts',
              builder: (context, state) => const DebtsAmanahScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) =>
                      const AddDebtAmanahScreen(),
                ),
              ],
            ),
          ],
        ),

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/budget',
              builder: (context, state) => const BudgetScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const AddBudgetScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
