import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class SimplePoseDetectorService {
  late PoseDetector _poseDetector;
  int repCount = 0;
  
  Future<void> initialize() async {
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.single,
      model: PoseDetectionModel.accurate,
    );
    _poseDetector = PoseDetector(options: options);
  }
  
  Future<Pose?> detectPose(CameraImage image) async {
    try {
      final inputImage = await _createInputImage(image);
      final poses = await _poseDetector.processImage(inputImage);
      return poses.isNotEmpty ? poses.first : null;
    } catch (e) {
      print('Pose detection error: $e');
      return null;
    }
  }
  
  Future<InputImage> _createInputImage(CameraImage image) async {
    // Simple conversion without complex metadata
    final WriteBuffer buffer = WriteBuffer();
    
    for (var plane in image.planes) {
      buffer.putUint8List(plane.bytes);
    }
    
    final bytes = buffer.done().buffer.asUint8List();
    
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation0deg, // Adjust as needed
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }
  
  // Helper method untuk menghitung sudut
  static double calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final ab = _distance(a, b);
    final bc = _distance(b, c);
    final ac = _distance(a, c);
    
    final cosAngle = (ab * ab + bc * bc - ac * ac) / (2 * ab * bc);
    final clamped = cosAngle.clamp(-1.0, 1.0);
    
    return math.acos(clamped) * 180 / math.pi;
  }
  
  static double _distance(PoseLandmark a, PoseLandmark b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt(dx * dx + dy * dy);
  }
  
  void resetCount() => repCount = 0;
  void incrementCount() => repCount++;
  
  void dispose() {
    _poseDetector.close();
  }
}