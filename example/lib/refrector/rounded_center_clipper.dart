import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math';

class RoundedCenterClipper extends CustomClipper<Path> {
  final double width;
  final double height;
  final double borderRadius;

  RoundedCenterClipper({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(
      center: center,
      width: width,
      height: height,
    );

    final rRect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    return Path()..addRRect(rRect);
  }

  @override
  bool shouldReclip(covariant RoundedCenterClipper oldClipper) {
    return width != oldClipper.width ||
        height != oldClipper.height ||
        borderRadius != oldClipper.borderRadius;
  }
}
