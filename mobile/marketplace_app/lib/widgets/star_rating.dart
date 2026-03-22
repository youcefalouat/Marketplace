import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double average;
  final int count;
  final double size;

  const StarRating({
    super.key,
    required this.average,
    required this.count,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = average.clamp(0, 5);
    final full = clamped.floor();
    final hasHalf = (clamped - full) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            i < full
                ? Icons.star
                : (i == full && hasHalf)
                    ? Icons.star_half
                    : Icons.star_border,
            size: size,
            color: Colors.amber[700],
          ),
        const SizedBox(width: 6),
        Text(
          clamped.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size * 0.9,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($count)',
          style: TextStyle(
            fontSize: size * 0.85,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
