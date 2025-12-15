import 'package:incontext/core/utils/result.dart';

class TranscriptionResult {
  const TranscriptionResult({
    required this.text,
    required this.language,
  });

  final String text;
  final String language;
}

class DummyTranscriptionService {
  const DummyTranscriptionService();

  Future<Result<TranscriptionResult>> transcribeAudio({
    required String audioUrl,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Return dummy transcription
    return const Success(
      TranscriptionResult(
        text: 'This is a dummy transcription of the audio thought. '
            'In production, this would be the actual transcribed text from the audio file.',
        language: 'en',
      ),
    );
  }
}
