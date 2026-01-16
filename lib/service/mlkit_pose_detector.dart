// mlkit_pose_detector.dart - MINIMAL VERSION
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class MLKitPoseDetector {
  late PoseDetector _poseDetector;
  
  Future<void> initialize() async {
    _poseDetector = PoseDetector(options: PoseDetectorOptions(
      mode: PoseDetectionMode.single,
      model: PoseDetectionModel.accurate,
    ));
  }
  
  Future<List<Pose>?> processImage(InputImage image) async {
    return await _poseDetector.processImage(image);
  }
  
  void dispose() {
    _poseDetector.close();
  }
}