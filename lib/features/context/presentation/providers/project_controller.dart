import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:incontext/core/utils/result.dart';
import 'package:incontext/features/context/domain/entities/project_entity.dart';
import 'package:incontext/features/context/domain/repositories/project_repository.dart';
import 'package:incontext/features/context/presentation/providers/context_providers.dart';

/// Provider for project controller
final projectControllerProvider =
    StateNotifierProvider<ProjectController, ProjectState>((ref) {
  final repository = ref.watch(projectRepositoryProvider);
  return ProjectController(repository);
});

/// Controller for project operations
class ProjectController extends StateNotifier<ProjectState> {
  ProjectController(this._repository) : super(const ProjectState());

  final ProjectRepository _repository;

  Future<void> createProject({
    required String title,
    String? description,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.createProject(
      title: title,
      description: description,
    );

    result.when(
      success: (project) {
        state = state.copyWith(
          isLoading: false,
          createdProject: project,
        );
      },
      error: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  Future<void> deleteProject(String id) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.deleteProject(id);

    result.when(
      success: (_) {
        state = state.copyWith(isLoading: false);
      },
      error: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  void clearError() {
    state = state.copyWith();
  }

  void clearCreatedProject() {
    state = state.copyWith(createdProject: null);
  }
}

/// State for project operations
class ProjectState {
  const ProjectState({
    this.isLoading = false,
    this.error,
    this.createdProject,
  });

  final bool isLoading;
  final String? error;
  final ProjectEntity? createdProject;

  ProjectState copyWith({
    bool? isLoading,
    String? error,
    ProjectEntity? createdProject,
  }) {
    return ProjectState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      createdProject: createdProject,
    );
  }
}
