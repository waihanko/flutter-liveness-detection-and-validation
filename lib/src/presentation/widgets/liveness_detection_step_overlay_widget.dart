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

  const LivenessDetectionStepOverlayWidget({super.key,
    required this.steps,
    required this.onCompleted,
    required this.aspectHeight,
    required this.camera,
    required this.isFaceDetected,
    this.showCurrentStep = false,
    this.isDarkMode = true,
    this.showDurationUiText = false,
    this.duration});

  @override
  State<LivenessDetectionStepOverlayWidget> createState() =>
      LivenessDetectionStepOverlayWidgetState();
}

class LivenessDetectionStepOverlayWidgetState
    extends State<LivenessDetectionStepOverlayWidget> {
  int get currentIndex => _currentIndex;

  bool _isLoading = false;
  int _currentIndex = 0;
  double _currentStepIndicator = 0;
  late final PageController _pageController;
  late Widget _circularProgressWidget;

  // Add timer and remaining duration variables
  Timer? _countdownTimer;
  int _remainingDuration = 0;

  static const double _indicatorMaxStep = 100;
  static const double _heightLine = 25;

  double _getStepIncrement(int stepLength) {
    return 100 / stepLength;
  }

  String get stepCounter => "$_currentIndex/${widget.steps.length}";

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeTimer();
    debugPrint('showCurrentStep ${widget.showCurrentStep}');
  }

  void _initializeControllers() {
    _pageController = PageController(initialPage: 0);
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
      unselectedColor: Colors.grey,
      selectedColor: Colors.green,
      heightLine: _heightLine,
      current: _currentStepIndicator,
      maxStep: _indicatorMaxStep,
      child: widget.camera,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> nextPage() async {
    if (_isLoading) return;

    if (_currentIndex + 1 <= widget.steps.length - 1) {
      await _handleNextStep();
    } else {
      await _handleCompletion();
    }
  }

  Future<void> _handleNextStep() async {
    _showLoader();
    await Future.delayed(const Duration(milliseconds: 100));
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 1),
      curve: Curves.easeIn,
    );
    await Future.delayed(const Duration(seconds: 1));
    _hideLoader();
    _updateState();
  }

  Future<void> _handleCompletion() async {
    _updateState();
    await Future.delayed(const Duration(milliseconds: 500));
    widget.onCompleted();
  }

  void _updateState() {
    if (mounted) {
      setState(() {
        _currentIndex++;
        _currentStepIndicator += _getStepIncrement(widget.steps.length);
        _circularProgressWidget = _buildCircularIndicator();
      });
    }
  }

  void reset() {
    _pageController.jumpToPage(0);
    if (mounted) {
      setState(() {
        _currentIndex = 0;
        _currentStepIndicator = 0;
        _circularProgressWidget = _buildCircularIndicator();
      });
    }
  }

  void _showLoader() {
    if (mounted) setState(() => _isLoading = true);
  }

  void _hideLoader() {
    if (mounted) setState(() => _isLoading = false);
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
        SizedBox(height: 12,),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Face verification",
              style:
              TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black,
                  fontSize: 22,
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
                  stepCounter,
                  style: TextStyle(
                      color: widget.isDarkMode
                          ? Colors.white
                          : Colors.black),
                ),
              ],
            )

          ],
        ),
        SizedBox(height: 48,),
        _buildCircularCamera(),
        SizedBox(height: 48,),
        Text(
          "Scan your face",
          style:
          TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12,),
        _buildFaceDetectionStatus(),
        const SizedBox(height: 16),
        widget.isDarkMode ? _buildLoaderDarkMode() : _buildLoaderLightMode(),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text("Cancel", style: TextStyle(
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
    print(widget.aspectHeight);
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
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.steps.length,
            itemBuilder: _buildStepItem,
          ),
        )
      ],
    );
  }


  Widget _buildStepItem(BuildContext context, int index) {
    return Text(
      widget.steps[index].title,
      textAlign: TextAlign.center,
        style:
        TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildLoaderDarkMode() {
    return Center(
      child: CupertinoActivityIndicator(
        color: !_isLoading ? Colors.transparent : Colors.white,
      ),
    );
  }

  Widget _buildLoaderLightMode() {
    return Center(
      child: CupertinoActivityIndicator(
        color: _isLoading ? Colors.transparent : Colors.white,
      ),
    );
  }
}

class _CenterClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    double clipHeight = 533.3333333333333;
    double top = (size.height - clipHeight) / 2;
    return Rect.fromLTWH(0, top, size.width, clipHeight);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
}