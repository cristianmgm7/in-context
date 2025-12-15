class AppRoutes {
  AppRoutes._();

  // Authentication routes
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';

  // Main app routes
  static const String home = '/';
  static const String projects = '/projects';
  static String projectDetail(String id) => '/projects/$id';
}
