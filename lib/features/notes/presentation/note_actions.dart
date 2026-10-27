import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/confirm_delete_dialog.dart';
import '../data/note.dart';
import '../providers/note_provider.dart';

/// Confirms and deletes [n]. Returns true when deleted, false when cancelled
/// or failed; a failure is reported here, success is left to the caller so
/// it can show the message on the right page.
Future<bool> deleteNote(BuildContext context, Note n) async {
  final provider = context.read<NoteProvider>();
  final messenger = ScaffoldMessenger.of(context);
  if (!await confirmDelete(context, itemName: 'catatan ${n.title}')) {
    return false;
  }
  final error = await provider.delete(n.id!);
  if (error != null) messenger.showSnackBar(SnackBar(content: Text(error)));
  return error == null;
}
