import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Small group heading, optionally followed by a highlighted badge.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.badge, this.trailing});

  final String title;
  final String? badge;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xs, AppSpacing.xl, AppSpacing.xs, AppSpacing.sm),
      child: Row(
        children: [
          Text(
            title,
            style: text.titleSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (badge != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                badge!,
                style: text.labelSmall?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}
