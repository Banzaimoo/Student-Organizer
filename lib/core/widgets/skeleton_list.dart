import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Loading placeholder shaped like a grouped list of two-line rows.
/// Pulses gently; stays static when the platform asks for reduced motion.
class SkeletonList extends StatefulWidget {
  const SkeletonList({super.key, this.rows = 5});

  final int rows;

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppSpacing.xs),
          ),
        );

    return Semantics(
      label: 'Memuat',
      child: FadeTransition(
        opacity: Tween(begin: 0.45, end: 1.0).animate(_controller),
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: widget.rows,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                bar(44, 32),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FractionallySizedBox(
                        widthFactor: i.isEven ? 0.6 : 0.45,
                        child: bar(double.infinity, 14),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FractionallySizedBox(
                        widthFactor: 0.35,
                        child: bar(double.infinity, 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
