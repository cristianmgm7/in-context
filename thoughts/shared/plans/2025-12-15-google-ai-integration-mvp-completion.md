# Google AI Integration - MVP Completion Plan

## Overview

This plan completes the MVP by replacing dummy AI services with real Google AI (Gemini) integration. The app is already fully functional with dummy data - we just need to swap in real AI services.

**Date**: 2025-12-15
**Status**: Ready to implement
**Target Platform**: iOS (for now)

## Current State Analysis

### ✅ What's Working:
- ✅ Projects: Create, list, delete
- ✅ Thoughts: Create text thoughts, delete thoughts
- ✅ Audio: Recording infrastructure exists (needs iOS permissions)
- ✅ Context: Manual editing works
- ✅ UI: All screens and widgets complete
- ✅ State Management: All controllers wired up
- ✅ Database: Firestore repositories implemented

### ⚠️ What Needs Real AI:
- ❌ Audio transcription (using `DummyTranscriptionService`)
- ❌ Context enhancement (using `DummyContextEnhancementService`)
- ❌ Output generation (using `DummyOutputGenerationService`)

### 🔧 What Needs Configuration:
- ❌ iOS permissions for audio recording (Info.plist)
- ❌ Google AI API key setup
- ❌ Service provider wiring

---

## Implementation Plan

### Phase 1: Dependencies & Configuration

#### 1.1 Add Google AI Dependency

**File**: `pubspec.yaml`

Add to dependencies section:
```yaml
dependencies:
  # ... existing dependencies ...

  # Google AI (Gemini)
  google_generative_ai: ^0.2.2
```

Then run:
```bash
~/flutter/bin/flutter pub get
```

#### 1.2 Environment Configuration

**File**: `.env`

Add:
```env
# Google AI Studio API Key
GOOGLE_AI_API_KEY=your_api_key_here
```

**Note**: Get your API key from [Google AI Studio](https://makersuite.google.com/app/apikey)

#### 1.3 iOS Permissions

**File**: `ios/Runner/Info.plist`

Add these permissions for audio recording:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need access to your microphone to record audio thoughts</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>We need access to speech recognition to transcribe your audio thoughts</string>
```

**Success Criteria**:
- [ ] Dependency resolves without errors
- [ ] API key is in `.env` file
- [ ] Info.plist has microphone permissions

---

### Phase 2: Google AI Base Service

#### 2.1 Create Base Google AI Service

**File**: `lib/core/services/google_ai_service.dart`

```dart
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
```

**Pattern**: This base service handles API key management and provides common methods for all AI operations.

**Success Criteria**:
- [ ] File compiles without errors
- [ ] API key is loaded from `.env`
- [ ] Basic generation method works

---

### Phase 3: Replace Dummy Services

#### 3.1 Audio Transcription Service

**File**: `lib/core/services/transcription_service.dart`

Replace/create this file (replacing dummy version):

```dart
import 'package:incontext/core/errors/failures.dart';
import 'package:incontext/core/services/google_ai_service.dart';
import 'package:incontext/core/utils/result.dart';
import 'package:logger/logger.dart';

class TranscriptionResult {
  const TranscriptionResult({
    required this.text,
    required this.language,
  });

  final String text;
  final String language;
}

/// Service for transcribing audio using Google AI
class TranscriptionService {
  TranscriptionService({
    required GoogleAIService googleAIService,
    Logger? logger,
  })  : _googleAIService = googleAIService,
        _logger = logger ?? Logger();

  final GoogleAIService _googleAIService;
  final Logger _logger;

  /// Transcribe audio file to text
  ///
  /// Note: Google AI doesn't support direct audio transcription yet,
  /// so we'll use a workaround by describing the audio file
  /// For production, integrate Whisper API or Google Speech-to-Text
  Future<Result<TranscriptionResult>> transcribeAudio({
    required String audioUrl,
  }) async {
    try {
      _logger.d('Transcribing audio from: $audioUrl');

      // TODO: For MVP, we'll use a placeholder message
      // In production, integrate Google Speech-to-Text API or Whisper
      final prompt = '''
You are an audio transcription assistant.
The user has recorded an audio thought but we don't have the actual audio content yet.
Generate a helpful placeholder message explaining that transcription will be available soon.
Keep it brief and encouraging.
''';

      final result = await _googleAIService.generateContent(
        prompt: prompt,
        temperature: 0.3,
      );

      return result.when(
        success: (text) {
          _logger.i('Audio transcription completed');
          return Success(
            TranscriptionResult(
              text: '[Audio transcription will be available soon]\n\n$text',
              language: 'en',
            ),
          );
        },
        error: (failure) {
          _logger.e('Transcription failed: ${failure.message}');
          return Error(
            ServerFailure(
              message: 'Failed to transcribe audio: ${failure.message}',
            ),
          );
        },
      );
    } catch (e, stackTrace) {
      _logger.e('Error in transcribeAudio', error: e, stackTrace: stackTrace);
      return Error(
        UnknownFailure(message: 'Transcription error: ${e.toString()}'),
      );
    }
  }
}
```

**Note**: Google Gemini doesn't support audio transcription directly yet. For MVP, this provides a placeholder. You can integrate Google Speech-to-Text or Whisper API later.

**Alternative**: If you want real transcription immediately, we can integrate Google Cloud Speech-to-Text API instead.

#### 3.2 Context Enhancement Service

**File**: `lib/core/services/context_enhancement_service.dart`

Replace/create:

```dart
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
```

**Success Criteria**:
- [ ] Service uses real Gemini API
- [ ] Thoughts are properly formatted for AI
- [ ] Enhanced context is coherent and useful

#### 3.3 Output Generation Service

**File**: `lib/core/services/output_generation_service.dart`

Replace/create:

```dart
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
```

**Success Criteria**:
- [ ] Prompt templates are correctly processed
- [ ] Outputs are generated based on context
- [ ] Different prompts produce different outputs

---

### Phase 4: Update Providers

#### 4.1 Update Core Providers

**File**: `lib/core/providers/core_providers.dart`

Add these new providers (replace dummy ones):

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:incontext/core/services/google_ai_service.dart';
import 'package:incontext/core/services/transcription_service.dart';
import 'package:incontext/core/services/context_enhancement_service.dart';
import 'package:incontext/core/services/output_generation_service.dart';

// ... existing providers ...

/// Google AI base service provider
final googleAIServiceProvider = Provider<GoogleAIService>((ref) {
  return GoogleAIService();
});

/// Transcription service provider (replaces dummy)
final transcriptionServiceProvider = Provider<TranscriptionService>((ref) {
  final googleAI = ref.watch(googleAIServiceProvider);
  return TranscriptionService(googleAIService: googleAI);
});

/// Context enhancement service provider (replaces dummy)
final contextEnhancementServiceProvider = Provider<ContextEnhancementService>((ref) {
  final googleAI = ref.watch(googleAIServiceProvider);
  return ContextEnhancementService(googleAIService: googleAI);
});

/// Output generation service provider (replaces dummy)
final outputGenerationServiceProvider = Provider<OutputGenerationService>((ref) {
  final googleAI = ref.watch(googleAIServiceProvider);
  return OutputGenerationService(googleAIService: googleAI);
});
```

**Success Criteria**:
- [ ] All providers compile without errors
- [ ] Services are properly injected

---

### Phase 5: Update Controllers

#### 5.1 Update Thought Controller

**File**: `lib/features/context/presentation/providers/thought_controller.dart`

Change line 18 from:
```dart
final transcriptionService = ref.watch(dummyTranscriptionServiceProvider);
```

To:
```dart
final transcriptionService = ref.watch(transcriptionServiceProvider);
```

And update the import from:
```dart
import 'package:incontext/core/services/dummy_transcription_service.dart';
```

To:
```dart
import 'package:incontext/core/services/transcription_service.dart';
```

And change the field type on line 37 from:
```dart
final DummyTranscriptionService _transcriptionService;
```

To:
```dart
final TranscriptionService _transcriptionService;
```

#### 5.2 Update Context Controller

**File**: `lib/features/context/presentation/providers/context_controller.dart`

Change line 13 from:
```dart
final enhancementService = ref.watch(dummyContextEnhancementServiceProvider);
```

To:
```dart
final enhancementService = ref.watch(contextEnhancementServiceProvider);
```

Update import from:
```dart
import 'package:incontext/core/services/dummy_context_enhancement_service.dart';
```

To:
```dart
import 'package:incontext/core/services/context_enhancement_service.dart';
```

And change the field type on line 23 from:
```dart
final DummyContextEnhancementService _enhancementService;
```

To:
```dart
final ContextEnhancementService _enhancementService;
```

#### 5.3 Update Output Controller

**File**: `lib/features/context/presentation/providers/output_controller.dart`

Change line 13 from:
```dart
final generationService = ref.watch(dummyOutputGenerationServiceProvider);
```

To:
```dart
final generationService = ref.watch(outputGenerationServiceProvider);
```

Update import from:
```dart
import 'package:incontext/core/services/dummy_output_generation_service.dart';
```

To:
```dart
import 'package:incontext/core/services/output_generation_service.dart';
```

And change the field type on line 22 from:
```dart
final DummyOutputGenerationService _generationService;
```

To:
```dart
final OutputGenerationService _generationService;
```

**Success Criteria**:
- [ ] All controllers compile
- [ ] Controllers use real services
- [ ] No references to dummy services remain

---

### Phase 6: Testing & Verification

#### 6.1 End-to-End Testing Flow

**Test Sequence**:

1. **Create Project**
   - [ ] Can create a new project
   - [ ] Project appears in list

2. **Add Text Thoughts**
   - [ ] Can add text thought
   - [ ] Thought appears immediately
   - [ ] Can add multiple thoughts
   - [ ] Can delete a thought

3. **Add Audio Thought** (after iOS permissions)
   - [ ] Can start recording
   - [ ] Microphone indicator shows
   - [ ] Can stop recording
   - [ ] Audio uploads to Firebase Storage
   - [ ] Thought shows "Transcribing..." status
   - [ ] Transcription completes (placeholder for now)

4. **Refine Context**
   - [ ] Click "Refine Context" button
   - [ ] Loading state shows for 2-5 seconds
   - [ ] Enhanced context appears using real Gemini
   - [ ] Context is coherent and well-formatted

5. **Outdated Detection**
   - [ ] Add a new thought after context is created
   - [ ] "Context outdated" banner appears
   - [ ] Can refine context again

6. **Manual Context Editing**
   - [ ] Click "Edit" button
   - [ ] Context editor opens
   - [ ] Can modify text
   - [ ] Click "Save"
   - [ ] Updated context appears

7. **Generate Outputs**
   - [ ] Output section appears below context
   - [ ] Can see 4 prompt chips (Email, Todo, Summary, Code Agent)
   - [ ] Click "Email Generator"
   - [ ] Loading state shows
   - [ ] Output appears using real Gemini
   - [ ] Can copy output to clipboard
   - [ ] Can generate multiple outputs

#### 6.2 Error Handling Tests

- [ ] Network error shows helpful message
- [ ] API key missing shows clear error
- [ ] Invalid API key shows authentication error
- [ ] Rate limit error is handled gracefully

---

## Post-MVP Improvements (Optional)

### Audio Transcription Options:

**Option A: Google Cloud Speech-to-Text** (Recommended)
- More accurate than placeholder
- Costs: $0.006 per 15 seconds
- Requires Google Cloud project setup

**Option B: OpenAI Whisper API**
- Very accurate
- Costs: $0.006 per minute
- Easy to integrate

**Option C: Keep placeholder for MVP**
- Focus on context/output features first
- Add real transcription later

### Future Enhancements:

1. **Streaming Responses**: Use `generateContentStream` for real-time output
2. **Token Usage Tracking**: Monitor costs
3. **Model Selection**: Let users choose Gemini Flash vs Pro
4. **Prompt Library**: User-created custom prompts
5. **Context History**: Version tracking with diffs

---

## Implementation Checklist

### Dependencies
- [ ] Add `google_generative_ai: ^0.2.2` to pubspec.yaml
- [ ] Run `flutter pub get`
- [ ] Add API key to `.env`

### iOS Configuration
- [ ] Add microphone permissions to Info.plist
- [ ] Test recording on real iOS device

### Services
- [ ] Create `google_ai_service.dart`
- [ ] Create `transcription_service.dart`
- [ ] Create `context_enhancement_service.dart`
- [ ] Create `output_generation_service.dart`

### Providers
- [ ] Add service providers to `core_providers.dart`
- [ ] Remove/deprecate dummy service providers

### Controllers
- [ ] Update `thought_controller.dart` imports and types
- [ ] Update `context_controller.dart` imports and types
- [ ] Update `output_controller.dart` imports and types

### Testing
- [ ] Test project creation
- [ ] Test text thoughts
- [ ] Test audio recording (iOS device)
- [ ] Test context refinement with real AI
- [ ] Test output generation with real AI
- [ ] Test all 4 prompt types
- [ ] Test error scenarios

### Cleanup
- [ ] Delete `dummy_transcription_service.dart`
- [ ] Delete `dummy_context_enhancement_service.dart`
- [ ] Delete `dummy_output_generation_service.dart`

---

## Estimated Time

- **Phase 1**: 15 minutes (dependencies & config)
- **Phase 2**: 30 minutes (base service)
- **Phase 3**: 45 minutes (3 services)
- **Phase 4**: 15 minutes (providers)
- **Phase 5**: 15 minutes (controllers)
- **Phase 6**: 30 minutes (testing)

**Total**: ~2.5 hours

---

## References

- Google AI Studio: https://makersuite.google.com/
- Gemini API Docs: https://ai.google.dev/docs
- Flutter Package: https://pub.dev/packages/google_generative_ai
- Original Plan: [2025-12-15-context-first-thinking-system-mvp.md](./2025-12-15-context-first-thinking-system-mvp.md)
