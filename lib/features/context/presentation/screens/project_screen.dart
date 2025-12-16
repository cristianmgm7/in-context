import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:incontext/core/widgets/error_body.dart';
import 'package:incontext/core/widgets/loading_body.dart';
import 'package:incontext/features/context/presentation/providers/context_controller.dart';
import 'package:incontext/features/context/presentation/providers/context_providers.dart';
import 'package:incontext/features/context/presentation/providers/output_controller.dart';
import 'package:incontext/features/context/presentation/providers/thought_controller.dart';
import 'package:incontext/features/context/presentation/widgets/components/context_section.dart';
import 'package:incontext/features/context/presentation/widgets/components/thoughts_section.dart';

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
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Thoughts section
                ThoughtsSection(
                  projectId: widget.projectId,
                ),

                // Context section
                ContextSection(
                  projectId: widget.projectId,
                ),
              ],
            ),
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



}
