import 'package:flutter/material.dart';
import 'package:flutter_liveness_detection_randomized_plugin/src/models/liveness_detection_label_model.dart';

class LivenessDetectionConfig {
  final int? durationLivenessVerify;
  final bool showDurationUiText;
  final bool useCustomizedLabel;
  final LivenessDetectionLabelModel? customizedLabel;
  final bool isEnableMaxBrightness;
  final Color? inActiveStepColor;
  final Color? activeStepColor;

  LivenessDetectionConfig({
    this.activeStepColor,
    this.inActiveStepColor,
    this.durationLivenessVerify,
    this.showDurationUiText = false,
    this.useCustomizedLabel = false,
    this.customizedLabel,
    this.isEnableMaxBrightness = true
  });
}
