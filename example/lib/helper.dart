import 'package:flutter_liveness_detection_randomized_plugin/index.dart';

abstract class Helper{
  //Get Two Pair Of Live Check
  static LivenessDetectionLabelModel getRandomLivenessModel({bool alwaysIncludeSmile = false}) {
    final random = Random();
    final allKeys = ['lookDown', 'lookLeft', 'lookRight', 'lookUp', 'blink', 'smile'];

    List<String> enabledKeys;
    if (alwaysIncludeSmile) {
      // Exclude 'smile' from random selection, then pick one, then add 'smile'
      final keysWithoutSmile = allKeys.where((k) => k != 'smile').toList();
      keysWithoutSmile.shuffle(random);
      enabledKeys = [keysWithoutSmile.first, 'smile'];
    } else {
      // Just pick 2 random keys
      final shuffledKeys = [...allKeys]..shuffle(random);
      enabledKeys = shuffledKeys.take(2).toList();
    }

    final enabledSet = enabledKeys.toSet();

    var model = LivenessDetectionLabelModel(
      lookDown: enabledSet.contains('lookDown') ? null : '',
      lookLeft: enabledSet.contains('lookLeft') ? null : '',
      lookRight: enabledSet.contains('lookRight') ? null : '',
      lookUp: enabledSet.contains('lookUp') ? null : '',
      blink: enabledSet.contains('blink') ? null : '',
      smile: enabledSet.contains('smile') ? null : '',
    );
    return model;
  }

}