import 'dart:math';

class PosePoint {
  final double x;
  final double y;
  final double confidence;
  final String label;

  PosePoint({
    required this.x,
    required this.y,
    required this.confidence,
    required this.label,
  });

  double distanceTo(PosePoint other) {
    return sqrt(pow(x - other.x, 2) + pow(y - other.y, 2));
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'confidence': confidence,
      'label': label,
    };
  }

  factory PosePoint.fromJson(Map<String, dynamic> json) {
    return PosePoint(
      x: json['x']?.toDouble() ?? 0.0,
      y: json['y']?.toDouble() ?? 0.0,
      confidence: json['confidence']?.toDouble() ?? 0.0,
      label: json['label'] ?? '',
    );
  }
}

class Pose {
  final List<PosePoint> keypoints;
  final double confidence;
  final DateTime timestamp;
  final String? imagePath;

  Pose({
    required this.keypoints,
    required this.confidence,
    required this.timestamp,
    this.imagePath,
  });

  PosePoint? getKeypoint(String label) {
    try {
      return keypoints.firstWhere(
        (point) => point.label == label,
      );
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'keypoints': keypoints.map((point) => point.toJson()).toList(),
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'imagePath': imagePath,
    };
  }

  factory Pose.fromJson(Map<String, dynamic> json) {
    return Pose(
      keypoints: (json['keypoints'] as List)
          .map((pointJson) => PosePoint.fromJson(pointJson))
          .toList(),
      confidence: json['confidence']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['timestamp']),
      imagePath: json['imagePath'],
    );
  }
}

class PoseAngles {
  final double leftElbowAngle;
  final double rightElbowAngle;
  final double leftShoulderAngle;
  final double rightShoulderAngle;
  final double leftKneeAngle;
  final double rightKneeAngle;
  final double leftHipAngle;
  final double rightHipAngle;
  final DateTime timestamp;

  PoseAngles({
    required this.leftElbowAngle,
    required this.rightElbowAngle,
    required this.leftShoulderAngle,
    required this.rightShoulderAngle,
    required this.leftKneeAngle,
    required this.rightKneeAngle,
    required this.leftHipAngle,
    required this.rightHipAngle,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'leftElbowAngle': leftElbowAngle,
      'rightElbowAngle': rightElbowAngle,
      'leftShoulderAngle': leftShoulderAngle,
      'rightShoulderAngle': rightShoulderAngle,
      'leftKneeAngle': leftKneeAngle,
      'rightKneeAngle': rightKneeAngle,
      'leftHipAngle': leftHipAngle,
      'rightHipAngle': rightHipAngle,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PoseAngles.fromJson(Map<String, dynamic> json) {
    return PoseAngles(
      leftElbowAngle: json['leftElbowAngle']?.toDouble() ?? 0.0,
      rightElbowAngle: json['rightElbowAngle']?.toDouble() ?? 0.0,
      leftShoulderAngle: json['leftShoulderAngle']?.toDouble() ?? 0.0,
      rightShoulderAngle: json['rightShoulderAngle']?.toDouble() ?? 0.0,
      leftKneeAngle: json['leftKneeAngle']?.toDouble() ?? 0.0,
      rightKneeAngle: json['rightKneeAngle']?.toDouble() ?? 0.0,
      leftHipAngle: json['leftHipAngle']?.toDouble() ?? 0.0,
      rightHipAngle: json['rightHipAngle']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class ExerciseResult {
  final String exerciseName;
  final int totalReps;
  final int goodFormReps;
  final int badFormReps;
  final double averageAccuracy;
  final int durationSeconds;
  final List<PoseAngles> angleHistory;
  final DateTime startTime;
  final DateTime endTime;

  ExerciseResult({
    required this.exerciseName,
    required this.totalReps,
    required this.goodFormReps,
    required this.badFormReps,
    required this.averageAccuracy,
    required this.durationSeconds,
    required this.angleHistory,
    required this.startTime,
    required this.endTime,
  });

  double get formPercentage {
    if (totalReps == 0) return 0.0;
    return (goodFormReps / totalReps) * 100;
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseName': exerciseName,
      'totalReps': totalReps,
      'goodFormReps': goodFormReps,
      'badFormReps': badFormReps,
      'averageAccuracy': averageAccuracy,
      'durationSeconds': durationSeconds,
      'angleHistory': angleHistory.map((angle) => angle.toJson()).toList(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    };
  }

  factory ExerciseResult.fromJson(Map<String, dynamic> json) {
    return ExerciseResult(
      exerciseName: json['exerciseName'] ?? '',
      totalReps: json['totalReps'] ?? 0,
      goodFormReps: json['goodFormReps'] ?? 0,
      badFormReps: json['badFormReps'] ?? 0,
      averageAccuracy: json['averageAccuracy']?.toDouble() ?? 0.0,
      durationSeconds: json['durationSeconds'] ?? 0,
      angleHistory: (json['angleHistory'] as List)
          .map((angleJson) => PoseAngles.fromJson(angleJson))
          .toList(),
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
    );
  }
}