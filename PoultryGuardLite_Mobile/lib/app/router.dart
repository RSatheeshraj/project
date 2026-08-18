import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Screens
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/dashboard/screens/home_dashboard_screen.dart';
import '../features/flock/screens/farms_screen.dart';
import '../features/flock/screens/add_edit_farm_screen.dart';
import '../features/flock/screens/farm_details_screen.dart';
import '../features/flock/models/farm_model.dart';
import '../features/flock/screens/add_edit_batch_screen.dart';
import '../features/flock/models/batch_model.dart';
import '../features/flock/screens/batch_details_screen.dart';
import '../features/flock/models/sales_model.dart';
import '../features/flock/screens/add_edit_entry_screen.dart';
import '../features/flock/screens/add_edit_sales_screen.dart';
import '../features/flock/screens/entries_report_screen.dart';
import '../features/flock/screens/sales_report_screen.dart';
import '../features/flock/screens/entry_details_screen.dart';
import '../features/flock/screens/final_report_screen.dart';
import '../features/flock/models/entry_model.dart';
import '../features/history/screens/reports_screen.dart';
import '../features/profile/screens/settings_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/notifications_screen.dart';
import '../features/profile/screens/security_privacy_screen.dart';
import '../features/profile/screens/change_password_screen.dart';
import '../features/profile/screens/delete_account_screen.dart';
import '../features/scan/models/scan_history_model.dart';
import '../features/scan/screens/ai_result_screen.dart';
import '../features/scan/screens/ai_scan_screen.dart';
import '../features/vet/screens/veterinarian_directory_screen.dart';
import '../features/vet/screens/add_edit_vet_screen.dart';
import '../features/vet/models/vet_model.dart';
import '../features/flock/screens/health_screen.dart';
import '../features/flock/screens/timeline_screen.dart';
import 'scaffold_with_nav_bar.dart';

// ── Route constants ───────────────────────────────────────────────────────────

abstract final class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String flocks = '/flocks';
  static const String addFarm = '/flocks/add';
  static const String editFarm = '/flocks/edit';
  static const String farmDetails = '/flocks/details';
  static const String addBatch = '/flocks/batch-add';
  static const String editBatch = '/flocks/batch-edit';
  static const String batchDetails = '/flocks/batch-details';
  static const String addEntry = '/flocks/entry-add';
  static const String editEntry = '/flocks/entry-edit';
  static const String entryDetails = '/flocks/entry-details';
  static const String addSale = '/flocks/sale-add';
  static const String editSale = '/flocks/sale-edit';
  static const String scan = '/scan';
  static const String scanDetails = '/scan/details';
  static const String history = '/history';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String notifications = '/profile/notifications';
  static const String security = '/profile/security';
  static const String changePassword = '/profile/change-password';
  static const String deleteAccount = '/profile/delete-account';
  static const String vet = '/vet';
  static const String health = '/flocks/health';
  static const String timeline = '/flocks/timeline';
}

// ── Router ────────────────────────────────────────────────────────────────────

abstract final class AppRouter {
  static final _refreshNotifier = _AuthStateNotifier();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: _refreshNotifier,
    redirect: _guard,
    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.history,
        builder: (_, _) => const ReportsScreen(),
      ),


      // The shell wrapping our bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Tab 1: Home Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => const HomeDashboardScreen(),
              ),
            ],
          ),
          // Tab 2: Farms
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.flocks,
                builder: (_, _) => const FarmsScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (_, _) => const AddEditFarmScreen(),
                  ),
                  GoRoute(
                    path: 'edit',
                    builder: (_, state) {
                      final farm = state.extra as FarmModel?;
                      return AddEditFarmScreen(farm: farm);
                    },
                  ),
                  GoRoute(
                    path: 'details',
                    builder: (_, state) {
                      final farm = state.extra as FarmModel;
                      return FarmDetailsScreen(farm: farm);
                    },
                  ),
                  GoRoute(
                    path: 'batch-add',
                    builder: (_, state) {
                      final farm = state.extra as FarmModel;
                      return AddEditBatchScreen(farm: farm);
                    },
                  ),
                  GoRoute(
                    path: 'batch-edit',
                    builder: (_, state) {
                      final data = state.extra as Map<String, dynamic>;
                      return AddEditBatchScreen(
                        farm: data['farm'] as FarmModel,
                        batch: data['batch'] as BatchModel,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'batch-details',
                    builder: (_, state) {
                      final data = state.extra as Map<String, dynamic>;
                      return BatchDetailsScreen(
                        farm: data['farm'] as FarmModel,
                        batch: data['batch'] as BatchModel,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'entry-add',
                    builder: (_, state) {
                      final data = state.extra as Map<String, dynamic>;
                      return AddEditEntryScreen(
                        farm: data['farm'] as FarmModel,
                        batch: data['batch'] as BatchModel,
                        selectedDate: data['selectedDate'] as DateTime?,
                        weekNumber: data['weekNumber'] as int?,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'final-report',
                    builder: (_, state) {
                      final data = state.extra as Map<String, dynamic>;
                      return FinalReportScreen(
                        farm: data['farm'] as FarmModel,
                        batch: data['batch'] as BatchModel,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'entries-report',
                    builder: (context, state) {
                      final extras = state.extra as Map<String, dynamic>;
                      return EntriesReportScreen(
                        farm: extras['farm'] as FarmModel,
                        batch: extras['batch'] as BatchModel,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'sales-report',
                    builder: (context, state) {
                      final extras = state.extra as Map<String, dynamic>;
                      return SalesReportScreen(
                        farm: extras['farm'] as FarmModel,
                        batch: extras['batch'] as BatchModel,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'entry-edit',
                    builder: (_, state) {
                      final data = state.extra as Map<String, dynamic>;
                      return AddEditEntryScreen(
                        farm: data['farm'] as FarmModel,
                        batch: data['batch'] as BatchModel,
                        entry: data['entry'] as EntryModel,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'entry-details',
                    builder: (_, state) {
                      final data = state.extra as Map<String, dynamic>;
                      return EntryDetailsScreen(
                        farm: data['farm'] as FarmModel,
                        batch: data['batch'] as BatchModel,
                        entry: data['entry'] as EntryModel,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'sale-add',
                    builder: (_, state) {
                      final data = state.extra as Map<String, dynamic>;
                      return AddEditSalesScreen(
                        farm: data['farm'] as FarmModel,
                        batch: data['batch'] as BatchModel,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'sale-edit',
                    builder: (_, state) {
                      final data = state.extra as Map<String, dynamic>;
                      return AddEditSalesScreen(
                        farm: data['farm'] as FarmModel,
                        batch: data['batch'] as BatchModel,
                        sale: data['sale'] as SalesModel, // ensure SalesModel is imported
                      );
                    },
                  ),
                  GoRoute(
                    path: 'health',
                    builder: (_, state) {
                      final data = state.extra as Map<String, dynamic>;
                      return HealthScreen(
                        farm: data['farm'] as FarmModel,
                        batch: data['batch'] as BatchModel,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'timeline',
                    builder: (_, state) {
                      final data = state.extra as Map<String, dynamic>;
                      return TimelineScreen(
                        farm: data['farm'] as FarmModel,
                        batch: data['batch'] as BatchModel,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          // Tab 3: AI Scan
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.scan,
                builder: (_, _) => const AiScanScreen(),
                routes: [
                  GoRoute(
                    path: 'details',
                    builder: (_, state) {
                      final item = state.extra as ScanHistoryModel;
                      return AiResultScreen(
                        result: item.result,
                        imageUrl: item.imageUrl,
                        farmName: item.farmName,
                        batchName: item.batchName,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          // Tab 4: Veterinarian
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.vet,
                builder: (_, _) => const VeterinarianDirectoryScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (_, _) => const AddEditVetScreen(),
                  ),
                  GoRoute(
                    path: 'edit',
                    builder: (_, state) {
                      final vet = state.extra as VetModel;
                      return AddEditVetScreen(vet: vet);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Tab 5: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (_, _) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, _) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'notifications',
                    builder: (_, _) => const NotificationsScreen(),
                  ),
                  GoRoute(
                    path: 'security',
                    builder: (_, _) => const SecurityPrivacyScreen(),
                  ),
                  GoRoute(
                    path: 'change-password',
                    builder: (_, _) => const ChangePasswordScreen(),
                  ),
                  GoRoute(
                    path: 'delete-account',
                    builder: (_, _) => const DeleteAccountScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );

  static String? _guard(BuildContext context, GoRouterState state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final loc = state.matchedLocation;

    // If we just registered, stay on the register screen to show the success UI.
    // The RegisterScreen will manually navigate to home after a delay.
    if (isLoggedIn && loc == AppRoutes.register) return null;

    final isAuthRoute = loc == AppRoutes.login || loc == AppRoutes.register;

    if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;
    if (isLoggedIn && isAuthRoute) return AppRoutes.home;
    return null; // no redirect needed
  }
}

// ── Auth state change notifier for GoRouter ───────────────────────────────────

/// Notifies [GoRouter] whenever Firebase auth state changes so the
/// redirect guard re-evaluates automatically.
class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier() {
    _subscription = FirebaseAuth.instance.authStateChanges().listen(
      (_) => notifyListeners(),
    );
  }

  late final StreamSubscription<User?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
