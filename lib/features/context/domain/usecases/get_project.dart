import 'package:incontext/core/utils/result.dart';
import 'package:incontext/features/context/domain/entities/project_entity.dart';
import 'package:incontext/features/context/domain/repositories/project_repository.dart';

class GetProject {
  const GetProject(this._repository);

  final ProjectRepository _repository;

  Future<Result<ProjectEntity>> call(String projectId) =>
      _repository.getProject(projectId);
}
