import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/confirm_delete_dialog.dart';
import '../data/schedule.dart';
import '../providers/schedule_provider.dart';

/// Confirms and deletes [s]. Returns true when deleted, false when cancelled
/// or failed; a failure is reported here, success is left to the caller so
/// it can show the message on the right page.
Future<bool> deleteSchedule(BuildContext context, Schedule s) async {
  final provider = context.read<ScheduleProvider>();
  final messenger = ScaffoldMessenger.of(context);
  if (!await confirmDelete(context, itemName: 'jadwal ${s.courseName}')) {
    return false;
  }
  final error = await provider.delete(s.id!);
  if (error != null) messenger.showSnackBar(SnackBar(content: Text(error)));
  return error == null;
}

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
