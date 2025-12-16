import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:incontext/core/theme/app_spacing.dart';
import 'package:incontext/core/widgets/app_text_field.dart';
import 'package:incontext/features/context/presentation/providers/thought_controller.dart';

class AddThoughtModal extends ConsumerStatefulWidget {
  const AddThoughtModal({
    required this.projectId,
    required this.onDismiss,
    super.key,
  });

  final String projectId;
  final VoidCallback onDismiss;

  @override
  ConsumerState<AddThoughtModal> createState() => _AddThoughtModalState();
}

class _AddThoughtModalState extends ConsumerState<AddThoughtModal> {
  final _controller = TextEditingController();
  bool _isTextMode = true; // true for text, false for audio

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitText() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    ref.read(thoughtControllerProvider.notifier).createTextThought(
          projectId: widget.projectId,
          text: text,
        );
    _controller.clear();
    widget.onDismiss();
  }

  void _toggleRecording() {
    final thoughtController = ref.read(thoughtControllerProvider.notifier);
    final currentState = ref.read(thoughtControllerProvider);

    if (currentState.isRecording || currentState.isUploading) {
      thoughtController.stopRecordingAndCreateThought(widget.projectId);
      widget.onDismiss();
    } else {
      thoughtController.startRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final thoughtState = ref.watch(thoughtControllerProvider);

        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mode selector
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _isTextMode = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isTextMode ? Theme.of(context).colorScheme.primary : null,
                        foregroundColor: _isTextMode ? Theme.of(context).colorScheme.onPrimary : null,
                      ),
                      child: const Text('Text'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _isTextMode = false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !_isTextMode ? Theme.of(context).colorScheme.primary : null,
                        foregroundColor: !_isTextMode ? Theme.of(context).colorScheme.onPrimary : null,
                      ),
                      child: const Text('Audio'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Input area
              if (_isTextMode) ...[
                AppTextField(
                  controller: _controller,
                  hint: 'Enter your thought...',
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton.icon(
                  onPressed: _submitText,
                  icon: const Icon(Icons.send),
                  label: const Text('Add Thought'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ] else ...[
                const Text(
                  'Tap the microphone to start recording',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton.icon(
                  onPressed: _toggleRecording,
                  icon: Icon(thoughtState.isRecording || thoughtState.isUploading ? Icons.stop : Icons.mic),
                  label: Text(thoughtState.isRecording ? 'Stop & Save' :
                             thoughtState.isUploading ? 'Uploading...' : 'Start Recording'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: thoughtState.isRecording ? Colors.red : null,
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }
}
