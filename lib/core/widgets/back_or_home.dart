import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Back button that still works when the page was opened by deep link
/// (nothing to pop): it then goes to [fallback].
class BackOrHome extends StatelessWidget {
  const BackOrHome({super.key, required this.fallback});

  final String fallback;

  @override
  Widget build(BuildContext context) {
    return BackButton(
      onPressed: () =>
          context.canPop() ? context.pop() : context.go(fallback),
    );
  }
}
