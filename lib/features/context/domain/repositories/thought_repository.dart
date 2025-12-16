import 'package:incontext/core/utils/result.dart';
import 'package:incontext/features/context/domain/entities/thought_entity.dart';

abstract class ThoughtRepository {
  /// Stream of all thoughts for a project
  Stream<List<ThoughtEntity>> watchThoughts(String projectId);

  /// Create a text thought
  Future<Result<ThoughtEntity>> createTextThought({
    required String projectId,
    required String text,
  });

  /// Create an audio thought (requires uploading file first)
  Future<Result<ThoughtEntity>> createAudioThought({
    required String projectId,
    required String audioUrl,
  });

  /// Update transcription for an audio thought
  Future<Result<void>> updateTranscription({
    required String thoughtId,
    required String transcript,
    required TranscriptionStatus status,
  });

  /// Delete a thought
  Future<Result<void>> deleteThought(String thoughtId);
}
