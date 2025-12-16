import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:incontext/core/theme/app_spacing.dart';
import 'package:incontext/core/widgets/error_body.dart';
import 'package:incontext/core/widgets/loading_body.dart';
import 'package:incontext/features/context/presentation/providers/context_providers.dart';
import 'package:incontext/features/context/presentation/providers/thought_controller.dart';
import 'package:incontext/features/context/presentation/widgets/components/add_thought_modal.dart';
import 'package:incontext/features/context/presentation/widgets/thought_card.dart';

class ThoughtsSection extends ConsumerWidget {
  const ThoughtsSection({
    required this.projectId,
    super.key,
  });

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thoughtsAsync = ref.watch(thoughtsStreamProvider(projectId));

    return Column(
      children: [
        // Add thought button
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ElevatedButton.icon(
            onPressed: () => _showAddThoughtModal(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Add Thought'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),

        // Thoughts list
        Expanded(
          child: thoughtsAsync.when(
            data: (thoughts) {
              if (thoughts.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      'No thoughts yet. Click "Add Thought" above to get started.',
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
                    onDelete: () => ref.read(thoughtControllerProvider.notifier).deleteThought(thought.id),
                  );
                },
              );
            },
            loading: () => const LoadingBody(loadingMessage: 'Loading thoughts...'),
            error: (error, _) => ErrorBody(description: 'Failed to load thoughts: $error'),
          ),
        ),
      ],
    );
  }

  void _showAddThoughtModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) => AddThoughtModal(
        projectId: projectId,
        onDismiss: () => Navigator.of(modalContext).pop(),
      ),
    );
  }
}

