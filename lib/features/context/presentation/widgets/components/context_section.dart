import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:incontext/core/theme/app_spacing.dart';
import 'package:incontext/core/widgets/error_body.dart';
import 'package:incontext/core/widgets/loading_body.dart';
import 'package:incontext/features/context/data/prompt_definitions_registry.dart';
import 'package:incontext/features/context/domain/entities/context_entity.dart';
import 'package:incontext/features/context/domain/entities/thought_entity.dart';
import 'package:incontext/features/context/presentation/providers/context_controller.dart';
import 'package:incontext/features/context/presentation/providers/context_providers.dart';
import 'package:incontext/features/context/presentation/providers/output_controller.dart';
import 'package:incontext/features/context/presentation/screens/context_editor_screen.dart';
import 'package:incontext/features/context/presentation/widgets/context_card.dart';
import 'package:incontext/features/context/presentation/widgets/output_card.dart';

class ContextSection extends ConsumerWidget {
  const ContextSection({
    required this.projectId,
    super.key,
  });

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contextAsync = ref.watch(contextStreamProvider(projectId));
    final thoughtsAsync = ref.watch(thoughtsStreamProvider(projectId));
    final contextState = ref.watch(contextControllerProvider);

    return contextAsync.when(
      data: (contextEntity) {
        final thoughts = thoughtsAsync.valueOrNull ?? [];
        final isOutdated = contextEntity != null ? _isContextOutdated(contextEntity, thoughts) : false;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ContextCard(
              context: contextEntity,
              isOutdated: isOutdated,
              onRefine: () => _refineContext(ref, thoughts),
              onEdit: () => _editContext(context, contextEntity),
              isRefining: contextState.isEnhancing,
            ),
            if (contextEntity != null) _buildOutputsSection(ref, contextEntity),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16.0),
        child: LinearProgressIndicator(),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Failed to load context: $error'),
      ),
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

  void _refineContext(WidgetRef ref, List<ThoughtEntity> thoughts) {
    ref.read(contextControllerProvider.notifier).enhanceContext(
          projectId: projectId,
          thoughts: thoughts,
        );
  }

  void _editContext(BuildContext context, ContextEntity? contextEntity) {
    if (contextEntity != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ContextEditorScreen(context: contextEntity),
        ),
      );
    }
  }

  Widget _buildOutputsSection(WidgetRef ref, ContextEntity contextEntity) {
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
}
