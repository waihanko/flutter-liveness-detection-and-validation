import 'dart:math' as math;
import 'package:flutter/material.dart';

class CircularProgressPainter extends CustomPainter {
  final double currentStep;
  final double maxStep;
  final double widthLine;
  final double heightLine;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Gradient? gradientColor;

  CircularProgressPainter({
    required this.maxStep,
    required this.widthLine,
    required this.heightLine,
    required this.currentStep,
    required this.selectedColor,
    required this.unselectedColor,
    required this.gradientColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = math.min(centerX, centerY);

    final rect = Rect.fromCircle(center: Offset(centerX, centerY), radius: radius);

    Paint paint = Paint()..style = PaintingStyle.stroke;

    if (gradientColor != null) {
      paint.shader = gradientColor!.createShader(rect);
    }

    _drawStepArc(canvas, paint, size, centerX, centerY, radius);
  }

  void _drawStepArc(
      Canvas canvas,
      Paint paint,
      Size size,
      double centerX,
      double centerY,
      double radius,
      ) {
    final draw = (360 * currentStep) / maxStep;
    final stepLine = 360 / maxStep;

    for (double i = 0; i < 360; i += stepLine) {
      final outerCircleRadius = (radius - (i < draw ? 0 : heightLine / 2));
      final innerCircleRadius = (radius - heightLine);

      final angleRad = i * math.pi / 180;
      final x1 = centerX + outerCircleRadius * math.cos(angleRad);
      final y1 = centerY + outerCircleRadius * math.sin(angleRad);

      final x2 = centerX + innerCircleRadius * math.cos(angleRad);
      final y2 = centerY + innerCircleRadius * math.sin(angleRad);

      final dashBrush = paint
        ..color = i < draw
            ? selectedColor ?? Colors.red
            : unselectedColor ?? Colors.yellow
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = widthLine;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), dashBrush);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
