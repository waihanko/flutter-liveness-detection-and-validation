import 'package:flutter_liveness_detection_randomized_plugin/index.dart';

List<LivenessDetectionStepItem> stepLiveness = [
  LivenessDetectionStepItem(
    step: LivenessDetectionStep.blink,
    title: "Blink 2-3 Times",
  ),
  LivenessDetectionStepItem(
    step: LivenessDetectionStep.lookUp,
    title: "Look UP",
  ),
  LivenessDetectionStepItem(
    step: LivenessDetectionStep.lookDown,
    title: "Look DOWN",
  ),
  LivenessDetectionStepItem(
    step: LivenessDetectionStep.lookRight,
    title: "Look RIGHT",
  ),
  LivenessDetectionStepItem(
    step: LivenessDetectionStep.lookLeft,
    title: "Look LEFT",
  ),
  LivenessDetectionStepItem(
    step: LivenessDetectionStep.smile,
    title: "Smile",
  ),
];
