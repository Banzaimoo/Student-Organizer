import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/confirm_delete_dialog.dart';
import '../data/task.dart';
import '../providers/task_provider.dart';

/// Confirms and deletes [t]. Returns true when deleted, false when cancelled
/// or failed; a failure is reported here, success is left to the caller so
/// it can show the message on the right page.
Future<bool> deleteTask(BuildContext context, Task t) async {
  final provider = context.read<TaskProvider>();
  final messenger = ScaffoldMessenger.of(context);
  if (!await confirmDelete(context, itemName: 'tugas ${t.title}')) {
    return false;
  }
  final error = await provider.delete(t.id!);
  if (error != null) messenger.showSnackBar(SnackBar(content: Text(error)));
  return error == null;
}

/// Changes the status of [t] and reports the result in a SnackBar.
Future<void> changeTaskStatus(
  BuildContext context,
  Task t,
  TaskStatus status,
) async {
  final provider = context.read<TaskProvider>();
  final messenger = ScaffoldMessenger.of(context);
  final error = await provider.setStatus(t, status);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(error ?? 'Status diubah ke ${status.label}')),
    );
}

/// Checkbox on a card: finished ↔ not started.
Future<void> toggleTaskDone(BuildContext context, Task t) => changeTaskStatus(
  context,
  t,
  t.isDone ? TaskStatus.belum : TaskStatus.selesai,
);
