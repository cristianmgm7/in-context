import 'package:incontext/core/utils/result.dart';
import 'package:incontext/features/context/domain/entities/context_entity.dart';
import 'package:incontext/features/context/domain/entities/output_entity.dart';
import 'package:incontext/features/context/domain/entities/prompt_definition_entity.dart';
import 'package:incontext/features/context/domain/repositories/output_repository.dart';

/// Use case: Generate output by applying a prompt to context
class CreateOutput {
  const CreateOutput(this._repository);

  final OutputRepository _repository;

  Future<Result<OutputEntity>> call({
    required ContextEntity context,
    required PromptDefinitionEntity prompt,
    required String Function(ContextEntity, PromptDefinitionEntity) generator,
  }) async {
    // Call the generator function (AI service) to create output
    final generatedContent = generator(context, prompt);

    // Save the output
    return _repository.createOutput(
      contextId: context.id,
      promptDefinitionId: prompt.id,
      promptVersion: prompt.version,
      content: generatedContent,
    );
  }
}
