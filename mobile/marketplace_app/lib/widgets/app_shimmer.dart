import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Animated shimmer box used for skeleton loaders.
///
/// If [height] is omitted the box expands to fill its parent (works inside
/// Expanded / SizedBox.expand contexts).  Pass an explicit [height] for
/// fixed-size text-line skeletons.
///
/// Each instance owns one [AnimationController]. Acceptable because skeleton
/// screens are transient and contain at most ~10 boxes at a time.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _offset = Tween<double>(begin: -1.5, end: 2.5).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final br = widget.borderRadius ??
        BorderRadius.circular(AppLayout.radiusFull);

    return AnimatedBuilder(
      animation: _offset,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: br,
          gradient: LinearGradient(
            begin: Alignment(_offset.value - 1, 0),
            end: Alignment(_offset.value + 1, 0),
            colors: [
              colors.shimmer,
              Color.lerp(colors.shimmer, colors.surfaceElevated2, 0.65)!,
              colors.shimmer,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}
