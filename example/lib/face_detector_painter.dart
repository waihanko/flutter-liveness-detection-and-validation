import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

// class FaceDetectorPainter extends CustomPainter {
//   FaceDetectorPainter(
//       this.faces,
//       this.imageSize,
//       this.rotation,
//       this.cameraLensDirection,
//       );
//
//   final List<Face> faces;
//   final Size imageSize;
//   final InputImageRotation rotation;
//   final CameraLensDirection cameraLensDirection;
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final Paint paint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 4;
//
//     // Central frame: 60% width, 50% height of screen
//     final double frameWidth = size.width * 0.6;
//     final double frameHeight = size.height * 0.5;
//     final Offset center = Offset(size.width / 2, size.height / 2);
//     final Rect frameRect = Rect.fromCenter(
//       center: center,
//       width: frameWidth,
//       height: frameHeight,
//     );
//
//     bool faceIsInside = false;
//
//     if (faces.isNotEmpty) {
//       final face = faces.first;
//
//       Rect faceRect = _scaleRect(face.boundingBox, imageSize, size);
//
//       // If using front camera, mirror the X axis
//       if (cameraLensDirection == CameraLensDirection.front) {
//         faceRect = Rect.fromLTRB(
//           size.width - faceRect.right,
//           faceRect.top,
//           size.width - faceRect.left,
//           faceRect.bottom,
//         );
//       }
//
//       faceIsInside =
//           frameRect.contains(faceRect.topLeft) &&
//               frameRect.contains(faceRect.bottomRight);
//     }
//
//     // Choose red or green based on face position
//     paint.color = faceIsInside ? Colors.green : Colors.red;
//
//     _drawCorners(canvas, frameRect, paint);
//   }
//
//   Rect _scaleRect(Rect rect, Size imageSize, Size widgetSize) {
//     final double scaleX = widgetSize.width / imageSize.width;
//     final double scaleY = widgetSize.height / imageSize.height;
//
//     return Rect.fromLTRB(
//       rect.left * scaleX,
//       rect.top * scaleY,
//       rect.right * scaleX,
//       rect.bottom * scaleY,
//     );
//   }
//
//   void _drawCorners(Canvas canvas, Rect rect, Paint paint) {
//     const double cornerLength = 20.0;
//
//     // Top-left
//     canvas.drawLine(rect.topLeft, rect.topLeft + Offset(cornerLength, 0), paint);
//     canvas.drawLine(rect.topLeft, rect.topLeft + Offset(0, cornerLength), paint);
//
//     // Top-right
//     canvas.drawLine(rect.topRight, rect.topRight - Offset(cornerLength, 0), paint);
//     canvas.drawLine(rect.topRight, rect.topRight + Offset(0, cornerLength), paint);
//
//     // Bottom-left
//     canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(cornerLength, 0), paint);
//     canvas.drawLine(rect.bottomLeft, rect.bottomLeft - Offset(0, cornerLength), paint);
//
//     // Bottom-right
//     canvas.drawLine(rect.bottomRight, rect.bottomRight - Offset(cornerLength, 0), paint);
//     canvas.drawLine(rect.bottomRight, rect.bottomRight - Offset(0, cornerLength), paint);
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }


class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter(
      this.faces,
      this.imageSize,
      this.rotation,
      this.cameraLensDirection,
      );

  final List<Face> faces;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.red;
    final Paint paint2 = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 1.0
      ..color = Colors.green;

    for (final Face face in faces) {
      final left = translateX(
        face.boundingBox.left,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final top = translateY(
        face.boundingBox.top,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final right = translateX(
        face.boundingBox.right,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final bottom = translateY(
        face.boundingBox.bottom,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );

      canvas.drawRect(
        Rect.fromLTRB(left, top, right, bottom),
        paint1,
      );

      // Get the emotion
      final String emotion = _detectEmotion(face);

// Calculate top-center position of the face bounding box
      final double labelX = (left + right) / 2;
      final double labelY = top - 10; // Slightly above the bounding box

// Configure text style
      final textSpan = TextSpan(
        text: emotion,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

// Draw background rectangle behind the text
      final backgroundRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(labelX, labelY - textPainter.height / 2),
          width: textPainter.width + 10,
          height: textPainter.height + 6,
        ),
        const Radius.circular(6),
      );

      final Paint backgroundPaint = Paint()..color = Colors.white;
      canvas.drawRRect(backgroundRect, backgroundPaint);

// Draw the label text
      textPainter.paint(
        canvas,
        Offset(labelX - textPainter.width / 2, labelY - textPainter.height),
      );

      void paintContour(FaceContourType type) {
        final contour = face.contours[type];
        if (contour?.points != null) {
          for (final Point point in contour!.points) {
            canvas.drawCircle(
              Offset(
                translateX(
                  point.x.toDouble(),
                  size,
                  imageSize,
                  rotation,
                  cameraLensDirection,
                ),
                translateY(
                  point.y.toDouble(),
                  size,
                  imageSize,
                  rotation,
                  cameraLensDirection,
                ),
              ),
              1,
              paint1,
            );
          }
        }
      }

      void paintLandmark(FaceLandmarkType type) {
        final landmark = face.landmarks[type];
        if (landmark?.position != null) {
          canvas.drawCircle(
            Offset(
              translateX(
                landmark!.position.x.toDouble(),
                size,
                imageSize,
                rotation,
                cameraLensDirection,
              ),
              translateY(
                landmark.position.y.toDouble(),
                size,
                imageSize,
                rotation,
                cameraLensDirection,
              ),
            ),
            2,
            paint2,
          );
        }
      }

      for (final type in FaceContourType.values) {
        paintContour(type);
      }

      for (final type in FaceLandmarkType.values) {
        paintLandmark(type);
      }
    }
  }

  String _detectEmotion(Face face) {
    if (face.smilingProbability != null && face.smilingProbability! > 0.6) {
      return 'Smile';
    } else if ((face.leftEyeOpenProbability != null &&
        face.leftEyeOpenProbability! < 0.3) ||
        (face.rightEyeOpenProbability != null &&
            face.rightEyeOpenProbability! < 0.3)) {
      return 'Blink';
    } else if (face.headEulerAngleY != null && face.headEulerAngleY! < -15) {
      return 'Look Right';
    } else if (face.headEulerAngleY != null && face.headEulerAngleY! > 15) {
      return 'Look Left';
    } else {
      return 'Neutral';
    }
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize || oldDelegate.faces != faces;
  }
}

double translateX(
    double x,
    Size canvasSize,
    Size imageSize,
    InputImageRotation rotation,
    CameraLensDirection cameraLensDirection,
    ) {
  switch (rotation) {
    case InputImageRotation.rotation90deg:
      return x *
          canvasSize.width /
          (Platform.isIOS ? imageSize.width : imageSize.height);
    case InputImageRotation.rotation270deg:
      return canvasSize.width -
          x *
              canvasSize.width /
              (Platform.isIOS ? imageSize.width : imageSize.height);
    case InputImageRotation.rotation0deg:
    case InputImageRotation.rotation180deg:
      switch (cameraLensDirection) {
        case CameraLensDirection.back:
          return x * canvasSize.width / imageSize.width;
        default:
          return canvasSize.width - x * canvasSize.width / imageSize.width;
      }
  }
}

double translateY(
    double y,
    Size canvasSize,
    Size imageSize,
    InputImageRotation rotation,
    CameraLensDirection cameraLensDirection,
    ) {
  switch (rotation) {
    case InputImageRotation.rotation90deg:
    case InputImageRotation.rotation270deg:
      return y *
          canvasSize.height /
          (Platform.isIOS ? imageSize.height : imageSize.width);
    case InputImageRotation.rotation0deg:
    case InputImageRotation.rotation180deg:
      return y * canvasSize.height / imageSize.height;
  }
}
