import 'package:flutter/material.dart';
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
