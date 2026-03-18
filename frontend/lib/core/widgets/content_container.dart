import 'package:flutter/material.dart';

/// Widget qui centre et contraint la largeur max du contenu
class ContentContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ContentContainer({
    super.key,
    required this.child,
    this.maxWidth = 1400,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
