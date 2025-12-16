import 'package:flutter/material.dart';
import 'package:incontext/core/theme/app_spacing.dart';
import 'package:incontext/features/context/domain/entities/thought_entity.dart';
import 'package:timeago/timeago.dart' as timeago;

class ThoughtCard extends StatelessWidget {
  const ThoughtCard({
    required this.thought,
    required this.onDelete,
    super.key,
  });

  final ThoughtEntity thought;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  thought.type == ThoughtType.text
                      ? Icons.text_fields
                      : Icons.mic,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  timeago.format(thought.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (thought.type == ThoughtType.text)
              Text(thought.rawContent)
            else ...[
              if (thought.transcriptionStatus == TranscriptionStatus.processing)
                const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Text('Transcribing...'),
                  ],
                )
              else if (thought.transcript != null)
                Text(thought.transcript!)
              else
                const Text('[Audio]',
                    style: TextStyle(fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }
}
