import 'package:flutter/foundation.dart';
import 'package:flutter_liveness_detection_randomized_plugin/index.dart';
import 'package:flutter_liveness_detection_randomized_plugin/src/core/constants/liveness_detection_step_constant.dart';
import 'package:collection/collection.dart';
import 'package:screen_brightness/screen_brightness.dart';

List<CameraDescription> availableCams = [];

class LivenessDetectionView extends StatefulWidget {
  final LivenessDetectionConfig config;
  final bool isEnableSnackBar;
  final bool shuffleListWithSmileLast;
  final bool showCurrentStep;
  final bool isDarkMode;
  final String? title;
  final Function(String? detectedFaceImage) onDetectionCompleted;

  const LivenessDetectionView({
    super.key,
    required this.config,
    required this.isEnableSnackBar,
    required this.onDetectionCompleted,
    this.title,
    this.isDarkMode = true,
    this.showCurrentStep = false,
    this.shuffleListWithSmileLast = true,
  });

  @override
  State<LivenessDetectionView> createState() => _LivenessDetectionScreenState();
}

class _LivenessDetectionScreenState extends State<LivenessDetectionView> {
  // Camera related variables
  CameraController? _cameraController;
  int _cameraIndex = 0;
  bool _isBusy = false;
  bool _isTakingPicture = false;
  Timer? _timerToDetectFace;

  // Detection state variables
  bool _isProcessingStep = false;
  bool _faceDetectedState = false;

  // Brightness Screen
  Future<void> setApplicationBrightness(double brightness) async {
    try {
      await ScreenBrightness.instance
          .setApplicationScreenBrightness(brightness);
    } catch (e) {
      throw 'Failed to set application brightness';
    }
  }

  Future<void> resetApplicationBrightness() async {
    try {
      await ScreenBrightness.instance.resetApplicationScreenBrightness();
    } catch (e) {
      throw 'Failed to reset application brightness';
    }
  }

  // Steps related variables
  late final List<LivenessDetectionStepItem> steps;
  final GlobalKey<LivenessDetectionStepOverlayWidgetState> _stepsKey =
  GlobalKey<LivenessDetectionStepOverlayWidgetState>();

  static void shuffleListLivenessChallenge({
    required List<LivenessDetectionStepItem> list,
    required bool isSmileLast,
  }) {
    if (isSmileLast) {
      //Move Smile To End
      final index = list.indexWhere((item) =>
      item.step == LivenessDetectionStep.smile);

      if (index != -1) {
        final smileItem = list.removeAt(index);
        list.add(smileItem); // Add smile to the end
      }
    } else {
      list.shuffle(Random());
    }
  }

  List<LivenessDetectionStepItem> customizedLivenessLabel(
      LivenessDetectionLabelModel label) {

      List<LivenessDetectionStepItem> customizedSteps = [];

      if (label.blink != "" && widget.config.useCustomizedLabel) {
        customizedSteps.add(LivenessDetectionStepItem(
          step: LivenessDetectionStep.blink,
          title: label.blink ?? "Blink 2-3 Times",
        ));
      }

      if (label.lookRight != "" && widget.config.useCustomizedLabel) {
        customizedSteps.add(LivenessDetectionStepItem(
          step: LivenessDetectionStep.lookRight,
          title: label.lookRight ?? "Look Right",
        ));
      }

      if (label.lookLeft != "" && widget.config.useCustomizedLabel) {
        customizedSteps.add(LivenessDetectionStepItem(
          step: LivenessDetectionStep.lookLeft,
          title: label.lookLeft ?? "Look Left",
        ));
      }

      if (label.lookUp != "" && widget.config.useCustomizedLabel) {
        customizedSteps.add(LivenessDetectionStepItem(
          step: LivenessDetectionStep.lookUp,
          title: label.lookUp ?? "Look Up",
        ));
      }

      if (label.lookDown != "" && widget.config.useCustomizedLabel) {
        customizedSteps.add(LivenessDetectionStepItem(
          step: LivenessDetectionStep.lookDown,
          title: label.lookDown ?? "Look Down",
        ));
      }

      if (label.smile != "" && widget.config.useCustomizedLabel) {
        customizedSteps.add(LivenessDetectionStepItem(
          step: LivenessDetectionStep.smile,
          title: label.smile ?? "Smile",
        ));
      }

      if (label.lookStraight != "" && widget.config.useCustomizedLabel) {
        customizedSteps.add(LivenessDetectionStepItem(
          step: LivenessDetectionStep.lookStraight,
          title: label.lookStraight ?? "Look Straight",
        ));
      }

    return customizedSteps;
  }

  @override
  void initState() {
    _preInitCallBack();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _postFrameCallBack());
  }

  @override
  void dispose() {
    _timerToDetectFace?.cancel();
    _timerToDetectFace = null;
    _cameraController?.dispose();

    shuffleListLivenessChallenge(
        list: widget.config.useCustomizedLabel &&
            widget.config.customizedLabel != null
            ? customizedLivenessLabel(widget.config.customizedLabel!)
            : stepLiveness,
        isSmileLast: widget.config.useCustomizedLabel
            ? false
            : widget.shuffleListWithSmileLast);
    if (widget.config.isEnableMaxBrightness) {
      resetApplicationBrightness();
    }
    super.dispose();
  }

  void _preInitCallBack() {
    shuffleListLivenessChallenge(
        list: widget.config.useCustomizedLabel &&
            widget.config.customizedLabel != null
            ? customizedLivenessLabel(widget.config.customizedLabel!)
            : stepLiveness,
        isSmileLast: widget.config.useCustomizedLabel
            ? false
            : widget.shuffleListWithSmileLast);
    if (widget.config.isEnableMaxBrightness) {
      setApplicationBrightness(1.0);
    }
  }

  void _postFrameCallBack() async {
    availableCams = await availableCameras();
    if (availableCams.any((element) =>
    element.lensDirection == CameraLensDirection.front &&
        element.sensorOrientation == 90)) {
      _cameraIndex = availableCams.indexOf(
        availableCams.firstWhere((element) =>
        element.lensDirection == CameraLensDirection.front &&
            element.sensorOrientation == 90),
      );
    } else {
      _cameraIndex = availableCams.indexOf(
        availableCams.firstWhere(
                (element) =>
            element.lensDirection == CameraLensDirection.front),
      );
    }
    _startLiveFeed();

    shuffleListLivenessChallenge(
        list: widget.config.useCustomizedLabel &&
            widget.config.customizedLabel != null
            ? customizedLivenessLabel(widget.config.customizedLabel!)
            : stepLiveness,
        isSmileLast: widget.shuffleListWithSmileLast);
  }

  void _startLiveFeed() async {
    final camera = availableCams[_cameraIndex];
    _cameraController =
        CameraController(camera, ResolutionPreset.high, enableAudio: false);

    _cameraController?.initialize().then((_) {
      if (!mounted) return;
      _cameraController?.startImageStream(_processCameraImage);
      setState(() {});
    });
    _startFaceDetectionTimer();
  }

  void _startFaceDetectionTimer() {
    _timerToDetectFace = Timer(
        Duration(seconds: widget.config.durationLivenessVerify ?? 45),
            () => widget.onDetectionCompleted.call(null));
  }

  Future<void> _processCameraImage(CameraImage cameraImage) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in cameraImage.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes
        .done()
        .buffer
        .asUint8List();

    final Size imageSize = Size(
      cameraImage.width.toDouble(),
      cameraImage.height.toDouble(),
    );

    final camera = availableCams[_cameraIndex];
    final imageRotation =
    InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (imageRotation == null) return;

    final inputImageFormat =
    InputImageFormatValue.fromRawValue(cameraImage.format.raw);
    if (inputImageFormat == null) return;

    final inputImageData = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: cameraImage.planes[0].bytesPerRow,
    );

    final inputImage = InputImage.fromBytes(
      metadata: inputImageData,
      bytes: bytes,
    );

    _processImage(inputImage);
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (_isBusy) return;
    _isBusy = true;

    final faces =
    await MachineLearningKitHelper.instance.processInputImage(inputImage);

    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      if (faces.isEmpty) {
        _resetSteps();
        if (mounted) setState(() => _faceDetectedState = false);
      } else {
        if (mounted) setState(() => _faceDetectedState = true);
        final currentIndex = _stepsKey.currentState?.currentIndex ?? 0;
        if (widget.config.useCustomizedLabel) {
          if (currentIndex <
              customizedLivenessLabel(widget.config.customizedLabel!).length) {
            _detectFace(
              face: faces.first,
              step: customizedLivenessLabel(
                  widget.config.customizedLabel!)[currentIndex]
                  .step,
            );
          }
        } else {
          if (currentIndex < stepLiveness.length) {
            _detectFace(
              face: faces.first,
              step: stepLiveness[currentIndex].step,
            );
          }
        }
      }
    } else {
      _resetSteps();
    }

    _isBusy = false;
    if (mounted) setState(() {});
  }

  void _detectFace({
    required Face face,
    required LivenessDetectionStep step,
  }) async {
    if (_isProcessingStep) return;

    switch (step) {
      case LivenessDetectionStep.blink:
        await _handlingBlinkStep(face: face, step: step);
        break;

      case LivenessDetectionStep.lookRight:
        await _handlingTurnRight(face: face, step: step);
        break;

      case LivenessDetectionStep.lookLeft:
        await _handlingTurnLeft(face: face, step: step);
        break;

      case LivenessDetectionStep.lookUp:
        await _handlingLookUp(face: face, step: step);
        break;

      case LivenessDetectionStep.lookDown:
        await _handlingLookDown(face: face, step: step);
        break;

      case LivenessDetectionStep.smile:
        await _handlingSmile(face: face, step: step);
        break;

      case LivenessDetectionStep.lookStraight:
        await _handlingLookStraight(face: face, step: step);
        break;
    }
  }

  Future<void> _completeStep({required LivenessDetectionStep step}) async {
    if (mounted) setState(() {});
    await _stepsKey.currentState?.nextPage();
    _stopProcessing();
  }

  void _takePicture() async {
    try {
      if (_cameraController == null || _isTakingPicture) return;

      if (mounted) setState(() => _isTakingPicture = true);
      await _cameraController?.stopImageStream();

      final XFile? clickedImage = await _cameraController?.takePicture();
      if (clickedImage == null) {
        _startLiveFeed();
        return;
      }
      // _onDetectionCompleted(imgToReturn: clickedImage);
      widget.onDetectionCompleted.call(clickedImage.path);
    } catch (e) {
      _startLiveFeed();
    }
  }

  void _onDetectionCompleted({XFile? imgToReturn}) {
    final String? imgPath = imgToReturn?.path;
    if (widget.isEnableSnackBar) {
      final snackBar = SnackBar(
        content: Text(imgToReturn == null
            ? 'Verification of liveness detection failed, please try again. (Exceeds time limit ${widget
            .config.durationLivenessVerify ?? 45} second.)'
            : 'Verification of liveness detection success!'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
    Navigator.of(context).pop(imgPath);
  }

  void _resetSteps() {
    if (widget.config.useCustomizedLabel) {
      for (var step
      in customizedLivenessLabel(widget.config.customizedLabel!)) {
        final index = customizedLivenessLabel(widget.config.customizedLabel!)
            .indexWhere((p1) => p1.step == step.step);
        customizedLivenessLabel(widget.config.customizedLabel!)[index] =
            customizedLivenessLabel(widget.config.customizedLabel!)[index]
                .copyWith();
      }
      if (_stepsKey.currentState?.currentIndex != 0) {
        _stepsKey.currentState?.reset();
      }
      if (mounted) setState(() {});
    } else {
      for (var step in stepLiveness) {
        final index = stepLiveness.indexWhere((p1) => p1.step == step.step);
        stepLiveness[index] = stepLiveness[index].copyWith();
      }
      if (_stepsKey.currentState?.currentIndex != 0) {
        _stepsKey.currentState?.reset();
      }
      if (mounted) setState(() {});
    }
  }

  void _startProcessing() {
    if (!mounted) return;
    if (mounted) setState(() => _isProcessingStep = true);
  }

  void _stopProcessing() {
    if (!mounted) return;
    if (mounted) setState(() => _isProcessingStep = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
      body:_buildDetectionBody(),
    );
  }

  Widget _buildDetectionBody() {
    if (_cameraController == null ||
        _cameraController?.value.isInitialized == false) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    final double cameraAspectRatio = _cameraController!.value.aspectRatio;

    debugPrint("cameraAspectRatio $cameraAspectRatio");
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: LivenessDetectionStepOverlayWidget(
            duration: widget.config.durationLivenessVerify,
            showDurationUiText: widget.config.showDurationUiText,
            isDarkMode: widget.isDarkMode,
            isFaceDetected: _faceDetectedState,
            aspectHeight: 300 * cameraAspectRatio,
            camera: CameraPreview(_cameraController!),
            key: _stepsKey,
            activeStepColor: widget.config.activeStepColor,
            inActiveStepColor: widget.config.inActiveStepColor,
            steps: widget.config.useCustomizedLabel
                ? customizedLivenessLabel(widget.config.customizedLabel!)
                : stepLiveness,
            showCurrentStep: widget.showCurrentStep,
            title: widget.title,
            onCompleted: () =>
                Future.delayed(
                  const Duration(milliseconds: 500),
                      () => _takePicture(),
                ),
          ),
        ),
        // _buildCameraControls(),
      ],
    )
    ;
  }

  Widget _buildCameraControls() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              Icons.flash_on,
              color: Colors.white,
            ),
            onPressed: () async {},
          ),
          GestureDetector(
            onTap: () => {},
            child: Icon(
              Icons.radio_button_on,
              color: Colors.red,
              size: 70,
            ),
          ),
          const Icon(Icons.flip_camera_ios, color: Colors.green)
        ],
      ),
    );
  }


  Future<void> _handlingBlinkStep({
    required Face face,
    required LivenessDetectionStep step,
  }) async {
    final blinkThreshold = FlutterLivenessDetectionRandomizedPlugin
        .instance.thresholdConfig
        .firstWhereOrNull((p0) => p0 is LivenessThresholdBlink)
    as LivenessThresholdBlink?;

    if ((face.leftEyeOpenProbability ?? 1.0) <
        (blinkThreshold?.leftEyeProbability ?? 0.25) &&
        (face.rightEyeOpenProbability ?? 1.0) <
            (blinkThreshold?.rightEyeProbability ?? 0.25)) {
      _startProcessing();
      await _completeStep(step: step);
    }
  }

  Future<void> _handlingTurnRight({
    required Face face,
    required LivenessDetectionStep step,
  }) async {
    if (Platform.isAndroid) {
      final headTurnThreshold = FlutterLivenessDetectionRandomizedPlugin
          .instance.thresholdConfig
          .firstWhereOrNull((p0) => p0 is LivenessThresholdHead)
      as LivenessThresholdHead?;
      if ((face.headEulerAngleY ?? 0) <
          (headTurnThreshold?.rotationAngle ?? -30)) {
        _startProcessing();
        await _completeStep(step: step);
      }
    } else if (Platform.isIOS) {
      final headTurnThreshold = FlutterLivenessDetectionRandomizedPlugin
          .instance.thresholdConfig
          .firstWhereOrNull((p0) => p0 is LivenessThresholdHead)
      as LivenessThresholdHead?;
      if ((face.headEulerAngleY ?? 0) >
          (headTurnThreshold?.rotationAngle ?? 30)) {
        _startProcessing();
        await _completeStep(step: step);
      }
    }
  }

  Future<void> _handlingTurnLeft({
    required Face face,
    required LivenessDetectionStep step,
  }) async {
    if (Platform.isAndroid) {
      final headTurnThreshold = FlutterLivenessDetectionRandomizedPlugin
          .instance.thresholdConfig
          .firstWhereOrNull((p0) => p0 is LivenessThresholdHead)
      as LivenessThresholdHead?;
      if ((face.headEulerAngleY ?? 0) >
          (headTurnThreshold?.rotationAngle ?? 30)) {
        _startProcessing();
        await _completeStep(step: step);
      }
    } else if (Platform.isIOS) {
      final headTurnThreshold = FlutterLivenessDetectionRandomizedPlugin
          .instance.thresholdConfig
          .firstWhereOrNull((p0) => p0 is LivenessThresholdHead)
      as LivenessThresholdHead?;
      if ((face.headEulerAngleY ?? 0) <
          (headTurnThreshold?.rotationAngle ?? -30)) {
        _startProcessing();
        await _completeStep(step: step);
      }
    }
  }

  Future<void> _handlingLookUp({
    required Face face,
    required LivenessDetectionStep step,
  }) async {
    final headTurnThreshold = FlutterLivenessDetectionRandomizedPlugin
        .instance.thresholdConfig
        .firstWhereOrNull((p0) => p0 is LivenessThresholdHead)
    as LivenessThresholdHead?;
    if ((face.headEulerAngleX ?? 0) >
        (headTurnThreshold?.rotationAngle ?? 20)) {
      _startProcessing();
      await _completeStep(step: step);
    }
  }

  Future<void> _handlingLookDown({
    required Face face,
    required LivenessDetectionStep step,
  }) async {
    final headTurnThreshold = FlutterLivenessDetectionRandomizedPlugin
        .instance.thresholdConfig
        .firstWhereOrNull((p0) => p0 is LivenessThresholdHead)
    as LivenessThresholdHead?;
    if ((face.headEulerAngleX ?? 0) <
        (headTurnThreshold?.rotationAngle ?? -15)) {
      _startProcessing();
      await _completeStep(step: step);
    }
  }

  Future<void> _handlingSmile({
    required Face face,
    required LivenessDetectionStep step,
  }) async {
    final smileThreshold = FlutterLivenessDetectionRandomizedPlugin
        .instance.thresholdConfig
        .firstWhereOrNull((p0) => p0 is LivenessThresholdSmile)
    as LivenessThresholdSmile?;

    if ((face.smilingProbability ?? 0) >
        (smileThreshold?.probability ?? 0.65)) {
      _startProcessing();
      await _completeStep(step: step);
    }
  }

  Future<void> _handlingLookStraight({
    required Face face,
    required LivenessDetectionStep step,
  }) async {
    final straightThreshold = FlutterLivenessDetectionRandomizedPlugin
        .instance.thresholdConfig
        .firstWhereOrNull((p0) => p0 is LivenessThresholdStraight)
    as LivenessThresholdStraight?;

    final angleY = face.headEulerAngleY ?? 0.0; // yaw (side)
    final angleX = face.headEulerAngleX ?? 0.0; // pitch (up/down)

    if (angleY.abs() < (straightThreshold?.maxYaw ?? 10.0) &&
        angleX.abs() < (straightThreshold?.maxPitch ?? 10.0)) {
      _startProcessing();
      _completeStep(step: step);
    }
  }


  Future<bool> onSteadyFaceDetected(XFile clickedImage) async {
    // Convert the clicked image to InputImage for face detection
    final inputImage = InputImage.fromFile(File(clickedImage.path));

    // Create a face detector with options
    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate,
        enableClassification: true, // ← VERY IMPORTANT!
        enableLandmarks: true,      // Optional but helpful
      ),
    );

    // Process the image and detect faces
    final List<Face> faces = await faceDetector.processImage(inputImage);
    if (faces.isEmpty) {
      print("No face detected.");
      return false; // No face detected, return false
    }

    // Get the first face from the list of detected faces
    final face = faces.first;
    final boundingBox = face.boundingBox;

    // Check if the face is visible and steady
    final isCheckHeadSteady = checkIsHeadSteady(face); // Use your logic here

    if (!isCheckHeadSteady) {
      print("Face is not visible or head is not steady.");
      return false; // Either the face is not visible or head is not steady
    }

    print("Face is steady and visible.");
    return true; // Face is steady and visible, return true
  }

  bool checkIsHeadSteady(Face face) {
    const maxYaw = 10.0;  // left/right
    const maxRoll = 10.0; // tilt
    return (face.headEulerAngleY?.abs()??0) < maxYaw &&
        (face.headEulerAngleZ?.abs()??0) < maxRoll;
  }

}
