import 'package:incontext/core/errors/failures.dart';
import 'package:incontext/core/services/google_ai_service.dart';
import 'package:incontext/core/utils/result.dart';
import 'package:incontext/features/context/domain/entities/context_entity.dart';
import 'package:incontext/features/context/domain/entities/prompt_definition_entity.dart';
import 'package:logger/logger.dart';

class OutputGenerationResult {
  const OutputGenerationResult({
    required this.content,
  });

  final String content;
}

/// Service for generating outputs using Google AI
class OutputGenerationService {
  OutputGenerationService({
    required GoogleAIService googleAIService,
    Logger? logger,
  })  : _googleAIService = googleAIService,
        _logger = logger ?? Logger();

  final GoogleAIService _googleAIService;
  final Logger _logger;

  /// Generate output by applying a prompt to context
  Future<Result<OutputGenerationResult>> generateOutput({
    required ContextEntity context,
    required PromptDefinitionEntity prompt,
  }) async {
    try {
      _logger.d('Generating output with prompt: ${prompt.name}');

      // Replace {{CONTEXT}} placeholder in prompt template
      final processedPrompt = prompt.promptTemplate.replaceAll(
        '{{CONTEXT}}',
        context.content,
      );

      final result = await _googleAIService.generateContent(
        prompt: processedPrompt,
        temperature: 0.8, // Higher creativity for outputs
      );

      return result.when(
        success: (generatedText) {
          _logger.i('Output generated successfully with ${prompt.name}');
          return Success(
            OutputGenerationResult(content: generatedText),
          );
        },
        error: (failure) {
          _logger.e('Output generation failed: ${failure.message}');
          return Error(failure);
        },
      );
    } catch (e, stackTrace) {
      _logger.e('Error in generateOutput', error: e, stackTrace: stackTrace);
      return Error(
        UnknownFailure(message: 'Output generation error: ${e.toString()}'),
      );
    }
  }
}
