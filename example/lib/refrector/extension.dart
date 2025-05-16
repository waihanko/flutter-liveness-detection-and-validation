enum LivenessDetectionStep {
  blink,
  lookRight,
  lookLeft,
  lookUp,
  lookDown,
  smile,
}


extension LivenessDetectionStepExtension on LivenessDetectionStep {
  String get displayName {
    switch (this) {
      case LivenessDetectionStep.blink:
        return 'Blink';
      case LivenessDetectionStep.lookRight:
        return 'Look Right';
      case LivenessDetectionStep.lookLeft:
        return 'Look Left';
      case LivenessDetectionStep.lookUp:
        return 'Look Up';
      case LivenessDetectionStep.lookDown:
        return 'Look Down';
      case LivenessDetectionStep.smile:
        return 'Smile';
    }
  }
}