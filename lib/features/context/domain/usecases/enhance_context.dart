import 'package:incontext/core/utils/result.dart';
import 'package:incontext/features/context/domain/entities/context_entity.dart';
import 'package:incontext/features/context/domain/entities/thought_entity.dart';
import 'package:incontext/features/context/domain/repositories/context_repository.dart';

/// Use case: Enhance context by refining all thoughts using AI
class EnhanceContext {
  const EnhanceContext(this._repository);

  final ContextRepository _repository;

  Future<Result<ContextEntity>> call({
    required String projectId,
    required List<ThoughtEntity> thoughts,
    required String Function(List<ThoughtEntity>) enhancer,
  }) async {
    // Call the enhancer function (AI service) to generate refined content
    final enhancedContent = enhancer(thoughts);

    // Save the enhanced context
    return _repository.saveContext(
      projectId: projectId,
      content: enhancedContent,
      sourceThoughtIds: thoughts.map((t) => t.id).toList(),
    );
  }
}
