import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_liveness_detection_randomized_plugin_example/refrector/step_generator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'extension.dart';
import 'face_detector_ui.dart'; // Import the new UI file


class FaceLivenessScanScreen extends StatefulWidget {
  const FaceLivenessScanScreen({super.key});

  @override
  State<FaceLivenessScanScreen> createState() => _FaceLivenessScanScreenState();
}

class _FaceLivenessScanScreenState extends State<FaceLivenessScanScreen> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true, // <== Enables smiling and eye open probabilities
      enableTracking: true,
      enableContours: true,
      enableLandmarks: true,
    ),
  );
  bool _canProcess = true;
  bool _isBusy = false;
  bool _isFaceDetected = false;
  bool _isTakingPicture = false;
  CustomPaint? _customPaint;
  List<LivenessDetectionStep> challengeActions = [];
  int currentChallengeIndex = 0;
  CameraController? _controller;
  Timer? _countdownTimer;
  static List<CameraDescription> _cameras = [];
  int _cameraIndex = -1;
  int _remainingDuration = 25; //25 Second;
  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void initState() {
    challengeActions = StepGenerator.getRandomLivenessSteps();

    _initializeTimer();
    _initialize();
    super.initState();
  }

  // New method to find the front camera index
  Future<int?> _findFrontCameraIndex() async {
    if (_cameras.isEmpty) {
      _cameras = await availableCameras();
    }
    for (var i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == CameraLensDirection.front) {
        return i;
      }
    }
    return null; // Return null if no front camera is found
  }

  // New method to calculate image rotation
  InputImageRotation? _getCameraImageRotation({
    required CameraDescription camera,
    required DeviceOrientation deviceOrientation,
    required int sensorOrientation,
  }) {
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation = _orientations[deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    return rotation;
  }

  void _initializeTimer() {
    _startCountdownTimer();
  }

  void _initialize() async {
    final index = await _findFrontCameraIndex();
    if (index != null) {
      try {
        _cameraIndex = index;
        _startLiveFeed();
      } catch (e) {
        print("Error starting live feed: $e");
        // Handle error, maybe show a message to the user
      }
    } else {
      // Handle case where no front camera is found, e.g., show an error message
      print("Error: No front camera found."); // Added a print statement for now
    }
  }

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _liveFeedBody());
  }

  Future _startLiveFeed() async {
    final camera = _cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      // Set to ResolutionPreset.high. Do NOT set it to ResolutionPreset.max because for some phones does NOT work.
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    try {
      await _controller?.initialize();
      if (!mounted) {
        return;
      }

      _controller?.startImageStream(_processCameraImage).then((value) {
        //Camera Ready
      });
      setState(() {});
    } catch (e) {
      print("Error initializing camera or starting image stream: $e");
      // Handle error, maybe show a message to the user
    }
  }

  void _processCameraImage(CameraImage image) {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;
    _processImage(inputImage);
  }

  Widget _liveFeedBody() {
    if (_cameras.isEmpty) return Container();
    if (_controller == null) return Container();
    if (_controller?.value.isInitialized == false) return Container();

    return buildFaceDetectorLiveFeedBody(
      context: context,
      controller: _controller!,
      isTakingPicture: _isTakingPicture,
      isFaceDetected: _isFaceDetected,
      customPaint: _customPaint,
      challengeActions: challengeActions,
      currentChallengeIndex: currentChallengeIndex,
      remainingDuration: _remainingDuration,
    );
  }

  void _takePicture(CameraController? controller) async {
    try {
      if (controller == null) return;

      if (mounted) setState(() => _isTakingPicture = true);

      final XFile? clickedImage = await controller.takePicture();
      await controller.stopImageStream();

      if (clickedImage == null) {
        _startLiveFeed();
        return;
      }

      final isFaceDetectedOnCaptureImage =
      await _checkIsFaceDetected(File(clickedImage.path));
      if (mounted) setState(() => _isTakingPicture = false);
      if(isFaceDetectedOnCaptureImage == false){
        _isFaceDetected = false;
        currentChallengeIndex = 0;
        _startLiveFeed();
      }else{
        print("Path is captured ${clickedImage.path}");
        Navigator.of(context).pop(clickedImage.path);
      }
    } catch (e) {
      _startLiveFeed();
    }
  }

  Future<bool> _checkIsFaceDetected(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
      );

      final List<Face> faces = await faceDetector.processImage(inputImage);
      if (faces.isNotEmpty) return true;
      return false;
    } catch (e) {
      print("Error checking face on captured image: $e");
      return false; // Assume no face detected on error
    }
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;

    try {
      final faces = await _faceDetector.processImage(inputImage);
      //_customPaint => To Apply Land Marks On Face
      // if (inputImage.metadata?.size != null &&
      //     inputImage.metadata?.rotation != null) {
      //   final painter = FaceDetectorPainter(
      //     faces,
      //     inputImage.metadata!.size,
      //     inputImage.metadata!.rotation,
      //     _cameraLensDirection,
      //   );
      //   _customPaint = CustomPaint(painter: painter);
      // }

      if(faces.isEmpty){
        _isFaceDetected = false;
        currentChallengeIndex = 0;
      }else{
        _isFaceDetected = true;
        checkChallenge(faces.first);
      }
    } catch (e) {
      print("Error processing image: $e");
      _isFaceDetected = false; // Assume no face detected on error
      currentChallengeIndex = 0;
    } finally {
      _isBusy = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingDuration > 0) {
        setState(() {
          _remainingDuration--;
        });
      } else {
        Navigator.of(context).pop(); //Timer Complete Here
        _countdownTimer?.cancel();
      }
    });
  }


// Check if the face is performing the current challenge action
  void checkChallenge(Face face) async {
    if (currentChallengeIndex >= challengeActions.length) {
      return;
    }

    final currentAction = challengeActions[currentChallengeIndex];
    bool actionCompleted = false;

    switch (currentAction) {
      case LivenessDetectionStep.smile:
        actionCompleted = face.smilingProbability != null &&
            face.smilingProbability! > 0.5;
        break;
      case LivenessDetectionStep.blink:
        actionCompleted = (face.leftEyeOpenProbability != null &&
            face.leftEyeOpenProbability! < 0.3) ||
            (face.rightEyeOpenProbability != null &&
                face.rightEyeOpenProbability! < 0.3);
        break;
      case LivenessDetectionStep.lookRight:
        actionCompleted = face.headEulerAngleY != null &&
            face.headEulerAngleY! < -10;
        break;
      case LivenessDetectionStep.lookLeft:
        actionCompleted = face.headEulerAngleY != null &&
            face.headEulerAngleY! > 10;
        break;
      case LivenessDetectionStep.lookUp:
        actionCompleted = face.headEulerAngleX != null &&
            face.headEulerAngleX! > 20;
        break;
      case LivenessDetectionStep.lookDown:
        actionCompleted = face.headEulerAngleX != null &&
            face.headEulerAngleX! < -10;
        break;
    }

    if (actionCompleted) {
      currentChallengeIndex++;
      if (currentChallengeIndex >= challengeActions.length) {
        Future.delayed(const Duration(seconds: 2), () {
          _takePicture(_controller);
        });
      }
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    final camera = _cameras[_cameraIndex];
    final sensorOrientation = camera.sensorOrientation;
    final deviceOrientation = _controller!.value.deviceOrientation; // Get device orientation

    final rotation = _getCameraImageRotation(
      camera: camera,
      deviceOrientation: deviceOrientation,
      sensorOrientation: sensorOrientation,
    );

    if (rotation == null) return null;

    // get image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    // validate format depending on platform
    // only supported formats:
    // * nv21 for Android
    // * bgra8888 for iOS
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    // since format is constraint to nv21 or bgra8888, both only have one plane
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    // compose InputImage using bytes
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }

}
