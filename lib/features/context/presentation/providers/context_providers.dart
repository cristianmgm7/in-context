import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:incontext/core/providers/core_providers.dart';
import 'package:incontext/core/utils/result.dart';
import 'package:incontext/features/context/data/repositories/firebase_context_repository.dart';
import 'package:incontext/features/context/data/repositories/firebase_output_repository.dart';
import 'package:incontext/features/context/data/repositories/firebase_project_repository.dart';
import 'package:incontext/features/context/data/repositories/firebase_thought_repository.dart';
import 'package:incontext/features/context/domain/entities/project_entity.dart';
import 'package:incontext/features/context/domain/entities/thought_entity.dart';
import 'package:incontext/features/context/domain/entities/context_entity.dart';
import 'package:incontext/features/context/domain/entities/output_entity.dart';
import 'package:incontext/features/context/domain/repositories/context_repository.dart';
import 'package:incontext/features/context/domain/repositories/output_repository.dart';
import 'package:incontext/features/context/domain/repositories/project_repository.dart';
import 'package:incontext/features/context/domain/repositories/thought_repository.dart';

/// *** REPOSITORIES *** ///
/// Project repository provider
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return FirebaseProjectRepository(firestore, firebaseAuth);
});

/// Thought repository provider
final thoughtRepositoryProvider = Provider<ThoughtRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return FirebaseThoughtRepository(firestore, firebaseAuth);
});

/// Context repository provider
final contextRepositoryProvider = Provider<ContextRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return FirebaseContextRepository(firestore, firebaseAuth);
});

/// Output repository provider
final outputRepositoryProvider = Provider<OutputRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return FirebaseOutputRepository(firestore, firebaseAuth);
});

/// *** STREAM PROVIDERS *** ///
/// Stream provider for all projects
final projectsStreamProvider = StreamProvider((ref) {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.watchProjects();
});

/// Provider family for a specific project
final projectProvider =
    FutureProvider.family<ProjectEntity, String>((ref, projectId) async {
  final repository = ref.watch(projectRepositoryProvider);
  final result = await repository.getProject(projectId);
  return result.when(
    success: (project) => project,
    error: (failure) => throw failure,
  );
});

/// Stream provider family for thoughts in a project
final thoughtsStreamProvider =
    StreamProvider.family<List<ThoughtEntity>, String>((ref, projectId) {
  final repository = ref.watch(thoughtRepositoryProvider);
  return repository.watchThoughts(projectId);
});

/// Stream provider family for context in a project
final contextStreamProvider =
    StreamProvider.family<ContextEntity?, String>((ref, projectId) {
  final repository = ref.watch(contextRepositoryProvider);
  return repository.watchContextForProject(projectId);
});

/// Stream provider family for outputs for a context
final outputsStreamProvider =
    StreamProvider.family<List<OutputEntity>, String>((ref, contextId) {
  final repository = ref.watch(outputRepositoryProvider);
  return repository.watchOutputs(contextId);
});
