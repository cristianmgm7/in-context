import 'package:incontext/core/utils/result.dart';
import 'package:incontext/features/context/domain/repositories/project_repository.dart';

class DeleteProject {
  const DeleteProject(this._repository);

  final ProjectRepository _repository;

  Future<Result<void>> call(String projectId) =>
      _repository.deleteProject(projectId);
}
