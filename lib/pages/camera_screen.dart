import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tflite;
import '../service/pose_detector_service.dart';
import '../painter/pose_painter.dart';
import '../models/workout.dart';
import '../service/workout_service.dart';

// Alias untuk menghindari conflict
import '../service/workout_service.dart' as ws;

class CameraScreen extends StatefulWidget {
  final Workout workout;
  final String exerciseType;
  
  const CameraScreen({
    Key? key,
    required this.workout,
    required this.exerciseType,
  }) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  final PoseDetectorService _poseService = PoseDetectorService();
  
  // TFLite model
  late tflite.Interpreter _tfliteInterpreter;
  bool _isTfliteLoaded = false;
  
  bool _isDetecting = false;
  bool _isInitialized = false;
  bool _isProcessing = false;
  
  String _feedbackMessage = "Position yourself in frame";
  int _repCount = 0;
  int _correctReps = 0;
  Pose? _currentPose;
  String _debugInfo = "";
  final List<Map<String, dynamic>> _repHistory = [];
  
  // Timer untuk durasi workout
  int _elapsedSeconds = 0;
  late Timer _timer;
  
  // Exercise thresholds berdasarkan TFLite model
  final Map<String, Map<String, double>> _exerciseThresholds = {
    'pushup': {
      'min_angle': 80.0,
      'max_angle': 120.0,
      'rep_threshold': 100.0,
    },
    'squat': {
      'min_angle': 60.0,
      'max_angle': 100.0,
      'rep_threshold': 90.0,
    },
    'shoulder_press': {
      'min_angle': 150.0,
      'max_angle': 180.0,
      'rep_threshold': 160.0,
    }
  };
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadTfliteModel();
    
    // Start timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDetecting) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }
  
  Future<void> _loadTfliteModel() async {
    try {
      // Load model berdasarkan exercise type
      String modelPath = 'assets/models/push-up/pushup_model.tflite';
      
      if (widget.exerciseType == 'squat') {
        modelPath = 'assets/models/squat/squat_model.tflite';
      } else if (widget.exerciseType == 'shoulder_press') {
        modelPath = 'assets/models/shoulder_press/shoulder_press_model.tflite';
      }
      
      _tfliteInterpreter = await tflite.Interpreter.fromAsset(modelPath);
      _isTfliteLoaded = true;
      
      print('TFLite model loaded: ${widget.exerciseType}');
    } catch (e) {
      print('Error loading TFLite model: $e');
      // Fallback ke ML Kit saja
    }
  }
  
  Future<void> _initializeCamera() async {
    // Request camera permission
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() {
        _feedbackMessage = "Camera permission denied";
      });
      return;
    }
    
    try {
      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _feedbackMessage = "No camera found";
        });
        return;
      }
      
      // Use front camera for better user experience
      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      
      // Initialize camera controller
      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      
      await _cameraController!.initialize();
      await _poseService.initialize(exerciseType: widget.exerciseType);
      
      // Start image stream
      _cameraController!.startImageStream(_processCameraImage);
      
      setState(() {
        _isInitialized = true;
        _feedbackMessage = "Ready! Start your ${widget.exerciseType.replaceAll('_', ' ')}";
      });
      
    } catch (e) {
      setState(() {
        _feedbackMessage = "Error initializing camera: $e";
      });
    }
  }
  
  // Process pose dengan TFLite model
  Future<Map<String, dynamic>?> _processWithTflite(List<double> normalizedKeypoints) async {
    if (!_isTfliteLoaded || normalizedKeypoints.length < 51) { // 17 keypoints * 3 (x, y, confidence)
      return null;
    }
    
    try {
      // Reshape input untuk model
      final input = normalizedKeypoints.reshape([1, normalizedKeypoints.length]);
      final output = List.filled(1, List.filled(1, 0.0));
      
      // Run inference
      _tfliteInterpreter.run(input, output);
      
      // Interpret hasil berdasarkan exercise type
      final thresholds = _exerciseThresholds[widget.exerciseType] ?? _exerciseThresholds['pushup']!;
      final prediction = output[0][0];
      
      return {
        'is_correct_form': prediction > 0.5,
        'confidence': prediction,
        'threshold': thresholds['rep_threshold'],
        'feedback': _generateFeedback(prediction, thresholds),
      };
    } catch (e) {
      print('TFLite inference error: $e');
      return null;
    }
  }
  
  String _generateFeedback(double prediction, Map<String, double> thresholds) {
    if (prediction < 0.3) {
      return 'Form sangat buruk, perbaiki posisi Anda';
    } else if (prediction < 0.6) {
      return 'Form cukup, fokus pada gerakan yang benar';
    } else if (prediction < 0.8) {
      return 'Form baik, pertahankan!';
    } else {
      return 'Form sempurna! Lanjutkan!';
    }
  }
  
  // Normalize keypoints dari pose
  List<double> _normalizeKeypoints(Pose pose) {
    List<double> normalized = [];
    
    // Get all landmarks
    final landmarks = [
      pose.landmarks[PoseLandmarkType.nose],
      pose.landmarks[PoseLandmarkType.leftEyeInner],
      pose.landmarks[PoseLandmarkType.leftEye],
      pose.landmarks[PoseLandmarkType.leftEyeOuter],
      pose.landmarks[PoseLandmarkType.rightEyeInner],
      pose.landmarks[PoseLandmarkType.rightEye],
      pose.landmarks[PoseLandmarkType.rightEyeOuter],
      pose.landmarks[PoseLandmarkType.leftEar],
      pose.landmarks[PoseLandmarkType.rightEar],
      pose.landmarks[PoseLandmarkType.leftMouth],
      pose.landmarks[PoseLandmarkType.rightMouth],
      pose.landmarks[PoseLandmarkType.leftShoulder],
      pose.landmarks[PoseLandmarkType.rightShoulder],
      pose.landmarks[PoseLandmarkType.leftElbow],
      pose.landmarks[PoseLandmarkType.rightElbow],
      pose.landmarks[PoseLandmarkType.leftWrist],
      pose.landmarks[PoseLandmarkType.rightWrist],
    ];
    
    // Normalize coordinates
    for (var landmark in landmarks) {
      if (landmark != null) {
        normalized.add(landmark.x);
        normalized.add(landmark.y);
        normalized.add(landmark.likelihood);
      } else {
        normalized.addAll([0.0, 0.0, 0.0]);
      }
    }
    
    return normalized;
  }
  
  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || !_isDetecting || _cameraController == null) return;
    
    _isProcessing = true;
    
    try {
      final poseData = await _poseService.detectPose(
        image,
        _cameraController!.description,
      );
      
      if (poseData != null && mounted) {
        final newRepCount = _poseService.repCount;
        
        // Cek apakah ada rep baru
        if (newRepCount > _repCount) {
          // Proses dengan TFLite untuk validasi form
          final normalizedKeypoints = _normalizeKeypoints(poseData.pose);
          final tfliteResult = await _processWithTflite(normalizedKeypoints);
          
          bool isCorrectForm = true;
          double formConfidence = 0.0;
          String aiFeedback = '';
          
          if (tfliteResult != null) {
            isCorrectForm = tfliteResult['is_correct_form'] ?? true;
            formConfidence = tfliteResult['confidence'] ?? 0.0;
            aiFeedback = tfliteResult['feedback'] ?? '';
            
            if (isCorrectForm && formConfidence > 0.6) {
              _correctReps++;
            }
          }
          
          _repHistory.add({
            'timestamp': DateTime.now(),
            'rep_number': newRepCount,
            'is_correct_form': isCorrectForm,
            'form_confidence': formConfidence,
            'angles': {
              'left_knee': poseData.getLeftKneeAngle().toInt(),
              'right_knee': poseData.getRightKneeAngle().toInt(),
            },
            'aiFeedback': aiFeedback,
          });
        }
        
        // Update feedback
        String feedback = poseData.getPostureFeedback();
        if (_isTfliteLoaded && _repHistory.isNotEmpty) {
          final lastRep = _repHistory.last;
          if (lastRep['aiFeedback'] != null && lastRep['aiFeedback'].toString().isNotEmpty) {
            feedback = lastRep['aiFeedback'].toString();
          }
        }
        
        setState(() {
          _repCount = newRepCount;
          _feedbackMessage = feedback;
          _currentPose = poseData.pose;
          _debugInfo = "Reps: $_repCount | Correct: $_correctReps | Time: ${_formatDuration(_elapsedSeconds)}";
        });
      }
    } catch (e) {
      print('Error processing image: $e');
    } finally {
      _isProcessing = false;
    }
  }
  
  void _toggleDetection() {
    setState(() {
      _isDetecting = !_isDetecting;
      if (_isDetecting) {
        _feedbackMessage = "Detecting... Start exercising!";
      } else {
        _feedbackMessage = "Paused";
      }
    });
  }
  
  void _resetCount() {
    _poseService.resetCount();
    setState(() {
      _repCount = 0;
      _correctReps = 0;
      _elapsedSeconds = 0;
      _repHistory.clear();
      _feedbackMessage = "Counter reset. Ready!";
    });
  }
  
  Future<void> _completeWorkout() async {
    if (_repCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lakukan setidaknya 1 rep sebelum menyelesaikan'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Hitung akurasi berdasarkan TFLite model
    double averageAccuracy = 0.0;
    if (_repHistory.isNotEmpty) {
      double totalConfidence = 0.0;
      int count = 0;
      
      for (var rep in _repHistory) {
        if (rep['is_correct_form'] == true) {
          totalConfidence += (rep['form_confidence'] as double?) ?? 0.0;
          count++;
        }
      }
      
      if (count > 0) {
        averageAccuracy = (totalConfidence / count * 100).clamp(0.0, 100.0);
      }
    }
    
    try {
      // Submit hasil workout ke API
      final result = await ws.WorkoutService.submitPoseDetectionWorkout(
        workoutId: widget.workout.id,
        exerciseType: widget.exerciseType,
        totalReps: _repCount,
        sets: 1,
        durationSeconds: _elapsedSeconds,
        averageConfidence: averageAccuracy,
        poseAnalysis: {
          'total_reps': _repCount,
          'correct_reps': _correctReps,
          'average_accuracy': averageAccuracy,
          'rep_history': _repHistory,
          'tflite_used': _isTfliteLoaded,
        },
        movementAnalysis: {
          'exercise_type': widget.exerciseType,
          'duration_seconds': _elapsedSeconds,
          'start_time': DateTime.now().subtract(Duration(seconds: _elapsedSeconds)).toString(),
          'end_time': DateTime.now().toString(),
        },
      );
      
      if (result['success'] == true) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal menyimpan hasil workout'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  void dispose() {
    _timer.cancel();
    _cameraController?.dispose();
    _poseService.dispose();
    if (_isTfliteLoaded) {
      _tfliteInterpreter.close();
    }
    super.dispose();
  }
  
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isInitialized && _cameraController != null
            ? Stack(
                children: [
                  // Camera Preview
                  Center(
                    child: CameraPreview(_cameraController!),
                  ),
                  
                  // Skeleton Overlay
                  if (_isDetecting && _currentPose != null)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: PosePainter(
                          pose: _currentPose!,
                          imageSize: Size(
                            _cameraController!.value.previewSize!.height,
                            _cameraController!.value.previewSize!.width,
                          ),
                          widgetSize: MediaQuery.of(context).size,
                        ),
                      ),
                    ),
                  
                  // Top Bar with workout info
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                              Column(
                                children: [
                                  Text(
                                    widget.workout.namaWorkout,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    widget.exerciseType.replaceAll('_', ' ').toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.blueAccent,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.done, color: Colors.green),
                                onPressed: _completeWorkout,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _feedbackMessage,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Stats Container - Top Right
                  Positioned(
                    top: 160,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.timer, color: Colors.white, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'Duration',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            _formatDuration(_elapsedSeconds),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Stats Container - Top Left
                  Positioned(
                    top: 160,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'Correct',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            '$_correctReps/$_repCount',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Rep Counter - Center
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_repCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'REPS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Debug Info (hanya di development)
                  if (_debugInfo.isNotEmpty)
                    Positioned(
                      bottom: 200,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isTfliteLoaded)
                              const Icon(Icons.psychology, color: Colors.purple, size: 12),
                            SizedBox(width: 4),
                            Text(
                              _debugInfo,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // AI Status Indicator
                  if (_isTfliteLoaded)
                    Positioned(
                      top: 220,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            const Text(
                              'AI Active',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Bottom Controls
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Reset Button
                              _buildControlButton(
                                icon: Icons.refresh,
                                label: 'Reset',
                                onPressed: _resetCount,
                                color: Colors.orange,
                              ),
                              
                              // Start/Stop Button
                              _buildControlButton(
                                icon: _isDetecting ? Icons.pause : Icons.play_arrow,
                                label: _isDetecting ? 'Pause' : 'Start',
                                onPressed: _toggleDetection,
                                color: _isDetecting ? Colors.red : Colors.green,
                                isLarge: true,
                              ),
                              
                              // Help Button
                              _buildControlButton(
                                icon: Icons.info_outline,
                                label: 'Help',
                                onPressed: _showHelpDialog,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _completeWorkout,
                              icon: const Icon(Icons.done_all, size: 20),
                              label: const Text('Selesaikan Workout'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _feedbackMessage,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.workout.namaWorkout,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    if (!_isTfliteLoaded)
                      const Text(
                        'Loading AI Model...',
                        style: TextStyle(
                          color: Colors.purple,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
    bool isLarge = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: const CircleBorder(),
            padding: EdgeInsets.all(isLarge ? 24 : 16),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: isLarge ? 40 : 28,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI-Powered Workout Trainer'),
        backgroundColor: Colors.grey[900],
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(color: Colors.white70),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.workout.namaWorkout}\n',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isTfliteLoaded)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.purple, size: 16),
                        SizedBox(width: 8),
                        const Text(
                          'AI Features Active:',
                          style: TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '✓ Real-time form validation\n'
                      '✓ TFLite deep learning model\n'
                      '✓ Adaptive feedback system\n'
                      '✓ Progress tracking\n',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              Text(
                'How to Use:\n\n'
                '1. Pastikan seluruh tubuh dalam frame kamera\n\n'
                '2. Tekan START untuk memulai deteksi AI\n\n'
                '3. Lakukan gerakan ${widget.exerciseType.replaceAll('_', ' ')}:\n'
                '   • ${_getExerciseInstructions(widget.exerciseType)}\n\n'
                '4. Sistem AI akan:\n'
                '   • Menghitung rep secara akurat\n'
                '   • Menganalisa form gerakan\n'
                '   • Memberikan feedback real-time\n\n'
                '5. Tekan SELESAI untuk menyimpan hasil\n\n'
                '6. Data akan tersimpan dengan analisis AI',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it!',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getExerciseInstructions(String exerciseType) {
    switch (exerciseType.toLowerCase()) {
      case 'pushup':
      case 'push_up':
        return 'Berdiri dengan tangan di lantai, turunkan tubuh hingga dada hampir menyentuh lantai, lalu dorong kembali ke atas';
      case 'squat':
        return 'Berdiri tegak, turunkan tubuh dengan menekuk lutut, lalu kembali berdiri';
      case 'shoulder_press':
        return 'Angkat beban dari bahu ke atas kepala, lalu turunkan kembali';
      default:
        return 'Lakukan gerakan dengan form yang benar dan kontrol penuh';
    }
  }
}

// Extension untuk reshape list
extension ListExtension on List<double> {
  List<List<double>> reshape(List<int> shape) {
    if (shape.length != 2) throw ArgumentError('Shape must be 2D');
    final rows = shape[0];
    final cols = shape[1];
    
    if (length != rows * cols) throw ArgumentError('Invalid shape for list length');
    
    List<List<double>> result = [];
    for (int i = 0; i < rows; i++) {
      final start = i * cols;
      final end = start + cols;
      result.add(sublist(start, end));
    }
    
    return result;
  }
}