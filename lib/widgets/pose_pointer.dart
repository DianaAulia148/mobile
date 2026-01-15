import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final Pose pose;
  final Size imageSize;

  PosePainter(this.pose, this.imageSize);

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    Offset t(PoseLandmark lm) =>
        Offset(lm.x * scaleX, lm.y * scaleY);

    final paintGood = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 4;

    final paintBad = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 4;

    // =============================
    // BODY LINE (SHOULDER-HIP-ANKLE)
    // =============================
    final shoulder = _midPoint(
      pose.landmarks[PoseLandmarkType.leftShoulder]!,
      pose.landmarks[PoseLandmarkType.rightShoulder]!,
    );

    final hip = _midPoint(
      pose.landmarks[PoseLandmarkType.leftHip]!,
      pose.landmarks[PoseLandmarkType.rightHip]!,
    );

    final ankle = _midPoint(
      pose.landmarks[PoseLandmarkType.leftAnkle]!,
      pose.landmarks[PoseLandmarkType.rightAnkle]!,
    );

    final bodyAngle = _angleBetween(shoulder, hip, ankle);
    final bodyPaint = bodyAngle < 15 ? paintGood : paintBad;

    canvas.drawLine(t(shoulder), t(hip), bodyPaint);
    canvas.drawLine(t(hip), t(ankle), bodyPaint);

    // =============================
    // ELBOW ANGLES
    // =============================
    _drawElbow(
      canvas,
      pose.landmarks[PoseLandmarkType.leftShoulder]!,
      pose.landmarks[PoseLandmarkType.leftElbow]!,
      pose.landmarks[PoseLandmarkType.leftWrist]!,
      scaleX,
      scaleY,
    );

    _drawElbow(
      canvas,
      pose.landmarks[PoseLandmarkType.rightShoulder]!,
      pose.landmarks[PoseLandmarkType.rightElbow]!,
      pose.landmarks[PoseLandmarkType.rightWrist]!,
      scaleX,
      scaleY,
    );
  }

  void _drawElbow(
    Canvas canvas,
    PoseLandmark shoulder,
    PoseLandmark elbow,
    PoseLandmark wrist,
    double sx,
    double sy,
  ) {
    final angle = _calculateAngle(shoulder, elbow, wrist);

    final paint = Paint()
      ..color = angle < 95 || angle > 160
          ? Colors.greenAccent
          : Colors.orangeAccent
      ..strokeWidth = 4;

    final e = Offset(elbow.x * sx, elbow.y * sy);

    canvas.drawLine(
      Offset(shoulder.x * sx, shoulder.y * sy),
      e,
      paint,
    );

    canvas.drawLine(
      Offset(wrist.x * sx, wrist.y * sy),
      e,
      paint,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: "${angle.toStringAsFixed(0)}°",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, e + const Offset(6, -6));
  }

  // =============================
  // MATH UTILS
  // =============================
  PoseLandmark _midPoint(PoseLandmark a, PoseLandmark b) {
    return PoseLandmark(
      type: a.type,
      x: (a.x + b.x) / 2,
      y: (a.y + b.y) / 2,
      z: (a.z + b.z) / 2,
      likelihood: min(a.likelihood ?? 0, b.likelihood ?? 0),
    );
  }

  double _calculateAngle(
    PoseLandmark a,
    PoseLandmark b,
    PoseLandmark c,
  ) {
    final ab = Offset(a.x - b.x, a.y - b.y);
    final cb = Offset(c.x - b.x, c.y - b.y);

    final dot = ab.dx * cb.dx + ab.dy * cb.dy;
    final mag = sqrt(ab.distanceSquared * cb.distanceSquared);

    return acos(dot / mag) * 180 / pi;
  }

  double _angleBetween(
    PoseLandmark a,
    PoseLandmark b,
    PoseLandmark c,
  ) {
    return _calculateAngle(a, b, c);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
