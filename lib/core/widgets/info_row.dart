import 'package:flutter/material.dart';

/// Label/value row used in detail pages.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return ListTile(
      leading: Icon(icon, color: scheme.onSurfaceVariant),
      title: Text(
        label,
        style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      subtitle: Text(
        value,
        style: text.bodyLarge?.copyWith(color: scheme.onSurface),
      ),
    );
  }
}
