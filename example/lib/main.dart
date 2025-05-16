import 'package:flutter_liveness_detection_randomized_plugin/index.dart';

import 'face_verification_service.dart';
import 'helper.dart';
import 'refrector/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FaceVerificationService.init(modelPath: "assets/models/facenet.tflite");
  runApp( const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: HomePage(),
  ));
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<String?> capturedImages = [];
  String? imgPath;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(12),
        children: [
          if (imgPath != null) ...[
            const Text(
              'Result Liveness Detection',
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 12,
            ),
            Align(
              child: SizedBox(
                height: 100,
                width: 100,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(
                    File(imgPath!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 12,
            ),
          ],
          ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt_rounded),
              onPressed: () async {

                    await FlutterLivenessDetectionRandomizedPlugin.instance
                        .livenessDetection(
                  context: context,
                  config: LivenessDetectionConfig(
                    isEnableMaxBrightness: true,
                    // enable disable max brightness when taking face photo
                    durationLivenessVerify: 8000,
                    // default duration value is 45 second
                    showDurationUiText: false,
                    // show or hide duration remaining when perfoming liveness detection
                    useCustomizedLabel: true,
                    // set to true value for enable 'customizedLabel', set to false to use default label
                    // provide an empty string if you want to pass the liveness challenge
                    customizedLabel: Helper.getRandomLivenessModel(),
                  ),
                  // snackbar to notify either liveness is success or failed
                  shuffleListWithSmileLast: true,
                  // put 'smile' challenge always at the end of liveness challenge, if `useCustomizedLabel` is true, this automatically set to false
                  isDarkMode: false,
                  // enable dark/light mode
                  showCurrentStep: true,
                  // show number current step of liveness
                  onDetectionCompleted: (detectedFaceImage) {
                    print("Detected Face Link $detectedFaceImage");
                    if (mounted) {
                      setState(() {
                        imgPath = detectedFaceImage; // result liveness
                      });
                    }
                  },
                );

              },
              label: const Text('Liveness Detection System')),
        ],
      )),
    );
  }
}


// Custom painter for head mask
class HeadMaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}