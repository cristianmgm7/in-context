import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:incontext/core/routing/app_routes.dart';
import 'package:incontext/core/routing/pages/error_page.dart';
import 'package:incontext/core/routing/pages/splash_screen.dart';
import 'package:incontext/features/auth/presentation/providers/auth_providers.dart';
import 'package:incontext/features/auth/presentation/screens/login_screen.dart';
import 'package:incontext/features/auth/presentation/screens/register_screen.dart';
// Removed imports for features not yet implemented

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // If auth state is loading, show splash
      if (authState.isLoading) return AppRoutes.splash;

      // If not authenticated, go to login
      if (!isAuthenticated) {
        return AppRoutes.login;
      }

      // If authenticated and on splash/login/register, go to home
      final location = state.matchedLocation;
      if (location == AppRoutes.splash ||
          location == AppRoutes.login ||
          location == AppRoutes.register) {
        return AppRoutes.home;
      }

      // Otherwise, allow the route
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(title: 'Getting ready...'),
      ),

      // Public routes (outside shell)
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Main app route (authenticated)
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text(
              'Welcome to InContext!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    ],
    errorBuilder: (context, state) => ErrorPage(
      error: state.error?.toString(),
    ),
  );
});
