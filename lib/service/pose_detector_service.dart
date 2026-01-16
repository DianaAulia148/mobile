import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseData {
  final Pose pose;
  final double leftKneeAngle;
  final double rightKneeAngle;
  
  PoseData({
    required this.pose,
    required this.leftKneeAngle,
    required this.rightKneeAngle,
  });
  
  double getLeftKneeAngle() => leftKneeAngle;
  double getRightKneeAngle() => rightKneeAngle;
  
  String getPostureFeedback() {
    if (leftKneeAngle < 160 && rightKneeAngle < 160) {
      return "Maintain straight back!";
    } else if (leftKneeAngle > 170 || rightKneeAngle > 170) {
      return "Good form!";
    }
    return "Keep going!";
  }
}

class PoseDetectorService {
  late PoseDetector _poseDetector;
  String? _exerciseType;
  
  // State untuk counting reps
  int repCount = 0;
  String? _currentPhase;
  double? _lastKneeAngle;
  
  // Thresholds untuk counting
  static const Map<String, Map<String, dynamic>> exerciseThresholds = {
    'pushup': {
      'lower_threshold': 100.0,
      'upper_threshold': 160.0,
      'confidence_threshold': 0.5,
    },
    'squat': {
      'lower_threshold': 90.0,
      'upper_threshold': 170.0,
      'confidence_threshold': 0.5,
    },
    'shoulder_press': {
      'lower_threshold': 100.0,
      'upper_threshold': 180.0,
      'confidence_threshold': 0.5,
    }
  };
  
  Future<void> initialize({required String exerciseType}) async {
    _exerciseType = exerciseType.toLowerCase();
    
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.single,
      model: PoseDetectionModel.accurate,
    );
    
    _poseDetector = PoseDetector(options: options);
    print("Pose detector initialized for $_exerciseType");
  }
  
  Future<PoseData?> detectPose(CameraImage image, CameraDescription camera) async {
    try {
      // Convert CameraImage ke InputImage
      final inputImage = _convertCameraImage(image, camera);
      
      // Deteksi pose
      final List<Pose> poses = await _poseDetector.processImage(inputImage);
      
      if (poses.isEmpty) {
        return null;
      }
      
      // Ambil pose pertama (single person)
      final pose = poses.first;
      
      // Hitung sudut lutut
      final leftKneeAngle = _calculateKneeAngle(
        pose.landmarks[PoseLandmarkType.leftHip],
        pose.landmarks[PoseLandmarkType.leftKnee],
        pose.landmarks[PoseLandmarkType.leftAnkle],
      );
      
      final rightKneeAngle = _calculateKneeAngle(
        pose.landmarks[PoseLandmarkType.rightHip],
        pose.landmarks[PoseLandmarkType.rightKnee],
        pose.landmarks[PoseLandmarkType.rightAnkle],
      );
      
      // Count reps berdasarkan exercise type
      _countReps(leftKneeAngle, rightKneeAngle);
      
      return PoseData(
        pose: pose,
        leftKneeAngle: leftKneeAngle,
        rightKneeAngle: rightKneeAngle,
      );
    } catch (e) {
      print("Error detecting pose: $e");
      return null;
    }
  }
  
  InputImage _convertCameraImage(CameraImage image, CameraDescription camera) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();
    
    final Size imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );
    
    final planeData = image.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();
    
    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: _getImageRotation(camera),
      inputImageFormat: InputImageFormat.nv21,
      planeData: planeData,
    );
    
    return InputImage.fromBytes(
      bytes: bytes,
      inputImageData: inputImageData,
    );
  }
  
  InputImageRotation _getImageRotation(CameraDescription camera) {
    switch (camera.sensorOrientation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }
  
  double _calculateKneeAngle(
    PoseLandmark? hip,
    PoseLandmark? knee,
    PoseLandmark? ankle,
  ) {
    if (hip == null || knee == null || ankle == null) {
      return 180.0;
    }
    
    final a = _distance(hip, knee);
    final b = _distance(knee, ankle);
    final c = _distance(hip, ankle);
    
    // Law of cosines: cos(C) = (a² + b² - c²) / (2ab)
    final cosC = (a * a + b * b - c * c) / (2 * a * b);
    
    // Handle floating point errors
    final clampedCosC = cosC.clamp(-1.0, 1.0);
    
    return (acos(clampedCosC) * 180.0 / pi);
  }
  
  double _distance(PoseLandmark p1, PoseLandmark p2) {
    final dx = p1.x - p2.x;
    final dy = p1.y - p2.y;
    return sqrt(dx * dx + dy * dy);
  }
  
  void _countReps(double leftKneeAngle, double rightKneeAngle) {
    final avgAngle = (leftKneeAngle + rightKneeAngle) / 2;
    final thresholds = _getThresholds();
    
    if (thresholds == null) return;
    
    final lowerThreshold = thresholds['lower_threshold'] as double;
    final upperThreshold = thresholds['upper_threshold'] as double;
    
    if (_currentPhase == null) {
      _currentPhase = avgAngle < lowerThreshold ? 'down' : 'up';
    } else if (_currentPhase == 'up' && avgAngle < lowerThreshold) {
      _currentPhase = 'down';
    } else if (_currentPhase == 'down' && avgAngle > upperThreshold) {
      _currentPhase = 'up';
      repCount++;
      print("Rep counted! Total: $repCount");
    }
    
    _lastKneeAngle = avgAngle;
  }
  
  Map<String, dynamic>? _getThresholds() {
    if (_exerciseType == null) return null;
    
    switch (_exerciseType!) {
      case 'squat':
        return exerciseThresholds['squat'];
      case 'pushup':
      case 'push_up':
        return exerciseThresholds['pushup'];
      case 'shoulder_press':
        return exerciseThresholds['shoulder_press'];
      default:
        return exerciseThresholds['pushup'];
    }
  }
  
  void resetCount() {
    repCount = 0;
    _currentPhase = null;
    _lastKneeAngle = null;
  }
  
  void dispose() {
    _poseDetector.close();
  }
}