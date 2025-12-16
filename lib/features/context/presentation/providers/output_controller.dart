import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:incontext/core/providers/core_providers.dart';
import 'package:incontext/core/services/dummy_output_generation_service.dart';
import 'package:incontext/core/utils/result.dart';
import 'package:incontext/features/context/domain/entities/context_entity.dart';
import 'package:incontext/features/context/domain/entities/prompt_definition_entity.dart';
import 'package:incontext/features/context/domain/repositories/output_repository.dart';
import 'package:incontext/features/context/presentation/providers/context_providers.dart';

final outputControllerProvider =
    StateNotifierProvider<OutputController, OutputState>((ref) {
  final repository = ref.watch(outputRepositoryProvider);
  final generationService = ref.watch(dummyOutputGenerationServiceProvider);
  return OutputController(repository, generationService);
});

class OutputController extends StateNotifier<OutputState> {
  OutputController(this._repository, this._generationService)
      : super(const OutputState());

  final OutputRepository _repository;
  final DummyOutputGenerationService _generationService;

  Future<void> generateOutput({
    required ContextEntity context,
    required PromptDefinitionEntity prompt,
  }) async {
    state = state.copyWith(isGenerating: true);

    // Generate content using service
    final generationResult = await _generationService.generateOutput(
      context: context,
      prompt: prompt,
    );

    await generationResult.when(
      success: (result) async {
        // Save output to repository
        final saveResult = await _repository.createOutput(
          contextId: context.id,
          promptDefinitionId: prompt.id,
          promptVersion: prompt.version,
          content: result.content,
        );

        saveResult.when(
          success: (_) {
            state = state.copyWith(isGenerating: false);
          },
          error: (failure) {
            state = state.copyWith(
              isGenerating: false,
              error: failure.message,
            );
          },
        );
      },
      error: (failure) {
        state = state.copyWith(
          isGenerating: false,
          error: failure.message,
        );
      },
    );
  }

  void clearError() {
    state = state.copyWith();
  }
}

class OutputState {
  const OutputState({
    this.isGenerating = false,
    this.error,
  });

  final bool isGenerating;
  final String? error;

  OutputState copyWith({
    bool? isGenerating,
    String? error,
  }) {
    return OutputState(
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
    );
  }
}
