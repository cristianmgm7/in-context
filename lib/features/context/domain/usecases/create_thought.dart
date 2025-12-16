import 'package:incontext/core/utils/result.dart';
import 'package:incontext/features/context/domain/entities/thought_entity.dart';
import 'package:incontext/features/context/domain/repositories/thought_repository.dart';

class CreateThought {
  const CreateThought(this._repository);

  final ThoughtRepository _repository;

  Future<Result<ThoughtEntity>> call({
    required String projectId,
    required String content,
    required bool isAudio,
  }) {
    if (isAudio) {
      return _repository.createAudioThought(
        projectId: projectId,
        audioUrl: content,
      );
    } else {
      return _repository.createTextThought(
        projectId: projectId,
        text: content,
      );
    }
  }
}
