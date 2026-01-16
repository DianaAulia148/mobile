// mlkit_pose_detector.dart - SIMPLIFIED VERSION
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class MLKitPoseDetector {
  late PoseDetector _poseDetector;
  bool _isInitialized = false;
  
  Future<void> initialize() async {
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.single,
      model: PoseDetectionModel.accurate,
    );
    
    _poseDetector = PoseDetector(options: options);
    _isInitialized = true;
    print("MLKit Pose Detector initialized");
  }
  
  Future<List<Pose>?> detectPoses(CameraImage image, CameraDescription camera) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final inputImage = _convertToInputImage(image, camera);
      final poses = await _poseDetector.processImage(inputImage);
      return poses.isNotEmpty ? poses : null;
    } catch (e) {
      print("Error detecting poses: $e");
      return null;
    }
  }
  
  InputImage _convertToInputImage(CameraImage image, CameraDescription camera) {
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
  
  void dispose() {
    if (_isInitialized) {
      _poseDetector.close();
      _isInitialized = false;
      print("MLKit Pose Detector disposed");
    }
  }
}