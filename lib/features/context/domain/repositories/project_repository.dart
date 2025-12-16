import 'package:incontext/core/utils/result.dart';
import 'package:incontext/features/context/domain/entities/project_entity.dart';

abstract class ProjectRepository {
  /// Stream of all projects for the current user
  Stream<List<ProjectEntity>> watchProjects();

  /// Get a single project by ID
  Future<Result<ProjectEntity>> getProject(String id);

  /// Create a new project
  Future<Result<ProjectEntity>> createProject({
    required String title,
    String? description,
  });

  /// Update an existing project
  Future<Result<ProjectEntity>> updateProject({
    required String id,
    String? title,
    String? description,
  });

  /// Delete a project
  Future<Result<void>> deleteProject(String id);
}
