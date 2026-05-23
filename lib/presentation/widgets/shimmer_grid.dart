import 'package:flutter/material.dart';

class ShimmerGrid extends StatefulWidget {
  const ShimmerGrid({super.key});

  @override
  State<ShimmerGrid> createState() => _ShimmerGridState();
}

class _ShimmerGridState extends State<ShimmerGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final opacity = _animation.value;
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.7,
          ),
          itemCount: 6,
          itemBuilder: (_, _) => RepaintBoundary(
            child: Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: opacity),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 10 * textScale,
                          width: 100 * textScale,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: opacity),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 8 * textScale,
                          width: 60 * textScale,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: opacity),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                ),
              ],
            ),
            ),
          ),
        );
      },
    );
  }
}
