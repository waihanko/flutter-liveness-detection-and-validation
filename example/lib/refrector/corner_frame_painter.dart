import 'package:flutter/material.dart';

class CornerFramePainter extends CustomPainter {
  final bool isFaceDetected;
  const CornerFramePainter({this.isFaceDetected = false});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isFaceDetected? Colors.green:Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const cornerLength = 48.0;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Top-left corner
    canvas.drawArc(
      Rect.fromLTWH(rect.left, rect.top, cornerLength, cornerLength),
      -3.14, // 180° (left)
      1.57,  // 90° sweep
      false,
      paint,
    );

    // Top-right corner
    canvas.drawArc(
      Rect.fromLTWH(rect.right - cornerLength, rect.top, cornerLength, cornerLength),
      -1.57, // -90° (top)
      1.57,  // 90° sweep
      false,
      paint,
    );

    // Bottom-left corner
    canvas.drawArc(
      Rect.fromLTWH(rect.left, rect.bottom - cornerLength, cornerLength, cornerLength),
      3.14,   // 180° (left)
      -1.57,  // -90° sweep (clockwise)
      false,
      paint,
    );

    // ✅ Bottom-right corner (fixed)
    canvas.drawArc(
      Rect.fromLTWH(rect.right - cornerLength, rect.bottom - cornerLength, cornerLength, cornerLength),
      1.57,      // start from bottom
      -1.57,     // sweep up to right
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
