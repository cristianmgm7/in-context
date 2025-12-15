import 'package:incontext/core/routing/app_routes.dart';

/// Helper function for authentication redirect logic
/// Simplified version for now
String? authRedirectLogic({
  required bool isAuthenticated,
  required bool hasProfile,
  required String currentLocation,
}) {
  // If not authenticated, go to login
  if (!isAuthenticated) {
    if (currentLocation != AppRoutes.login && currentLocation != AppRoutes.register) {
      return AppRoutes.login;
    }
  }

  // If authenticated and on auth pages, go to home
  if (isAuthenticated) {
    if (currentLocation == AppRoutes.login || currentLocation == AppRoutes.register) {
      return AppRoutes.home;
    }
  }

  return null; // No redirect needed
}


