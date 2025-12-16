import 'package:flutter/material.dart';
import 'package:incontext/core/theme/app_spacing.dart';
import 'package:incontext/core/widgets/app_button.dart';
import 'package:incontext/features/context/domain/entities/context_entity.dart';

class ContextCard extends StatelessWidget {
  const ContextCard({
    required this.context,
    required this.isOutdated,
    required this.onRefine,
    required this.onEdit,
    super.key,
    this.isRefining = false,
  });

  final ContextEntity? context;
  final bool isOutdated;
  final VoidCallback onRefine;
  final VoidCallback onEdit;
  final bool isRefining;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, size: 20),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Context',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (isOutdated)
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Context is outdated. Thoughts have been added or removed.',
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (this.context != null) ...[
              Text(this.context!.content),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Edit',
                      type: AppButtonType.outlined,
                      onPressed: onEdit,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      text: 'Refine',
                      onPressed: onRefine,
                      isLoading: isRefining,
                    ),
                  ),
                ],
              ),
            ] else
              AppButton(
                text: 'Refine Context',
                onPressed: onRefine,
                isLoading: isRefining,
              ),
          ],
        ),
      ),
    );
  }
}
