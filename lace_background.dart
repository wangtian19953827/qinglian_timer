import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

class LaceBackground extends StatelessWidget {
  const LaceBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bgTop, AppColors.bgMid, AppColors.bgBottom],
          stops: [0, 0.45, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: LacePatternPainter(color: AppColors.lace)),
          child,
        ],
      ),
    );
  }
}

class LacePatternPainter extends CustomPainter {
  const LacePatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    final dot = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    _scallopRow(canvas, Offset(0, 12), size.width, line, dot);
    _scallopRow(canvas, Offset(0, size.height - 64), size.width, line, dot);
  }

  void _scallopRow(
    Canvas canvas,
    Offset origin,
    double width,
    Paint line,
    Paint dot,
  ) {
    const double spacing = 30;
    const double radius = 7;
    final count = (width / spacing).ceil();
    for (var i = 0; i < count; i++) {
      final center = Offset(
        origin.dx + i * spacing + spacing / 2,
        origin.dy + radius,
      );
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, math.pi, math.pi, false, line);
      canvas.drawCircle(center.translate(0, -radius - 3), 1.1, dot);
      canvas.drawCircle(center.translate(-6, -2), 0.9, dot);
      canvas.drawCircle(center.translate(6, -2), 0.9, dot);
    }
  }

  @override
  bool shouldRepaint(covariant LacePatternPainter oldDelegate) =>
      oldDelegate.color != color;
}