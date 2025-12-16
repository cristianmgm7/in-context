import 'package:incontext/core/errors/failures.dart';

class ContextFailure extends Failure {
  const ContextFailure({
    required super.message,
    super.code,
  });

  factory ContextFailure.projectNotFound() => const ContextFailure(
        message: 'Project not found',
        code: 404,
      );

  factory ContextFailure.thoughtNotFound() => const ContextFailure(
        message: 'Thought not found',
        code: 404,
      );

  factory ContextFailure.contextNotFound() => const ContextFailure(
        message: 'Context not found',
        code: 404,
      );

  factory ContextFailure.transcriptionFailed(String reason) => ContextFailure(
        message: 'Transcription failed: $reason',
        code: 500,
      );

  factory ContextFailure.enhancementFailed(String reason) => ContextFailure(
        message: 'Context enhancement failed: $reason',
        code: 500,
      );

  factory ContextFailure.outputGenerationFailed(String reason) =>
      ContextFailure(
        message: 'Output generation failed: $reason',
        code: 500,
      );

  factory ContextFailure.unknown(String message) => ContextFailure(
        message: message,
        code: 500,
      );
}
