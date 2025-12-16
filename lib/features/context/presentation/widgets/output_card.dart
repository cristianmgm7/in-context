import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:incontext/core/theme/app_spacing.dart';
import 'package:incontext/features/context/domain/entities/output_entity.dart';
import 'package:timeago/timeago.dart' as timeago;

class OutputCard extends StatelessWidget {
  const OutputCard({
    required this.output,
    required this.promptName,
    super.key,
  });

  final OutputEntity output;
  final String promptName;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.output, size: 20),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    promptName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  timeago.format(output.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Prompt v${output.promptVersion}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: AppSpacing.md),
            Text(output.content),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: output.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy'),
            ),
          ],
        ),
      ),
    );
  }
}
