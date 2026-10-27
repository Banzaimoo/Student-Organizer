import 'package:flutter/material.dart';

/// Resolves to `true` only when the user confirms deletion.
Future<bool> confirmDelete(BuildContext context, {String itemName = 'data ini'}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Hapus data?'),
      content: Text('Yakin ingin menghapus $itemName? Tindakan ini tidak dapat dibatalkan.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        // Destructive action reads as destructive, not as the primary accent.
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
            foregroundColor: Theme.of(ctx).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  return result ?? false;
}
