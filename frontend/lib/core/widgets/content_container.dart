import 'package:flutter/material.dart';
import 'package:novadis_cri/core/theme/responsive.dart';

/// Widget qui centre et contraint la largeur max du contenu
/// avec padding responsive
class ContentContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ContentContainer({
    super.key,
    required this.child,
    this.maxWidth = 1400,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? Responsive.responsivePadding(context),
          child: child,
        ),
      ),
    );
  }
}
