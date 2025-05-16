
//Get Two Pair Of Live Check
import 'dart:math';

import 'extension.dart';

abstract class StepGenerator {
  // Get Two Random Liveness Steps, optionally always include 'smile'
  static List<LivenessDetectionStep> getRandomLivenessSteps({bool alwaysIncludeSmile = false}) {
    final random = Random();
    const allSteps = LivenessDetectionStep.values;

    // If you want to always include smile, pick one random excluding smile
    if (alwaysIncludeSmile) {
      final withoutSmile = allSteps.where((e) => e != LivenessDetectionStep.smile).toList();
      withoutSmile.shuffle(random);
      return [LivenessDetectionStep.smile, withoutSmile.first];
    }

    // Otherwise, just pick any two random distinct steps
    final shuffled = [...allSteps]..shuffle(random);
    return shuffled.take(2).toList();
  }
}