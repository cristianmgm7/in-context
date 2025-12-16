import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:incontext/core/errors/failures.dart';
import 'package:incontext/core/utils/result.dart';
import 'package:logger/logger.dart';

/// Base service for Google AI (Gemini) interactions
class GoogleAIService {
  GoogleAIService({Logger? logger}) : _logger = logger ?? Logger();

  final Logger _logger;

  /// Get API key from environment
  String get _apiKey {
    final apiKey = dotenv.env['GOOGLE_AI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GOOGLE_AI_API_KEY not found in .env file');
    }
    return apiKey;
  }

  /// Create a Gemini model instance
  GenerativeModel _createModel({
    String modelName = 'gemini-1.5-flash',
    double temperature = 0.7,
  }) {
    return GenerativeModel(
      model: modelName,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: temperature,
        maxOutputTokens: 2048,
      ),
    );
  }

  /// Generate content from text prompt
  Future<Result<String>> generateContent({
    required String prompt,
    String modelName = 'gemini-1.5-flash',
    double temperature = 0.7,
  }) async {
    try {
      _logger.d('Generating content with Gemini...');

      final model = _createModel(
        modelName: modelName,
        temperature: temperature,
      );

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        _logger.e('Empty response from Gemini');
        return Error(
          ServerFailure(message: 'Received empty response from AI service'),
        );
      }

      _logger.d('Content generated successfully');
      return Success(response.text!);
    } catch (e, stackTrace) {
      _logger.e('Error generating content', error: e, stackTrace: stackTrace);
      return Error(
        ServerFailure(message: 'AI generation failed: ${e.toString()}'),
      );
    }
  }

  /// Generate content with streaming (for future use)
  Stream<String> generateContentStream({
    required String prompt,
    String modelName = 'gemini-1.5-flash',
  }) async* {
    try {
      final model = _createModel(modelName: modelName);
      final content = [Content.text(prompt)];
      final response = model.generateContentStream(content);

      await for (final chunk in response) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      _logger.e('Error in streaming generation', error: e);
      yield 'Error: ${e.toString()}';
    }
  }
}
