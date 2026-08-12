import 'package:flutter/material.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/helpers/glass_container.dart';

class ShimmerSkeletonList extends StatefulWidget {
  final int itemCount;
  final double cardHeight;

  const ShimmerSkeletonList({
    this.itemCount = 3,
    this.cardHeight = 165.0,
    super.key,
  });

  @override
  State<ShimmerSkeletonList> createState() => _ShimmerSkeletonListState();
}

class _ShimmerSkeletonListState extends State<ShimmerSkeletonList>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.15, end: 0.45).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: widget.itemCount,
          itemBuilder: (context, index) {
            final double paddingVal = widget.cardHeight < 140.0 ? 12.0 : 16.0;
            final bool showLine2 = widget.cardHeight >= 140.0;
            final bool showLine3 = widget.cardHeight >= 160.0;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              height: widget.cardHeight,
              child: LiquidGlassContainer(
                glowColor: AppColors.primary.withAlpha((_opacityAnimation.value * 255).toInt()),
                borderRadius: 18,
                padding: EdgeInsets.all(paddingVal),
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title placeholder
                      Container(
                        width: 140,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((_opacityAnimation.value * 255).toInt()),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(height: widget.cardHeight < 140.0 ? 8 : 12),
                      // Divider placeholder
                      Container(
                        width: double.infinity,
                        height: 1.5,
                        color: AppColors.divider.withAlpha((_opacityAnimation.value * 120).toInt()),
                      ),
                      SizedBox(height: widget.cardHeight < 140.0 ? 12 : 16),
                      // Line 1 placeholder
                      Container(
                        width: 200,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((_opacityAnimation.value * 180).toInt()),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      if (showLine2) ...[
                        const SizedBox(height: 8),
                        // Line 2 placeholder
                        Container(
                          width: 120,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha((_opacityAnimation.value * 180).toInt()),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                      if (showLine3) ...[
                        const SizedBox(height: 8),
                        // Line 3 placeholder
                        Container(
                          width: 160,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha((_opacityAnimation.value * 180).toInt()),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
