import 'package:flutter/material.dart';
import 'package:incontext/core/theme/app_spacing.dart';
import 'package:incontext/core/widgets/app_text_field.dart';

class ThoughtInputWidget extends StatefulWidget {
  const ThoughtInputWidget({
    required this.onSubmitText,
    required this.onRecordAudio,
    required this.isRecording,
    super.key,
  });

  final void Function(String text) onSubmitText;
  final VoidCallback onRecordAudio;
  final bool isRecording;

  @override
  State<ThoughtInputWidget> createState() => _ThoughtInputWidgetState();
}

class _ThoughtInputWidgetState extends State<ThoughtInputWidget> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmitText(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: AppTextField(
              controller: _controller,
              hint: 'Add a thought...',
              maxLines: null,
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: Icon(widget.isRecording ? Icons.stop : Icons.mic),
            onPressed: widget.onRecordAudio,
            color: widget.isRecording ? Colors.red : null,
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
