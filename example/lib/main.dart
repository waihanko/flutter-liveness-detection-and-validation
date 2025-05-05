import 'package:flutter_liveness_detection_randomized_plugin/index.dart';

import 'face_match_screen.dart';
import 'face_verification_service.dart';
import 'helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FaceVerificationService.init();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FaceCompareScreen(),
    // home: HomeView(),
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
                final String? response =
                    await FlutterLivenessDetectionRandomizedPlugin.instance
                        .livenessDetection(
                  context: context,
                  config: LivenessDetectionConfig(
                    isEnableMaxBrightness: true, // enable disable max brightness when taking face photo
                    durationLivenessVerify: 600, // default duration value is 45 second
                    showDurationUiText: false, // show or hide duration remaining when perfoming liveness detection
                    startWithInfoScreen: true, // show or hide tutorial screen
                    useCustomizedLabel: true, // set to true value for enable 'customizedLabel', set to false to use default label
                    // provide an empty string if you want to pass the liveness challenge
                    customizedLabel: Helper.getRandomLivenessModel(),
                  ),
                  isEnableSnackBar: true, // snackbar to notify either liveness is success or failed
                  shuffleListWithSmileLast: true, // put 'smile' challenge always at the end of liveness challenge, if `useCustomizedLabel` is true, this automatically set to false
                  isDarkMode: false, // enable dark/light mode
                  showCurrentStep: true, // show number current step of liveness
                );
                if (mounted) {
                  setState(() {
                    imgPath = response; // result liveness
                  });
                }
              },
              label: const Text('Liveness Detection System')),
        ],
      )),
    );
  }
}
