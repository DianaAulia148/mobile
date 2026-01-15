import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class CameraScreen extends StatefulWidget {
  final String workoutId;
  final String workoutName;
  final String exerciseType;
  final int goalReps;

  const CameraScreen({
    super.key,
    required this.workoutId,
    required this.workoutName,
    required this.exerciseType,
    this.goalReps = 10,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

enum MotionPhase { up, down }

class _CameraScreenState extends State<CameraScreen> {
  // =============================
  // CAMERA & AI
  // =============================
  late CameraController _camera;
  late Interpreter _interpreter;
  late PoseDetector _poseDetector;

  bool _isCameraReady = false;
  bool _isRunning = false;

  // =============================
  // CONFIG (SAMA DENGAN PYTHON)
  // =============================
  static const int TIMESTEPS = 20;
  static const int FEATURES = 103;

  static const double CONFIDENCE_THRESHOLD = 0.75;
  static const double DOWN_THRESHOLD = 0.62;
  static const double UP_THRESHOLD = 0.78;
  static const int MIN_DOWN_FRAMES = 2;

  // =============================
  // STATE
  // =============================
  List<List<double>> sequenceBuffer = [];
  int reps = 0;
  int downFrames = 0;
  MotionPhase phase = MotionPhase.up;

  bool validMotion = false;
  String feedback = "Tekan START";

  // =============================
  // LANDMARK ORDER (WAJIB STABIL)
  // =============================
  static const landmarkOrder = [
    PoseLandmarkType.nose,
    PoseLandmarkType.leftEyeInner,
    PoseLandmarkType.leftEye,
    PoseLandmarkType.leftEyeOuter,
    PoseLandmarkType.rightEyeInner,
    PoseLandmarkType.rightEye,
    PoseLandmarkType.rightEyeOuter,
    PoseLandmarkType.leftEar,
    PoseLandmarkType.rightEar,
    PoseLandmarkType.leftMouth,
    PoseLandmarkType.rightMouth,
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftElbow,
    PoseLandmarkType.rightElbow,
    PoseLandmarkType.leftWrist,
    PoseLandmarkType.rightWrist,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
    PoseLandmarkType.leftKnee,
    PoseLandmarkType.rightKnee,
    PoseLandmarkType.leftAnkle,
    PoseLandmarkType.rightAnkle,
    PoseLandmarkType.leftHeel,
    PoseLandmarkType.rightHeel,
    PoseLandmarkType.leftFootIndex,
    PoseLandmarkType.rightFootIndex,
  ];

  // =============================
  // MODEL PATH
  // =============================
  String get _modelPath {
    switch (widget.exerciseType) {
      case 'squat':
        return 'models/squat_model.tflite';
      case 'shoulder_press':
        return 'models/shoulder_press_model.tflite';
      default:
        return 'models/pushup_model.tflite';
    }
  }

  // =============================
  // INIT
  // =============================
  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    final cameras = await availableCameras();
    final cam = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _camera = CameraController(cam, ResolutionPreset.medium, enableAudio: false);
    await _camera.initialize();

    _interpreter = await Interpreter.fromAsset(_modelPath);

    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
    );

    await _camera.startImageStream(_processCameraImage);

    setState(() => _isCameraReady = true);
  }

  // =============================
  // CAMERA PROCESS
  // =============================
  Future<void> _processCameraImage(CameraImage image) async {
    if (!_isRunning) return;

    final inputImage = _convertToInputImage(image);
    final poses = await _poseDetector.processImage(inputImage);

    if (poses.isEmpty) return;

    final pose = poses.first;
    final features = _extractFeatures(pose);
    if (features.length != FEATURES) return;

    _addFrame(features);

    if (sequenceBuffer.length == TIMESTEPS) {
      final confidence = _predict();

      if (confidence >= CONFIDENCE_THRESHOLD) {
        validMotion = true;
        _repEngine(pose);
      } else {
        validMotion = false;
        phase = MotionPhase.up;
        downFrames = 0;
      }

      _updateFeedback();
      if (mounted) setState(() {});
    }
  }

  // =============================
  // FEATURE EXTRACTION
  // =============================
  List<double> _extractFeatures(Pose pose) {
    final lm = pose.landmarks;

    final hipL = lm[PoseLandmarkType.leftHip]!;
    final hipR = lm[PoseLandmarkType.rightHip]!;

    final cx = (hipL.x + hipR.x) / 2;
    final cy = (hipL.y + hipR.y) / 2;

    List<double> features = [];

    for (var t in landmarkOrder) {
      final p = lm[t];
      if (p == null) {
        features.addAll([0, 0, 0]);
      } else {
        features.add(p.x - cx);
        features.add(p.y - cy);
        features.add(p.z);
      }
    }

    features.add(_angle(lm[PoseLandmarkType.leftShoulder]!,
        lm[PoseLandmarkType.leftElbow]!, lm[PoseLandmarkType.leftWrist]!));
    features.add(_angle(lm[PoseLandmarkType.rightShoulder]!,
        lm[PoseLandmarkType.rightElbow]!, lm[PoseLandmarkType.rightWrist]!));
    features.add(_angle(lm[PoseLandmarkType.leftHip]!,
        lm[PoseLandmarkType.leftKnee]!, lm[PoseLandmarkType.leftAnkle]!));
    features.add(_angle(lm[PoseLandmarkType.rightHip]!,
        lm[PoseLandmarkType.rightKnee]!, lm[PoseLandmarkType.rightAnkle]!));

    return features;
  }

  double _angle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final ba = [a.x - b.x, a.y - b.y, a.z - b.z];
    final bc = [c.x - b.x, c.y - b.y, c.z - b.z];

    final dot = ba[0] * bc[0] + ba[1] * bc[1] + ba[2] * bc[2];
    final magA = sqrt(ba[0] * ba[0] + ba[1] * ba[1] + ba[2] * ba[2]);
    final magB = sqrt(bc[0] * bc[0] + bc[1] * bc[1] + bc[2] * bc[2]);

    return acos((dot / (magA * magB + 1e-6)).clamp(-1.0, 1.0)) / pi;
  }

  // =============================
  // SEQUENCE & PREDICT
  // =============================
  void _addFrame(List<double> f) {
    if (sequenceBuffer.length >= TIMESTEPS) {
      sequenceBuffer.removeAt(0);
    }
    sequenceBuffer.add(f);
  }

  double _predict() {
    final input = sequenceBuffer.expand((e) => e).toList().reshape([1, TIMESTEPS, FEATURES]);
    final output = List.filled(1, 0.0).reshape([1, 1]);
    _interpreter.run(input, output);
    return output[0][0];
  }

  // =============================
  // REP ENGINE (ADAPTIF)
  // =============================
  void _repEngine(Pose pose) {
    final lm = pose.landmarks;
    double angle;

    if (widget.exerciseType == 'squat') {
      angle = (_angle(lm[PoseLandmarkType.leftHip]!,
              lm[PoseLandmarkType.leftKnee]!, lm[PoseLandmarkType.leftAnkle]!) +
          _angle(lm[PoseLandmarkType.rightHip]!,
              lm[PoseLandmarkType.rightKnee]!, lm[PoseLandmarkType.rightAnkle]!)) / 2;
    } else {
      angle = (_angle(lm[PoseLandmarkType.leftShoulder]!,
              lm[PoseLandmarkType.leftElbow]!, lm[PoseLandmarkType.leftWrist]!) +
          _angle(lm[PoseLandmarkType.rightShoulder]!,
              lm[PoseLandmarkType.rightElbow]!, lm[PoseLandmarkType.rightWrist]!)) / 2;
    }

    if (angle < DOWN_THRESHOLD) {
      downFrames++;
      if (downFrames >= MIN_DOWN_FRAMES) phase = MotionPhase.down;
    } else if (angle > UP_THRESHOLD && phase == MotionPhase.down) {
      reps++;
      phase = MotionPhase.up;
      downFrames = 0;

      if (reps >= widget.goalReps && mounted) {
        _showCompletionDialog();
      }
    }
  }

  // =============================
  // FEEDBACK
  // =============================
  void _updateFeedback() {
    if (!validMotion) {
      feedback = "Bukan gerakan ${widget.workoutName}";
    } else {
      feedback = phase == MotionPhase.down ? "Turun perlahan" : "Dorong ke atas";
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Workout Selesai"),
        content: Text("Anda menyelesaikan ${widget.goalReps} repetisi ${widget.workoutName}"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  // =============================
  // IMAGE CONVERT
  // =============================
  InputImage _convertToInputImage(CameraImage image) {
    final buffer = WriteBuffer();
    for (var p in image.planes) {
      buffer.putUint8List(p.bytes);
    }

    return InputImage.fromBytes(
      bytes: buffer.done().buffer.asUint8List(),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.yuv420,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  // =============================
  // UI
  // =============================
  @override
  Widget build(BuildContext context) {
    if (!_isCameraReady) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(widget.workoutName)),
      body: Stack(
        children: [
          CameraPreview(_camera),
          Positioned(
            top: 20,
            left: 20,
            child: Text(
              "REPS: $reps / ${widget.goalReps}\n$feedback",
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () => setState(() => _isRunning = !_isRunning),
                child: Text(_isRunning ? "PAUSE" : "START"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _camera.dispose();
    _poseDetector.close();
    _interpreter.close();
    super.dispose();
  }
}
