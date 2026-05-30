import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  static const assetPath = 'assets/images/fesh_bay_logo.png';

  final double size;
  final BorderRadius borderRadius;

  const AppLogo({
    super.key,
    this.size = 192,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: 'Fesh Bay',
      ),
    );
  }
}
