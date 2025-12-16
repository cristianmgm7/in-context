import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:incontext/core/providers/core_providers.dart';
import 'package:incontext/core/services/context_enhancement_service.dart';
import 'package:incontext/core/utils/result.dart';
import 'package:incontext/features/context/domain/entities/thought_entity.dart';
import 'package:incontext/features/context/domain/repositories/context_repository.dart';
import 'package:incontext/features/context/presentation/providers/context_providers.dart';

/// Provider for context controller
final contextControllerProvider =
    StateNotifierProvider<ContextController, ContextState>((ref) {
  final repository = ref.watch(contextRepositoryProvider);
  final enhancementService = ref.watch(contextEnhancementServiceProvider);
  return ContextController(repository, enhancementService);
});

/// Controller for context operations
class ContextController extends StateNotifier<ContextState> {
  ContextController(this._repository, this._enhancementService)
      : super(const ContextState());

  final ContextRepository _repository;
  final ContextEnhancementService _enhancementService;

  Future<void> enhanceContext({
    required String projectId,
    required List<ThoughtEntity> thoughts,
  }) async {
    state = state.copyWith(isEnhancing: true);

    final enhancementResult = await _enhancementService.enhanceContext(
      thoughts: thoughts,
    );

    await enhancementResult.when(
      success: (result) async {
        final saveResult = await _repository.saveContext(
          projectId: projectId,
          content: result.enhancedContent,
          sourceThoughtIds: thoughts.map((t) => t.id).toList(),
        );

        saveResult.when(
          success: (_) {
            state = state.copyWith(isEnhancing: false);
          },
          error: (failure) {
            state = state.copyWith(
              isEnhancing: false,
              error: failure.message,
            );
          },
        );
      },
      error: (failure) {
        state = state.copyWith(
          isEnhancing: false,
          error: failure.message,
        );
      },
    );
  }

  Future<void> updateContext({
    required String contextId,
    required String content,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.updateContextContent(
      contextId: contextId,
      content: content,
    );

    result.when(
      success: (_) {
        state = state.copyWith(isLoading: false);
      },
      error: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  void clearError() {
    state = state.copyWith();
  }
}

/// State for context operations
class ContextState {
  const ContextState({
    this.isLoading = false,
    this.isEnhancing = false,
    this.error,
  });

  final bool isLoading;
  final bool isEnhancing;
  final String? error;

  ContextState copyWith({
    bool? isLoading,
    bool? isEnhancing,
    String? error,
  }) {
    return ContextState(
      isLoading: isLoading ?? this.isLoading,
      isEnhancing: isEnhancing ?? this.isEnhancing,
      error: error,
    );
  }
}
