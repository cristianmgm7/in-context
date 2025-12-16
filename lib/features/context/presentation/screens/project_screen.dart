import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:incontext/core/theme/app_spacing.dart';
import 'package:incontext/core/widgets/error_body.dart';
import 'package:incontext/core/widgets/loading_body.dart';
import 'package:incontext/features/context/domain/entities/context_entity.dart';
import 'package:incontext/features/context/domain/entities/thought_entity.dart';
import 'package:incontext/features/context/data/prompt_definitions_registry.dart';
import 'package:incontext/features/context/presentation/providers/context_controller.dart';
import 'package:incontext/features/context/presentation/providers/context_providers.dart';
import 'package:incontext/features/context/presentation/providers/output_controller.dart';
import 'package:incontext/features/context/presentation/providers/thought_controller.dart';
import 'package:incontext/features/context/presentation/screens/context_editor_screen.dart';
import 'package:incontext/features/context/presentation/widgets/output_card.dart';
import 'package:incontext/features/context/presentation/widgets/context_card.dart';
import 'package:incontext/features/context/presentation/widgets/thought_card.dart';
import 'package:incontext/features/context/presentation/widgets/thought_input_widget.dart';

class ProjectScreen extends ConsumerStatefulWidget {
  const ProjectScreen({
    required this.projectId,
    super.key,
  });

  final String projectId;

  @override
  ConsumerState<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends ConsumerState<ProjectScreen> {
  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectProvider(widget.projectId));
    final thoughtsAsync = ref.watch(thoughtsStreamProvider(widget.projectId));
    final contextAsync = ref.watch(contextStreamProvider(widget.projectId));
    final thoughtState = ref.watch(thoughtControllerProvider);
    final contextState = ref.watch(contextControllerProvider);

    // Listen for thought controller errors
    ref.listen<ThoughtState>(thoughtControllerProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(thoughtControllerProvider.notifier).clearError();
      }
    });

    // Listen for context controller errors
    ref.listen<ContextState>(contextControllerProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(contextControllerProvider.notifier).clearError();
      }
    });

    // Listen for output controller errors
    ref.listen<OutputState>(outputControllerProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(outputControllerProvider.notifier).clearError();
      }
    });

    return projectAsync.when(
      data: (project) {
        return Scaffold(
          appBar: AppBar(
            title: Text(project.title),
          ),
          body: Column(
            children: [
              // Thoughts section
              Expanded(
                child: thoughtsAsync.when(
                  data: (thoughts) => _buildThoughtsSection(thoughts),
                  loading: () =>
                      const LoadingBody(loadingMessage: 'Loading thoughts...'),
                  error: (error, _) =>
                      ErrorBody(description: 'Failed to load thoughts: $error'),
                ),
              ),

              // Context section
              contextAsync.when(
                data: (context) => _buildContextSection(
                    context,
                    thoughtsAsync.valueOrNull ?? [],
                    contextState,
                    contextAsync.valueOrNull),
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: LinearProgressIndicator(),
                ),
                error: (error, _) =>
                    ErrorBody(description: 'Failed to load context: $error'),
              ),

              // Thought input
              ThoughtInputWidget(
                onSubmitText: _addTextThought,
                onRecordAudio: _handleAudioRecording,
                isRecording:
                    thoughtState.isRecording || thoughtState.isUploading,
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: LoadingBody(loadingMessage: 'Loading project...'),
      ),
      error: (error, _) => Scaffold(
        body: ErrorBody(description: 'Failed to load project: $error'),
      ),
    );
  }

  Widget _buildThoughtsSection(List<ThoughtEntity> thoughts) {
    if (thoughts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Text(
            'No thoughts yet. Add your first thought below.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      itemCount: thoughts.length,
      itemBuilder: (context, index) {
        final thought = thoughts[index];
        return ThoughtCard(
          thought: thought,
          onDelete: () => _deleteThought(thought.id),
        );
      },
    );
  }

  Widget _buildContextSection(
      ContextEntity? context,
      List<ThoughtEntity> thoughts,
      ContextState contextState,
      ContextEntity? contextEntity) {
    final isOutdated =
        context != null ? _isContextOutdated(context, thoughts) : false;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ContextCard(
          context: context,
          isOutdated: isOutdated,
          onRefine: _refineContext,
          onEdit: _editContext,
          isRefining: contextState.isEnhancing,
        ),
        if (contextEntity != null) _buildOutputsSection(contextEntity),
      ],
    );
  }

  bool _isContextOutdated(ContextEntity context, List<ThoughtEntity> thoughts) {
    // Context is outdated if:
    // 1. Any thought was created after context.updatedAt
    // 2. Any thought in sourceThoughtIds is missing (deleted)
    return thoughts.any((t) => t.createdAt.isAfter(context.updatedAt)) ||
        !context.sourceThoughtIds
            .every((id) => thoughts.any((t) => t.id == id));
  }

  void _addTextThought(String text) {
    ref.read(thoughtControllerProvider.notifier).createTextThought(
          projectId: widget.projectId,
          text: text,
        );
  }

  void _handleAudioRecording() {
    final thoughtController = ref.read(thoughtControllerProvider.notifier);
    final currentState = ref.read(thoughtControllerProvider);

    if (currentState.isRecording || currentState.isUploading) {
      thoughtController.stopRecordingAndCreateThought(widget.projectId);
    } else {
      thoughtController.startRecording();
    }
  }

  void _deleteThought(String thoughtId) {
    ref.read(thoughtControllerProvider.notifier).deleteThought(thoughtId);
  }

  void _refineContext() {
    final thoughtsAsyncValue =
        ref.read(thoughtsStreamProvider(widget.projectId));
    final thoughts = thoughtsAsyncValue.valueOrNull ?? [];
    if (thoughts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No thoughts to refine')),
      );
      return;
    }

    ref.read(contextControllerProvider.notifier).enhanceContext(
          projectId: widget.projectId,
          thoughts: thoughts,
        );
  }

  Widget _buildOutputsSection(ContextEntity contextEntity) {
    final outputsAsync = ref.watch(outputsStreamProvider(contextEntity.id));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'Outputs',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Prompt selection buttons
        Wrap(
          spacing: AppSpacing.sm,
          children: PromptDefinitionsRegistry.prompts.map((prompt) {
            return ActionChip(
              label: Text(prompt.name),
              onPressed: () {
                ref.read(outputControllerProvider.notifier).generateOutput(
                      context: contextEntity,
                      prompt: prompt,
                    );
              },
            );
          }).toList(),
        ),

        // Outputs list
        outputsAsync.when(
          data: (outputs) {
            if (outputs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text('No outputs yet. Apply a prompt above.'),
              );
            }

            return Column(
              children: [
                for (final output in outputs)
                  OutputCard(
                    output: output,
                    promptName: PromptDefinitionsRegistry.getById(
                                output.promptDefinitionId)
                            ?.name ??
                        'Unknown',
                  ),
              ],
            );
          },
          loading: () => const LoadingBody(),
          error: (error, _) => ErrorBody(description: 'Failed to load outputs'),
        ),
      ],
    );
  }

  void _editContext() {
    final contextAsyncValue = ref.read(contextStreamProvider(widget.projectId));
    final contextEntity = contextAsyncValue.valueOrNull;

    if (contextEntity != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ContextEditorScreen(context: contextEntity),
        ),
      );
    }
  }
}
