import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pushes [location] and shows the message the page pops with, if any, on
/// this page's Scaffold.
Future<void> pushForMessage(BuildContext context, String location) async {
  final messenger = ScaffoldMessenger.of(context);
  final message = await context.push<String>(location);
  if (message != null) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Closes the current page with [message] for the page underneath to show.
/// After a deep link there is nothing to pop, so it goes to [fallback] and
/// shows the message itself.
void closeWithMessage(BuildContext context, String message, String fallback) {
  if (context.canPop()) {
    context.pop(message);
    return;
  }
  final messenger = ScaffoldMessenger.of(context);
  context.go(fallback);
  messenger.showSnackBar(SnackBar(content: Text(message)));
}
