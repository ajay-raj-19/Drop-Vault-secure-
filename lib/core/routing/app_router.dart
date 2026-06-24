import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/main_layout_shell.dart';
import '../providers/onboarding_provider.dart';

// Import all presentation screens
import '../../features/onboarding/presentation/splash_screen_01.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/create_account_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/dashboard/presentation/home_dashboard_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/vault/presentation/add_item_screen.dart';
import '../../features/vault/presentation/filtered_items_screen.dart';
import '../../features/vault/presentation/my_collection_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/account_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/help/presentation/help_screen.dart';
import '../../features/settings/presentation/privacy_policy_screen.dart';
import '../../features/settings/presentation/terms_screen.dart';
import '../../features/profile/presentation/about_developer_screen.dart';
import '../../features/trash/presentation/trash_screen.dart';
import '../../features/reminder/presentation/reminder_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/vault/presentation/collection_items_screen.dart';
import '../../features/vault/presentation/note_viewer_screen.dart';
import '../../features/backup/presentation/backup_restore_screen.dart';
import '../providers/providers.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/domain/auth_state.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorDashboardKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorSearchKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorAddKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorVaultKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorProfileKey = GlobalKey<NavigatorState>();

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final onboardingCompleted = ref.watch(onboardingCompletedProvider);

  return GoRouter(
    initialLocation: onboardingCompleted ? '/login' : '/splash',
    navigatorKey: _rootNavigatorKey,
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges),
    redirect: (context, state) {
      final authState = authRepository.currentAuthState;
      final isAuthenticated = authState.status == AuthStatus.authenticated;

      final currentLocation = state.matchedLocation;
      final isOnSplash = currentLocation == '/splash';
      final isOnLogin = currentLocation == '/login';
      final isOnSignUp = currentLocation == '/signup';
      final isOnForgot = currentLocation == '/forgot-password';
      final isAuthRoute = isOnLogin || isOnSignUp || isOnForgot;

      // ── CASE 1: Onboarding not completed → show splash screens
      if (!onboardingCompleted) {
        // Allow splash screen; redirect everything else to splash
        if (!isOnSplash) {
          return '/splash';
        }
        return null;
      }

      // ── CASE 2: Onboarding completed + NOT authenticated → login
      if (!isAuthenticated) {
        // If user somehow lands on splash after onboarding, redirect to login
        if (isOnSplash) {
          return '/login';
        }
        // Allow auth routes (login, signup, forgot-password)
        if (isAuthRoute) {
          return null;
        }
        // Redirect everything else (dashboard, etc.) to login
        return '/login';
      }

      // ── CASE 3: Onboarding completed + authenticated → dashboard
      // Redirect auth/onboarding routes to dashboard
      if (isOnSplash || isAuthRoute) {
        return '/main/dashboard';
      }

      return null;
    },
    routes: [
      // Onboarding Screens
      GoRoute(
        path: '/splash',
        builder: (context, state) => const DropVaultSplashScreen(),
      ),
      
      // Auth Screens
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final prefilledEmail = extra?['email'] as String?;
          final prefilledPhoto = extra?['profileImagePath'] as String?;
          return SignUpPage(
            prefilledEmail: prefilledEmail,
            prefilledPhoto: prefilledPhoto,
          );
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),

      // Filtered Items by Category
      GoRoute(
        path: '/items/:category',
        builder: (context, state) {
          final category = state.pathParameters['category'] ?? 'link';
          return FilteredItemsScreen(categoryType: category);
        },
      ),

      // Collection Detail Screen
      GoRoute(
        path: '/collection/:name',
        builder: (context, state) {
          final name = state.pathParameters['name'] ?? '';
          return CollectionItemsScreen(collectionName: name);
        },
      ),

      // Note Viewer Screen
      GoRoute(
        path: '/viewer/note',
        builder: (context, state) {
          final item = state.extra as VaultItem;
          return NoteViewerScreen(item: item);
        },
      ),

      // Stateful Navigation Shell (Persistent Bottom Navigation Bar)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayoutShell(navigationShell: navigationShell);
        },
        branches: [
          // Tab 1: Dashboard Branch
          StatefulShellBranch(
            navigatorKey: _shellNavigatorDashboardKey,
            routes: [
              GoRoute(
                path: '/main/dashboard',
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          // Tab 2: Search Branch
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSearchKey,
            routes: [
              GoRoute(
                path: '/main/search',
                builder: (context, state) => const SearchPage(),
              ),
            ],
          ),
          // Tab 3: Add Item Branch
          StatefulShellBranch(
            navigatorKey: _shellNavigatorAddKey,
            routes: [
              GoRoute(
                path: '/main/add',
                builder: (context, state) => const AddItemPage(),
              ),
            ],
          ),
          // Tab 4: Vault/Collections Branch
          StatefulShellBranch(
            navigatorKey: _shellNavigatorVaultKey,
            routes: [
              GoRoute(
                path: '/main/vault',
                builder: (context, state) => const CollectionsPage(),
              ),
            ],
          ),
          // Tab 5: Profile Branch
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfileKey,
            routes: [
              GoRoute(
                path: '/main/profile',
                builder: (context, state) => const ProfilePage(),
                routes: [
                  // Sub-routes under Profile Tab
                  GoRoute(
                    path: 'account',
                    builder: (context, state) => const AccountPage(),
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsPage(),
                  ),
                  GoRoute(
                    path: 'help',
                    builder: (context, state) => const HelpSupportPage(),
                  ),
                  GoRoute(
                    path: 'trash',
                    builder: (context, state) => const TrashPage(),
                  ),
                  GoRoute(
                    path: 'reminder',
                    builder: (context, state) => const RemindersPage(),
                  ),
                  GoRoute(
                    path: 'edit-profile',
                    builder: (context, state) => const EditProfilePage(),
                  ),
                  GoRoute(
                    path: 'privacy-policy',
                    builder: (context, state) => const PrivacyPolicyPage(),
                  ),
                  GoRoute(
                    path: 'terms',
                    builder: (context, state) => const TermsOfServicePage(),
                  ),
                  GoRoute(
                    path: 'about-developer',
                    builder: (context, state) => const AboutDeveloperPage(),
                  ),
                  GoRoute(
                    path: 'backup',
                    builder: (context, state) => const BackupRestorePage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
