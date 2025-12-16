import 'package:incontext/core/utils/result.dart';
import 'package:incontext/features/context/domain/entities/project_entity.dart';
import 'package:incontext/features/context/domain/repositories/project_repository.dart';

class CreateProject {
  const CreateProject(this._repository);

  final ProjectRepository _repository;

  Future<Result<ProjectEntity>> call({
    required String title,
    String? description,
  }) =>
      _repository.createProject(
        title: title,
        description: description,
      );
}
