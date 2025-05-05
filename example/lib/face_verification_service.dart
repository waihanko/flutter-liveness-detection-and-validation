import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as image_lib;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper_plus/tflite_flutter_helper_plus.dart' as helper;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter_plus/src/bindings/types.dart' as tflp_internal;

class FaceVerificationService {
  static FaceVerificationService? _instance;
  static late final Interpreter _interpreter;

  FaceVerificationService._internal();

  /// Initializes the singleton instance
  static Future<void> init() async {
    _interpreter = await Interpreter.fromAsset('assets/models/facenet.tflite');
    _instance = FaceVerificationService._internal();
  }

  /// Check if the service is initialized
  static bool get isInitialized => _instance != null && _interpreter != null;

  /// Access the instance safely
  static FaceVerificationService get instance {
    if (!isInitialized) {
      throw Exception('FaceVerificationService not initialized. Call await FaceVerificationService.init() first.');
    }
    return _instance!;
  }


  /// Detect and tightly crop the face
  Future<image_lib.Image?> detectAndCropFace(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
    );

    final List<Face> faces = await faceDetector.processImage(inputImage);
    if (faces.isEmpty) return null;

    final face = faces.first;
    final boundingBox = face.boundingBox;

    final bytes = await imageFile.readAsBytes();
    final originalImage = image_lib.decodeImage(bytes);
    if (originalImage == null) return null;

    const double marginRatio = 0.08;
    final int x = (boundingBox.left - boundingBox.width * marginRatio)
        .toInt()
        .clamp(0, originalImage.width - 1);
    final int y = (boundingBox.top - boundingBox.height * marginRatio)
        .toInt()
        .clamp(0, originalImage.height - 1);
    final int w = (boundingBox.width * (1 + 2 * marginRatio)).toInt();
    final int h = (boundingBox.height * (1 + 2 * marginRatio)).toInt();

    int size = math.max(w, h);
    size = math.min(
        size, math.min(originalImage.width - x, originalImage.height - y));

    final cropped = image_lib.copyCrop(originalImage, x, y, size, size);
    final resized = image_lib.copyResize(cropped, width: 160, height: 160);

    return resized;
  }

  /// Generate embedding vector from cropped image
  Future<List<double>> getEmbedding(image_lib.Image image) async {
    var inputImage = helper.TensorImage(tflp_internal.TfLiteType.float32);
    inputImage.loadImage(image);

    final processor = helper.ImageProcessorBuilder()
        .add(helper.ResizeOp(160, 160, helper.ResizeMethod.bilinear))
        .add(helper.NormalizeOp(127.5, 127.5))
        .build();

    inputImage = processor.process(inputImage);

    var outputBuffer = helper.TensorBufferFloat([1, 128]);
    _interpreter.run(inputImage.buffer, outputBuffer.buffer);

    return outputBuffer.getDoubleList();
  }

  /// Cosine similarity between two embeddings
  double cosineSimilarity(List<double> a, List<double> b) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
  }

  /// Convert Image object to File (if needed)
  Future<File> convertImageToFile(
      image_lib.Image image, String fileName) async {
    Uint8List bytes = Uint8List.fromList(image_lib.encodeJpg(image));
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName.jpg');
    await file.writeAsBytes(bytes);
    return file;
  }
}
