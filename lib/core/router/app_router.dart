import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/finance/presentation/pages/finance_page.dart';
import '../../features/mindfulness/presentation/pages/journal_page.dart';
import '../../features/planning/presentation/pages/planning_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_shell.dart';
import '../config/app_config.dart';
import 'routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.planning,
    debugLogDiagnostics: AppConfig.instance.isDevelopment,
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.planning,
                name: AppRoutes.planningName,
                builder: (context, state) => const PlanningPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.finance,
                name: AppRoutes.financeName,
                builder: (context, state) => const FinancePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.mindfulness,
                name: AppRoutes.mindfulnessName,
                builder: (context, state) => const JournalPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.settings,
                name: AppRoutes.settingsName,
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: AppEmptyState(
        title: 'Pagina no encontrada',
        message: 'La ruta "${state.uri}" no existe.',
        icon: Icons.explore_off_outlined,
        actionLabel: 'Volver al inicio',
        onAction: () => context.go(AppRoutes.planning),
      ),
    ),
  );
});
