import 'package:flutter/material.dart';
import 'package:incontext_core/core/widgets/keyboard_dismisser.dart';
import 'package:nested/nested.dart';

class Globals extends StatelessWidget {
  const Globals({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Nested(
      children: const [
        KeyboardDismisser(),
      ],
      child: child,
    );
  }
}
