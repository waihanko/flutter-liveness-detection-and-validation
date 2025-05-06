import 'package:flutter_liveness_detection_randomized_plugin/index.dart';

abstract class Helper{
  //Get Two Pair Of Live Check
  static LivenessDetectionLabelModel getRandomLivenessModel({bool alwaysIncludeSmile = false}) {
    final random = Random();
    const allSteps = LivenessDetectionStep.values;

    // Convert enum to string names
    final allKeys = allSteps.map((e) => e.name).toList();

    List<String> enabledKeys;
    if (alwaysIncludeSmile) {
      final keysWithoutSmile = allKeys.where((k) => k != 'smile').toList();
      keysWithoutSmile.shuffle(random);
      enabledKeys = [keysWithoutSmile.first, 'smile'];
    } else {
      final shuffledKeys = [...allKeys]..shuffle(random);
      enabledKeys = shuffledKeys.take(2).toList();
    }

    final enabledSet = enabledKeys.toSet();

    return LivenessDetectionLabelModel(
      lookDown: enabledSet.contains('lookDown') ? null : '',
      lookLeft: enabledSet.contains('lookLeft') ? null : '',
      lookRight: enabledSet.contains('lookRight') ? null : '',
      lookUp: enabledSet.contains('lookUp') ? null : '',
      blink: enabledSet.contains('blink') ? null : '',
      lookStraight: enabledSet.contains('lookStraight') ? null : '',
      smile: enabledSet.contains('smile') ? null : '',
    );
  }

}