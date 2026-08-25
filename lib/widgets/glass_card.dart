import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 24,
    this.tint = AppColors.surface,
    this.borderColor = const Color(0x99FFFFFF),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color tint;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}