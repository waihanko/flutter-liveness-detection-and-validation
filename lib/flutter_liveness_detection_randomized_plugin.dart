import 'package:flutter_liveness_detection_randomized_plugin/index.dart';

class FlutterLivenessDetectionRandomizedPlugin {
  FlutterLivenessDetectionRandomizedPlugin._privateConstructor();
  static final FlutterLivenessDetectionRandomizedPlugin instance =
      FlutterLivenessDetectionRandomizedPlugin._privateConstructor();
  final List<LivenessDetectionThreshold> _thresholds = [];

  List<LivenessDetectionThreshold> get thresholdConfig {
    return _thresholds;
  }

  Future<void> livenessDetection({
    String? title,
    required BuildContext context,
    required LivenessDetectionConfig config,
    required bool shuffleListWithSmileLast,
    required bool showCurrentStep,
    required bool isDarkMode,
    required Function( String? detectedFaceImage) onDetectionCompleted,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LivenessDetectionView(
          config: config,
          title: title,
          shuffleListWithSmileLast: shuffleListWithSmileLast,
          showCurrentStep: showCurrentStep,
          isDarkMode: isDarkMode,
            onDetectionCompleted: onDetectionCompleted
        ),
      ),
    );
  }

  Future<String?> getPlatformVersion() {
    return FlutterLivenessDetectionRandomizedPluginPlatform.instance
        .getPlatformVersion();
  }
}
