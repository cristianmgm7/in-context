import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:incontext/core/providers/core_providers.dart';
import 'package:incontext/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:incontext/features/auth/domain/entities/user_entity.dart';
import 'package:incontext/features/auth/domain/repositories/auth_repository.dart';
// import 'package:incontext/features/auth/domain/usecases/check_user_profile.dart'; // Removed for simplicity
// import 'package:incontext/features/profile/presentation/providers/user_profile_providers.dart'; // TODO: Add when profile feature is added

/// AuthRepository provider (direct Riverpod, no GetIt bridging)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final googleSignIn = ref.watch(googleSignInProvider);
  return FirebaseAuthRepository(firebaseAuth, googleSignIn);
});

/// Stream provider for authentication state
/// This is the single source of truth for auth state in the app
final authStateProvider = StreamProvider<UserEntity?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges();
});

/// Provider to get current user synchronously
final currentUserProvider = Provider<UserEntity?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

/// Provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).valueOrNull != null;
});

// Simplified user status for now - just checks auth state
final userStatusProvider = Provider<UserStatus>((ref) {
  final authState = ref.watch(authStateProvider);

  if (authState.isLoading) {
    return const UserStatus(
      authStatus: AuthStatus.unknown,
      hasProfile: false,
      hasOnboardingPending: false,
    );
  }

  return UserStatus(
    authStatus: authState.value != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    hasProfile: false, // Simplified for now
    hasOnboardingPending: false,
  );
});

enum AuthStatus { unknown, authenticated, unauthenticated }

base class UserStatus {
  const UserStatus({
    required this.authStatus,
    required this.hasProfile,
    required this.hasOnboardingPending,
  });

  final AuthStatus authStatus;
  final bool hasProfile;
  final bool hasOnboardingPending;
}
