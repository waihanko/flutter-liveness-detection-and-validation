import 'dart:math';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_liveness_detection_randomized_plugin_example/refrector/small_screen_ui.dart';

import 'extension.dart';
import 'rounded_center_clipper.dart'; // Import the new clipper file
import 'corner_frame_painter.dart'; // Import the new painter file

// Helper methods for duration and countdown text
Widget getDurationUI({required int remainingDuration, required int currentChallengeIndex, required List<LivenessDetectionStep> challengeActions, bool isShowDurationText = true, bool isShowCurrentStep = true}){
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if(isShowDurationText) Text(
        _getRemainingTimeText(remainingDuration),
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      if(isShowCurrentStep) Text(
        _getRemainingCountDownText(currentChallengeIndex, challengeActions.length),
        style: const TextStyle(
          color: Colors.black,
        ),
      ),
    ],
  );
}

String _getRemainingTimeText(int duration) {
  int minutes = duration ~/ 60;
  int seconds = duration % 60;
  return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
}

String _getRemainingCountDownText(int currentChallengeIndex, int totalChallenges) {
  if(currentChallengeIndex == totalChallenges ){
    return "$currentChallengeIndex/$totalChallenges";
  }else{
    return "${(currentChallengeIndex) + 1}/$totalChallenges";
  }
}

// Widget to build the live feed body UI
Widget buildFaceDetectorLiveFeedBody({
  required BuildContext context,
  required CameraController controller,
  required bool isTakingPicture,
  required bool isFaceDetected,
  required CustomPaint? customPaint,
  required List<LivenessDetectionStep> challengeActions,
  required int currentChallengeIndex,
  required int remainingDuration,
}) {
  Size size = MediaQuery.sizeOf(context);
  double width = min(size.width, size.height);

  return  Stack(
    fit: StackFit.expand,
    children: [
      Positioned.fill(
        child: Stack(
          children: [
            Positioned(left: -8,right: -8, top: 0, bottom:0 ,child: CameraPreview(controller)),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                color: Colors.black.withOpacity(0.2), // Optional tint
              ),
            ),
          ],
        ),
      ),
      // ScanningView(controller: controller, isProcessing: currentChallengeIndex >= challengeActions.length,),

      ClipPath(
        clipper: RoundedCenterClipper(
          width: width * 0.6,
          height: width * 0.7,
          borderRadius: 25,
        ),
        child: Align(
          alignment: Alignment.topRight,
          child: Stack(
            children: [
              CameraPreview(controller), // takes full size
            ],
          ),
        ),
      ),
      Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: width * 0.6,
          height: width * 0.7,
          child: CustomPaint(
            painter: CornerFramePainter(isFaceDetected : isFaceDetected),
          ),
        ),
      ),
      // LargeScreenUI(),
      SmallScreenUI(
        challengeList: challengeActions,
        currentStep : currentChallengeIndex,
        durationUI: getDurationUI(
          remainingDuration: remainingDuration,
          currentChallengeIndex: currentChallengeIndex,
          challengeActions: challengeActions,
          isShowCurrentStep: true,
          isShowDurationText: true,
        ),
      ),
    ],
  );
}

class ScanLinePainter extends CustomPainter {
  final double yOffset;

  ScanLinePainter(this.yOffset);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Colors.white10,
          Colors.greenAccent,
          Colors.white10,
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, yOffset, size.width, 4));

    canvas.drawRect(Rect.fromLTWH(0, yOffset, size.width, 4), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class ScanningView extends StatefulWidget {
  final CameraController controller;
  final bool isProcessing;
  const ScanningView({required this.controller,  this.isProcessing= false});

  @override
  _ScanningViewState createState() => _ScanningViewState();
}

class _ScanningViewState extends State<ScanningView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final double frameWidthFactor = 0.6;
  final double frameHeightFactor = 0.7;
  final double borderRadius = 25;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double baseWidth = min(size.width, size.height);

    // These should match the clipper’s dimensions
    final double frameWidth = baseWidth * frameWidthFactor;
    final double frameHeight = baseWidth * frameHeightFactor;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final scanY = _animation.value * frameHeight;

        return ClipPath(
          clipper: RoundedCenterClipper(
            width: frameWidth,
            height: frameHeight,
            borderRadius: borderRadius,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: Stack(
              children: [
                CameraPreview(widget.controller), // takes full size
                if (widget.isProcessing)
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: frameWidth,
                      height: frameHeight,
                      child: CustomPaint(
                        painter: ScanLinePainter(scanY),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

}
