import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:incontext/core/routing/app_routes.dart';
import 'package:incontext/core/theme/app_spacing.dart';
import 'package:incontext/core/widgets/app_button.dart';
import 'package:incontext/core/widgets/empty_state.dart';
import 'package:incontext/core/widgets/error_body.dart';
import 'package:incontext/core/widgets/loading_body.dart';
import 'package:incontext/features/context/presentation/providers/context_providers.dart';
import 'package:incontext/features/context/presentation/providers/project_controller.dart';

class ProjectsListScreen extends ConsumerWidget {
  const ProjectsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsStreamProvider);

    // Listen for creation success to navigate
    ref.listen<ProjectState>(projectControllerProvider, (previous, next) {
      if (next.createdProject != null) {
        context.push('${AppRoutes.projects}/${next.createdProject!.id}');
        ref.read(projectControllerProvider.notifier).clearCreatedProject();
      }

      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(projectControllerProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Projects'),
      ),
      body: projectsAsync.when(
        data: (projects) {
          if (projects.isEmpty) {
            return EmptyState(
              icon: Icons.lightbulb_outline,
              title: 'No Projects Yet',
              message: 'Create your first project to start capturing thoughts',
              action: AppButton(
                text: 'Create Project',
                onPressed: () => _showCreateProjectDialog(context, ref),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                child: ListTile(
                  title: Text(project.title),
                  subtitle: project.description != null
                      ? Text(project.description!)
                      : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      context.push('${AppRoutes.projects}/${project.id}'),
                ),
              );
            },
          );
        },
        loading: () => const LoadingBody(loadingMessage: 'Loading projects...'),
        error: (error, _) => ErrorBody(
          description: 'Failed to load projects: $error',
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateProjectDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateProjectDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'My project idea',
              ),
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What is this project about?',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(projectControllerProvider);
              return TextButton(
                onPressed: state.isLoading
                    ? null
                    : () {
                        if (titleController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a title'),
                            ),
                          );
                          return;
                        }

                        ref
                            .read(projectControllerProvider.notifier)
                            .createProject(
                              title: titleController.text.trim(),
                              description:
                                  descriptionController.text.trim().isEmpty
                                      ? null
                                      : descriptionController.text.trim(),
                            );

                        context.pop();
                      },
                child: state.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create'),
              );
            },
          ),
        ],
      ),
    );
  }
}
