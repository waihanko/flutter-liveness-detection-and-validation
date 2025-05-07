import 'package:flutter/cupertino.dart';
import 'package:flutter_liveness_detection_randomized_plugin/index.dart';
import 'package:flutter_liveness_detection_randomized_plugin/src/presentation/widgets/circular_progress_widget/circular_progress_widget.dart';

class LivenessDetectionStepOverlayWidget extends StatefulWidget {
  final List<LivenessDetectionStepItem> steps;
  final VoidCallback onCompleted;
  final Widget camera;
  final double aspectHeight;
  final bool isFaceDetected;
  final bool showCurrentStep;
  final bool isDarkMode;
  final bool showDurationUiText;
  final int? duration;
  final Color? inActiveStepColor;
  final Color? activeStepColor;
  final String? title;

  const LivenessDetectionStepOverlayWidget({super.key,
    required this.steps,
    required this.onCompleted,
    required this.aspectHeight,
    required this.camera,
    required this.isFaceDetected,
    this.showCurrentStep = false,
    this.isDarkMode = true,
    this.showDurationUiText = false,
    this.activeStepColor,
    this.inActiveStepColor,
    this.duration,
    this.title
  });

  @override
  State<LivenessDetectionStepOverlayWidget> createState() =>
      LivenessDetectionStepOverlayWidgetState();
}

class LivenessDetectionStepOverlayWidgetState
    extends State<LivenessDetectionStepOverlayWidget> {
  int get currentIndex => _currentIndex;

  int _currentIndex = 0;
  double _currentStepIndicator = 0;
  late Widget _circularProgressWidget;

  // Add timer and remaining duration variables
  Timer? _countdownTimer;
  int _remainingDuration = 0;

  static const double _indicatorMaxStep = 100;
  static const double _heightLine = 25;

  double _getStepIncrement(int stepLength) {
    return 100 / stepLength;
  }


  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeTimer();
  }

  void _initializeControllers() {
    _circularProgressWidget = _buildCircularIndicator();
  }

  void _initializeTimer() {
    if (widget.duration != null && widget.showDurationUiText) {
      _remainingDuration = widget.duration!;
      _startCountdownTimer();
    }
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingDuration > 0) {
        setState(() {
          _remainingDuration--;
        });
      } else {
        _countdownTimer?.cancel();
      }
    });
  }

  Widget _buildCircularIndicator() {
    return CircularProgressWidget(
      inActiveStepColor: widget.inActiveStepColor?? Colors.grey,
      activeStepColor: widget.activeStepColor?? Colors.green,
      heightLine: _heightLine,
      current: _currentStepIndicator,
      maxStep: _indicatorMaxStep,
      child: widget.camera,
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> nextPage() async {
    if (_currentIndex + 1 <= widget.steps.length - 1) {
      await _handleNextStep();
    } else {
      await _handleCompletion();
    }
  }

  Future<void> _handleNextStep() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _updateState();
  }

  Future<void> _handleCompletion() async {
    _updateState();
    widget.onCompleted();
  }

  void _updateState() {
    if (mounted) {
      setState(() {
        if (_currentIndex < widget.steps.length - 1) {
                 _currentIndex++;
        }
        _currentStepIndicator += _getStepIncrement(widget.steps.length);
        _circularProgressWidget = _buildCircularIndicator();
      });
    }
  }

  void reset() {
    if (mounted) {
      setState(() {
        _currentIndex = 0;
        _currentStepIndicator = 0;
        _circularProgressWidget = _buildCircularIndicator();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.all(16),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        const SizedBox(height: 12,),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title?? "Face verification",
              style:
              TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Visibility(
                  replacement: const SizedBox.shrink(),
                  visible: widget.showDurationUiText,
                  child: Text(
                    _getRemainingTimeText(_remainingDuration),
                    style: TextStyle(
                      color: widget.isDarkMode
                          ? Colors.white
                          : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if(widget.showCurrentStep) Text(
                  "${_currentIndex+1}/${widget.steps.length}",
                  style: TextStyle(
                      color: widget.isDarkMode
                          ? Colors.white
                          : Colors.black),
                ),
              ],
            )

          ],
        ),
        const SizedBox(height: 48,),
        _buildCircularCamera(),
        const SizedBox(height: 48,),
        Text(
          "Scan your face",
          style:
          TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12,),
        _buildFaceDetectionStatus(),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Cancel", style: TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.w600,
              fontSize: 18
            ),),
          ),
        )
      ],
    );
  }

  Widget _buildCircularCamera() {
    return ClipRect(
      child: Align(
        alignment: Alignment.center,
        heightFactor: 300 / widget.aspectHeight,
        // Show 30% vertically (adjust as needed)
        child: SizedBox(
          height: widget.aspectHeight,
          width: 300,
          child: _circularProgressWidget,
        ),
      ),
    );
  }

  String _getRemainingTimeText(int duration) {
    int minutes = duration ~/ 60;
    int seconds = duration % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(
        2, '0')}";
  }

  Widget _buildFaceDetectionStatus() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if(!widget.isFaceDetected)
          SizedBox(
            height: MediaQuery
                .of(context)
                .size
                .height / 10,
            width: MediaQuery
                .of(context)
                .size
                .width,
            child: Align(
              alignment: Alignment.topCenter,
              child:  Text(
                'Place your face in frame',
                style:
                TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black,fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
          ),


        if(widget.isFaceDetected) SizedBox(
          height: MediaQuery
              .of(context)
              .size
              .height / 10,
          width: MediaQuery
              .of(context)
              .size
              .width,
          child: Text(
            widget.steps[_currentIndex].title,
            key: ValueKey('step_$_currentIndex'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w500),
          ),
        )
      ],
    );
  }


}

