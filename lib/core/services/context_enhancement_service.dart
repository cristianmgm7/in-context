import 'package:incontext/core/errors/failures.dart';
import 'package:incontext/core/services/google_ai_service.dart';
import 'package:incontext/core/utils/result.dart';
import 'package:incontext/features/context/domain/entities/thought_entity.dart';
import 'package:logger/logger.dart';

class ContextEnhancementResult {
  const ContextEnhancementResult({
    required this.enhancedContent,
  });

  final String enhancedContent;
}

/// Service for enhancing context using Google AI
class ContextEnhancementService {
  ContextEnhancementService({
    required GoogleAIService googleAIService,
    Logger? logger,
  })  : _googleAIService = googleAIService,
        _logger = logger ?? Logger();

  final GoogleAIService _googleAIService;
  final Logger _logger;

  /// Enhance context by refining thoughts using AI
  Future<Result<ContextEnhancementResult>> enhanceContext({
    required List<ThoughtEntity> thoughts,
  }) async {
    try {
      _logger.d('Enhancing context from ${thoughts.length} thoughts');

      if (thoughts.isEmpty) {
        return Error(
          ValidationFailure(message: 'Cannot enhance context with no thoughts'),
        );
      }

      // Prepare thoughts for AI processing
      final thoughtsText = _formatThoughtsForAI(thoughts);

      final prompt = '''
You are a context refinement assistant. Your job is to take raw, messy thoughts and refine them into a clear, coherent context.

The user has captured the following thoughts (in chronological order):

$thoughtsText

Your task:
1. Read and understand all the thoughts
2. Identify the main theme or goal
3. Clarify any ambiguous statements
4. Resolve contradictions (prioritize later thoughts if conflicting)
5. Add structure and coherence
6. Maintain the user's original intent and voice

Generate a refined context that represents the canonical understanding of what the user is thinking about.

Format the output as clear, well-structured text. Use markdown for formatting if helpful.
''';

      final result = await _googleAIService.generateContent(
        prompt: prompt,
        temperature: 0.7,
      );

      return result.when(
        success: (enhancedText) {
          _logger.i('Context enhanced successfully');
          return Success(
            ContextEnhancementResult(enhancedContent: enhancedText),
          );
        },
        error: (failure) {
          _logger.e('Context enhancement failed: ${failure.message}');
          return Error(failure);
        },
      );
    } catch (e, stackTrace) {
      _logger.e('Error in enhanceContext', error: e, stackTrace: stackTrace);
      return Error(
        UnknownFailure(message: 'Context enhancement error: ${e.toString()}'),
      );
    }
  }

  /// Format thoughts for AI processing
  String _formatThoughtsForAI(List<ThoughtEntity> thoughts) {
    final buffer = StringBuffer();

    for (var i = 0; i < thoughts.length; i++) {
      final thought = thoughts[i];
      buffer.writeln('---');
      buffer.writeln('Thought #${i + 1} (${thought.type.name}):');

      if (thought.type == ThoughtType.text) {
        buffer.writeln(thought.rawContent);
      } else if (thought.type == ThoughtType.audio) {
        if (thought.transcript != null && thought.transcript!.isNotEmpty) {
          buffer.writeln('[Audio transcript]: ${thought.transcript}');
        } else {
          buffer.writeln('[Audio thought - not yet transcribed]');
        }
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}
