import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseData {
  final List<Keypoint> keypoints;
  final double confidence;
  final DateTime timestamp;
  final Pose? pose; // PROPERY YANG DIPERLUKAN DI pose_detector_service.dart
  Map<String, dynamic>? aiValidation; // PERBAIKAN: jadikan non-final
  
  PoseData({
    required this.keypoints,
    required this.confidence,
    required this.timestamp,
    this.pose,
    this.aiValidation,
  });
  
  // Constructor tambahan untuk inisialisasi dari Pose ML Kit
  factory PoseData.fromPose(Pose pose, int imageWidth, int imageHeight) {
    final keypoints = <Keypoint>[];
    
    // Convert landmarks to Keypoint format
    for (final landmark in pose.landmarks.values) {
      keypoints.add(Keypoint(
        x: landmark.x * imageWidth,
        y: landmark.y * imageHeight,
        confidence: landmark.likelihood,
        part: _getBodyPartName(landmark.type),
      ));
    }
    
    final avgConfidence = keypoints.isNotEmpty 
        ? keypoints.map((kp) => kp.confidence).reduce((a, b) => a + b) / keypoints.length
        : 0.0;
    
    return PoseData(
      keypoints: keypoints,
      confidence: avgConfidence,
      timestamp: DateTime.now(),
      pose: pose,
    );
  }
  
  static String _getBodyPartName(PoseLandmarkType type) {
    switch (type) {
      case PoseLandmarkType.nose: return 'nose';
      case PoseLandmarkType.leftShoulder: return 'left_shoulder';
      case PoseLandmarkType.rightShoulder: return 'right_shoulder';
      case PoseLandmarkType.leftElbow: return 'left_elbow';
      case PoseLandmarkType.rightElbow: return 'right_elbow';
      case PoseLandmarkType.leftWrist: return 'left_wrist';
      case PoseLandmarkType.rightWrist: return 'right_wrist';
      case PoseLandmarkType.leftHip: return 'left_hip';
      case PoseLandmarkType.rightHip: return 'right_hip';
      case PoseLandmarkType.leftKnee: return 'left_knee';
      case PoseLandmarkType.rightKnee: return 'right_knee';
      case PoseLandmarkType.leftAnkle: return 'left_ankle';
      case PoseLandmarkType.rightAnkle: return 'right_ankle';
      default: return type.toString().split('.').last.toLowerCase();
    }
  }
  
  // Helper methods untuk angle calculation
  double getLeftKneeAngle() {
    final hip = getKeypoint('left_hip');
    final knee = getKeypoint('left_knee');
    final ankle = getKeypoint('left_ankle');
    
    if (hip != null && knee != null && ankle != null && 
        hip.confidence > 0.5 && knee.confidence > 0.5 && ankle.confidence > 0.5) {
      return _calculateAngle(hip, knee, ankle);
    }
    return 0.0;
  }
  
  double getRightKneeAngle() {
    final hip = getKeypoint('right_hip');
    final knee = getKeypoint('right_knee');
    final ankle = getKeypoint('right_ankle');
    
    if (hip != null && knee != null && ankle != null && 
        hip.confidence > 0.5 && knee.confidence > 0.5 && ankle.confidence > 0.5) {
      return _calculateAngle(hip, knee, ankle);
    }
    return 0.0;
  }
  
  double getAverageKneeAngle() {
    final left = getLeftKneeAngle();
    final right = getRightKneeAngle();
    return (left + right) / 2;
  }
  
  double getAverageElbowAngle() {
    final leftShoulder = getKeypoint('left_shoulder');
    final leftElbow = getKeypoint('left_elbow');
    final leftWrist = getKeypoint('left_wrist');
    
    final rightShoulder = getKeypoint('right_shoulder');
    final rightElbow = getKeypoint('right_elbow');
    final rightWrist = getKeypoint('right_wrist');
    
    double leftAngle = 0.0, rightAngle = 0.0;
    int count = 0;
    
    if (leftShoulder != null && leftElbow != null && leftWrist != null &&
        leftShoulder.confidence > 0.5 && leftElbow.confidence > 0.5 && leftWrist.confidence > 0.5) {
      leftAngle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
      count++;
    }
    
    if (rightShoulder != null && rightElbow != null && rightWrist != null &&
        rightShoulder.confidence > 0.5 && rightElbow.confidence > 0.5 && rightWrist.confidence > 0.5) {
      rightAngle = _calculateAngle(rightShoulder, rightElbow, rightWrist);
      count++;
    }
    
    return count > 0 ? (leftAngle + rightAngle) / count : 0.0;
  }
  
  String getPostureFeedback() {
    final avgAngle = getAverageKneeAngle();
    
    if (avgAngle < 60) {
      return "Terlalu rendah, jaga form!";
    } else if (avgAngle > 170) {
      return "Lurus, pertahankan!";
    } else {
      return "Form baik, lanjutkan!";
    }
  }
  
  double _calculateAngle(Keypoint a, Keypoint b, Keypoint c) {
    final Vector2 ab = Vector2(b.x - a.x, b.y - a.y);
    final Vector2 bc = Vector2(c.x - b.x, c.y - b.y);
    
    final double dotProduct = ab.dot(bc);
    final double magnitudeAB = ab.length;
    final double magnitudeBC = bc.length;
    
    if (magnitudeAB == 0 || magnitudeBC == 0) return 0.0;
    
    final double cosAngle = dotProduct / (magnitudeAB * magnitudeBC);
    return acos(cosAngle.clamp(-1.0, 1.0)) * (180 / pi);
  }
  
  Keypoint? getKeypoint(String partName) {
    return keypoints.firstWhere(
      (kp) => kp.part == partName,
      orElse: () => Keypoint(x: 0, y: 0, confidence: 0, part: partName),
    );
  }
}

class Keypoint {
  final double x;
  final double y;
  final double confidence;
  final String part;
  
  Keypoint({
    required this.x,
    required this.y,
    required this.confidence,
    required this.part,
  });
}

class PoseAnalysisResult {
  final int reps;
  final double confidence;
  final Map<String, double> angles;
  final List<String> formFeedback;
  final DateTime timestamp;
  
  PoseAnalysisResult({
    required this.reps,
    required this.confidence,
    required this.angles,
    required this.formFeedback,
    required this.timestamp,
  });
}

class Point {
  final double x;
  final double y;
  
  Point(this.x, this.y);
}

// Helper class untuk vector operations
class Vector2 {
  final double x, y;
  
  Vector2(this.x, this.y);
  
  double dot(Vector2 other) => x * other.x + y * other.y;
  double get length => sqrt(x * x + y * y);
}