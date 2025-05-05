import 'dart:typed_data';
import 'package:flutter_liveness_detection_randomized_plugin/index.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper_plus/tflite_flutter_helper_plus.dart'
    as helper;
import 'dart:math' as math;
import 'package:tflite_flutter_plus/src/bindings/types.dart' as tflp_internal;
import 'package:image/image.dart' as image_lib;
import 'package:path_provider/path_provider.dart';

import 'helper.dart';

class FaceCompareScreen extends StatefulWidget {
  const FaceCompareScreen({super.key});

  @override
  _FaceCompareScreenState createState() => _FaceCompareScreenState();
}

class _FaceCompareScreenState extends State<FaceCompareScreen> {
  late Interpreter interpreter;
  File? image1;
  File? image2;
  List<double>? embedding1;
  List<double>? embedding2;
  bool isProcessImage1 = false;
  bool isProcessImage2 = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    interpreter = await Interpreter.fromAsset('assets/models/facenet.tflite');
  }

  Future<List<double>> _getEmbedding(image_lib.Image image) async {
    // Step 1: Create TensorImage with proper type
    helper.TensorImage inputImage =
        helper.TensorImage(tflp_internal.TfLiteType.float32);
    inputImage.loadImage(image);

    // Step 2: Resize to 160x160 and normalize to [-1, 1]
    final processor = helper.ImageProcessorBuilder()
        .add(helper.ResizeOp(160, 160, helper.ResizeMethod.bilinear))
        .add(helper.NormalizeOp(127.5, 127.5)) // x = (x - 127.5) / 127.5
        .build();

    inputImage = processor.process(inputImage);

    // Step 3: Create output buffer for 128-dim embedding
    helper.TensorBuffer outputBuffer = helper.TensorBufferFloat([1, 128]);

    // Step 4: Run inference
    interpreter.run(inputImage.buffer, outputBuffer.buffer);

    // Step 5: Return the 128-dimensional embedding
    return outputBuffer.getDoubleList();
  }

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

  void _pickImage(int imageNumber) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) {
      setState(() {
        isProcessImage1 = false;
        isProcessImage2 = false;
      });
      return;
    }
    final imageFile = File(picked!.path);

    image_lib.Image? cropped = await detectAndCropFace(imageFile);

    if (cropped != null) {
      //To Show in view
      final embedding = await _getEmbedding(cropped);

      setState(() {
        if (imageNumber == 1) {
          convertImageToFile(cropped, "${DateTime.now()}_temp_image_1").then(
            (value) {
              setState(() {
                image1 = value;
                embedding1 = embedding;
                isProcessImage1 = false;
              });
            },
          );
        } else {
          convertImageToFile(cropped, "${DateTime.now()}_temp_image_2").then(
            (value) {
              setState(() {
                image2 = value;
                embedding2 = embedding;
                isProcessImage2 = false;
              });
            },
          );
        }
      });
    }
  }

  Future<File> convertImageToFile(
      image_lib.Image image, String fileName) async {
    // Encode image to JPG (or PNG)
    Uint8List bytes = Uint8List.fromList(image_lib.encodeJpg(image));

    // Get temporary directory
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');

    // Write to file
    await file.writeAsBytes(bytes);

    return file;
  }

  // Function to detect faces and crop the first detected face
  Future<image_lib.Image?> detectAndCropFace(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
    );

    // Detect faces
    final List<Face> faces = await faceDetector.processImage(inputImage);
    if (faces.isEmpty) return null; // No faces detected

    final face = faces.first;
    final boundingBox = face.boundingBox;

    final bytes = await imageFile.readAsBytes();
    final originalImage = image_lib.decodeImage(bytes);
    if (originalImage == null) return null;

    // Remove or reduce margin to avoid including shoulder or hair
    // If margin is too large, it might be including the head/shoulders/hair

    // Optional: Set margin to 0 if you're seeing too much of the surrounding area
    const double marginRatio = 0.08; // Decrease margin to keep the face tight
    final int x = (boundingBox.left - boundingBox.width * marginRatio)
        .toInt()
        .clamp(0, originalImage.width - 1);
    final int y = (boundingBox.top - boundingBox.height * marginRatio)
        .toInt()
        .clamp(0, originalImage.height - 1);
    final int w = (boundingBox.width * (1 + 2 * marginRatio)).toInt();
    final int h = (boundingBox.height * (1 + 2 * marginRatio)).toInt();

    // Ensure the crop is square and fits within the image bounds
    int size = math.max(w, h);
    size = math.min(
        size, math.min(originalImage.width - x, originalImage.height - y));

    // Crop the image to the tighter bounding box and resize to 160x160
    final cropped = image_lib.copyCrop(originalImage, x, y, size, size);
    final resized = image_lib.copyResize(cropped, width: 160, height: 160);

    return resized;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face Validation and Verification')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildImagePicker(
                  onTap: () {
                    setState(() {
                      image1 = null;
                      isProcessImage1 = true;
                    });
                    _pickImage(1);
                  },
                  image: image1,
                  icon: Icons.add_a_photo,
                  isProcessImage: isProcessImage1),

              // _buildImagePicker(
              //     onTap: () {
              //       setState(() {
              //         image1 = null;
              //         isProcessImage2 = true;
              //       });
              //       _pickImage(2);
              //     },
              //     image: image1,
              //     icon: Icons.add_a_photo,
              //     isProcessImage: isProcessImage2),

              _buildImagePicker(
                  onTap: () async {
                    setState(() {
                      image2 = null;
                      isProcessImage2 = true;
                    });
                    final String? response =
                        await FlutterLivenessDetectionRandomizedPlugin.instance
                            .livenessDetection(
                      context: context,
                      config: LivenessDetectionConfig(
                        isEnableMaxBrightness: true,
                        // enable disable max brightness when taking face photo
                        durationLivenessVerify: 45,
                        // default duration value is 45 second
                        showDurationUiText: true,
                        // show or hide tutorial screen
                        useCustomizedLabel: true,
                        // set to true value for enable 'customizedLabel', set to false to use default label
                        customizedLabel: Helper.getRandomLivenessModel(
                            alwaysIncludeSmile: true),
                      ),
                      isEnableSnackBar: true,
                      // snackbar to notify either liveness is success or failed
                      shuffleListWithSmileLast: true,
                      // put 'smile' challenge always at the end of liveness challenge, if `useCustomizedLabel` is true, this automatically set to false
                      isDarkMode: false,
                      // enable dark/light mode
                      showCurrentStep:
                          true, // show number current step of liveness
                    );
                    if (mounted) {
                      image_lib.Image? cropped =
                          await detectAndCropFace(File(response!));
                      embedding2 = await _getEmbedding(cropped!);
                      // image2 = File(response); // to show original image
                      await convertImageToFile(
                              cropped, "${DateTime.now()}_temp_image_2")
                          .then(
                        (value) => {
                          setState(() {
                            image2 = value;
                          })
                        },
                      );
                    }
                  },
                  image: image2,
                  icon: Icons.sentiment_very_satisfied_rounded),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          ElevatedButton(
            onPressed: () {
              if (embedding1 != null && embedding2 != null) {
                final similarity = cosineSimilarity(embedding1!, embedding2!);
                print("Distance is $similarity");
                const double threshold = 0.6;
                bool isMatch = similarity > threshold;

                if (isMatch) {
                  print('Match Found!');
                } else {
                  print('No Match.');
                }

                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Validation Result'),
                    content: Text(
                      'Similarity: ${similarity.toStringAsFixed(4)}\nMatch: $isMatch',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              elevation: 4,
            ),
            child: const Text(
              "Validate Faces",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                image1 = null;
                image2 = null;
              });
            },
            child: Text("Clear"),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker({
    required Function onTap,
    required File? image,
    required IconData icon,
    bool isProcessImage = false,
  }) {
    return GestureDetector(
      onTap: () => onTap.call(),
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
        ),
        child: isProcessImage
            ? const SizedBox(
                width: 50,
                height: 50,
                child: Center(child: CircularProgressIndicator()))
            : image == null
                ? Icon(icon, size: 50, color: Colors.grey)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      image,
                      fit: BoxFit.cover,
                    ),
                  ),
      ),
    );
  }
}
