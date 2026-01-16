import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final Pose? pose;
  final Size imageSize;
  final Size widgetSize;
  final double scale;
  
  PosePainter({
    required this.pose,
    required this.imageSize,
    required this.widgetSize,
    this.scale = 1.0,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (pose == null || pose!.landmarks.isEmpty) return;
    
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4.0 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final jointPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 6.0 * scale
      ..style = PaintingStyle.fill;
    
    // Calculate scaling factors
    final scaleX = widgetSize.width / imageSize.width;
    final scaleY = widgetSize.height / imageSize.height;
    
    // Draw keypoints
    for (final landmark in pose!.landmarks.values) {
      if (landmark.likelihood > 0.5) {
        final x = landmark.x * widgetSize.width;
        final y = landmark.y * widgetSize.height;
        
        canvas.drawCircle(
          Offset(x, y),
          8.0 * scale,
          jointPaint,
        );
      }
    }
    
    // Draw connections
    _drawConnection(
      canvas, 
      PoseLandmarkType.leftShoulder, 
      PoseLandmarkType.rightShoulder, 
      paint,
      scaleX,
      scaleY
    );
    _drawConnection(
      canvas, 
      PoseLandmarkType.leftShoulder, 
      PoseLandmarkType.leftElbow, 
      paint,
      scaleX,
      scaleY
    );
    _drawConnection(
      canvas, 
      PoseLandmarkType.leftElbow, 
      PoseLandmarkType.leftWrist, 
      paint,
      scaleX,
      scaleY
    );
    _drawConnection(
      canvas, 
      PoseLandmarkType.rightShoulder, 
      PoseLandmarkType.rightElbow, 
      paint,
      scaleX,
      scaleY
    );
    _drawConnection(
      canvas, 
      PoseLandmarkType.rightElbow, 
      PoseLandmarkType.rightWrist, 
      paint,
      scaleX,
      scaleY
    );
    _drawConnection(
      canvas, 
      PoseLandmarkType.leftShoulder, 
      PoseLandmarkType.leftHip, 
      paint,
      scaleX,
      scaleY
    );
    _drawConnection(
      canvas, 
      PoseLandmarkType.rightShoulder, 
      PoseLandmarkType.rightHip, 
      paint,
      scaleX,
      scaleY
    );
    _drawConnection(
      canvas, 
      PoseLandmarkType.leftHip, 
      PoseLandmarkType.rightHip, 
      paint,
      scaleX,
      scaleY
    );
    _drawConnection(
      canvas, 
      PoseLandmarkType.leftHip, 
      PoseLandmarkType.leftKnee, 
      paint,
      scaleX,
      scaleY
    );
    _drawConnection(
      canvas, 
      PoseLandmarkType.leftKnee, 
      PoseLandmarkType.leftAnkle, 
      paint,
      scaleX,
      scaleY
    );
    _drawConnection(
      canvas, 
      PoseLandmarkType.rightHip, 
      PoseLandmarkType.rightKnee, 
      paint,
      scaleX,
      scaleY
    );
    _drawConnection(
      canvas, 
      PoseLandmarkType.rightKnee, 
      PoseLandmarkType.rightAnkle, 
      paint,
      scaleX,
      scaleY
    );
  }
  
  void _drawConnection(
    Canvas canvas, 
    PoseLandmarkType type1, 
    PoseLandmarkType type2, 
    Paint paint,
    double scaleX,
    double scaleY
  ) {
    final landmark1 = pose!.landmarks[type1];
    final landmark2 = pose!.landmarks[type2];
    
    if (landmark1 != null && landmark2 != null && 
        landmark1.likelihood > 0.5 && landmark2.likelihood > 0.5) {
      final x1 = landmark1.x * widgetSize.width;
      final y1 = landmark1.y * widgetSize.height;
      final x2 = landmark2.x * widgetSize.width;
      final y2 = landmark2.y * widgetSize.height;
      
      canvas.drawLine(
        Offset(x1, y1),
        Offset(x2, y2),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}