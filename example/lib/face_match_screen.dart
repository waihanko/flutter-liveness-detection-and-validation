import 'package:flutter_liveness_detection_randomized_plugin/index.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as image_lib;

import 'face_verification_service.dart';
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
  final faceService = FaceVerificationService.instance;

  @override
  void initState() {
    super.initState();
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
    final imageFile = File(picked.path);

    image_lib.Image? cropped = await faceService.detectAndCropFace(imageFile);

    if (cropped != null) {
      //To Show in view
      final embedding = await faceService.getEmbedding(cropped);

      setState(() {
        if (imageNumber == 1) {
          faceService.convertImageToFile(cropped, "${DateTime.now()}_temp_image_1").then(
            (value) {
              setState(() {
                image1 = value;
                embedding1 = embedding;
                isProcessImage1 = false;
              });
            },
          );
        } else {
          faceService.convertImageToFile(cropped, "${DateTime.now()}_temp_image_2").then(
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
                        durationLivenessVerify: 800,
                        // default duration value is 45 second
                        showDurationUiText: true,
                        // show or hide tutorial screen
                        useCustomizedLabel: true,
                        // set to true value for enable 'customizedLabel', set to false to use default label
                        customizedLabel: Helper.getRandomLivenessModel(
                            alwaysIncludeSmile: true),

                        activeStepColor: Colors.green,

                        inActiveStepColor: Color(0xFFCDD2DA)
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
                          await faceService.detectAndCropFace(File(response!));
                      embedding2 = await faceService.getEmbedding(cropped!);
                      // image2 = File(response); // to show original image
                      await faceService.convertImageToFile(
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
                final similarity = faceService.cosineSimilarity(embedding1!, embedding2!);
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
