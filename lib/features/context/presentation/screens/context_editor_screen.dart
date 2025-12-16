import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:incontext/core/theme/app_spacing.dart';
import 'package:incontext/core/widgets/app_button.dart';
import 'package:incontext/features/context/domain/entities/context_entity.dart';
import 'package:incontext/features/context/presentation/providers/context_controller.dart';

class ContextEditorScreen extends ConsumerStatefulWidget {
  const ContextEditorScreen({
    required this.context,
    super.key,
  });

  final ContextEntity context;

  @override
  ConsumerState<ContextEditorScreen> createState() =>
      _ContextEditorScreenState();
}

class _ContextEditorScreenState extends ConsumerState<ContextEditorScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.context.content);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contextControllerProvider);

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

      // Navigate back on success
      if (previous?.isLoading == true &&
          next.isLoading == false &&
          next.error == null) {
        context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Context'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: state.isLoading ? null : _save,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Edit your context...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              text: 'Save Changes',
              onPressed: _save,
              isLoading: state.isLoading,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final newContent = _controller.text.trim();
    if (newContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Context cannot be empty')),
      );
      return;
    }

    ref.read(contextControllerProvider.notifier).updateContext(
          contextId: widget.context.id,
          content: newContent,
        );
  }
}
