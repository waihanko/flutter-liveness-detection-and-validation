import 'package:flutter_liveness_detection_randomized_plugin/index.dart';

class MachineLearningKitHelper {
  MachineLearningKitHelper._privateConstructor();
  static final MachineLearningKitHelper instance =
      MachineLearningKitHelper._privateConstructor();

  final FaceDetector faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      enableLandmarks: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  Future<List<Face>> processInputImage(InputImage imgFile) async {
    const maxAttempts = 3;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final List<Face> faces = await faceDetector.processImage(imgFile);
      if (faces.isNotEmpty) return faces;
    }

    return [];
  }
}
