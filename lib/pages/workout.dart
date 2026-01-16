import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../service/workout_service.dart';
import 'camera_screen.dart';

/// ================= PALETTE WARNA UNGU =================
class PurplePalette {
  static const Color lavender = Color(0xFFE39FF6);
  static const Color lilac = Color(0xFFBD93D3);
  static const Color amethyst = Color(0xFF9966CC);
  static const Color wildberry = Color(0xFF8B2991);
  static const Color iris = Color(0xFF9866C5);
  static const Color orchid = Color(0xFFAF69EE);
  static const Color periwinkle = Color(0xFFBD93D3);
  static const Color eggplant = Color(0xFF380385);
  static const Color violet = Color(0xFF710193);
  static const Color purple = Color(0xFFA32CC4);
  static const Color mauve = Color(0xFF7A4A88);
  static const Color heather = Color(0xFF9B7CB8);

  static const Color background = Color(0xFF08030C);
  static const Color cardBackground = Color(0xFF2C123A);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFC7B8D6);
  static const Color accent = purple;
  static const Color success = Color(0xFF4CAF50);
  static const Color info = Color(0xFF2196F3);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);

  // Workout category colors
  static const Color calisthenicsColor = Color(0xFF4FC3F7);
  static const Color strengthTrainingColor = Color(0xFF66BB6A);
  static const Color muscleBuildingColor = Color(0xFFEF5350);
  static const Color cardioColor = Color(0xFFFF9800);
  static const Color flexibilityColor = Color(0xFFAB47BC);
}

class WorkoutPlanPage extends StatefulWidget {
  const WorkoutPlanPage({super.key});

  @override
  State<WorkoutPlanPage> createState() => _WorkoutPlanPageState();
}

class _WorkoutPlanPageState extends State<WorkoutPlanPage> {
  int _selectedCategory = 0;
  final List<String> _categories = [
    "Semua",
    "Calisthenics",
    "Strength Training",
    "Muscle Building",
    "Cardio",
    "Flexibility"
  ];
  
  final List<Color> _categoryColors = [
    PurplePalette.accent,
    PurplePalette.calisthenicsColor,
    PurplePalette.strengthTrainingColor,
    PurplePalette.muscleBuildingColor,
    PurplePalette.cardioColor,
    PurplePalette.flexibilityColor,
  ];

  WorkoutResponse? _workoutResponse;
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final result = await WorkoutService.getTodayWorkoutsWithRetry();

    if (result['success'] == true && result['data'] != null) {
      setState(() {
        _workoutResponse = result['data'] as WorkoutResponse;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Gagal memuat data workout';
        _isLoading = false;
      });
    }
  }

  List<Workout> _getFilteredWorkouts() {
    if (_workoutResponse == null) return [];

    List<Workout> workouts = _workoutResponse!.workouts;

    // Filter by category
    if (_selectedCategory > 0) {
      final categoryMap = {
        1: 'calisthenics',
        2: 'strength',
        3: 'muscle',
        4: 'cardio',
        5: 'flexibility',
      };
      
      final selectedCategory = categoryMap[_selectedCategory]!;
      workouts = workouts.where((workout) => 
        workout.kategori.toLowerCase().contains(selectedCategory)
      ).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      workouts = workouts.where((workout) =>
        workout.namaWorkout.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        workout.deskripsi.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        workout.exercises.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Sort by status: in-progress -> not started -> completed
    workouts.sort((a, b) {
      if (a.isStarted && !b.isStarted) return -1;
      if (!a.isStarted && b.isStarted) return 1;
      if (!a.isCompleted && b.isCompleted) return -1;
      if (a.isCompleted && !b.isCompleted) return 1;
      return 0;
    });

    return workouts;
  }

  Color _getCategoryColor(String kategori) {
    final k = kategori.toLowerCase();
    
    if (k.contains('calisthenics')) {
      return PurplePalette.calisthenicsColor;
    } else if (k.contains('strength')) {
      return PurplePalette.strengthTrainingColor;
    } else if (k.contains('muscle') || k.contains('building')) {
      return PurplePalette.muscleBuildingColor;
    } else if (k.contains('cardio')) {
      return PurplePalette.cardioColor;
    } else if (k.contains('flexibility') || k.contains('yoga')) {
      return PurplePalette.flexibilityColor;
    }
    
    return PurplePalette.lilac;
  }

  Color _getStatusColor(Workout workout) {
    if (workout.isCompleted) {
      return PurplePalette.success;
    } else if (workout.isStarted) {
      return PurplePalette.warning;
    }
    return PurplePalette.textSecondary;
  }

  IconData _getStatusIcon(Workout workout) {
    if (workout.isCompleted) {
      return FontAwesomeIcons.checkCircle;
    } else if (workout.isStarted) {
      return FontAwesomeIcons.playCircle;
    }
    return FontAwesomeIcons.clock;
  }

  IconData _getWorkoutIcon(Workout workout) {
    final ex = workout.exercises.toLowerCase();
    
    if (ex.contains('push')) {
      return FontAwesomeIcons.handSparkles;
    } else if (ex.contains('squat')) {
      return FontAwesomeIcons.personWalking;
    } else if (ex.contains('shoulder')) {
      return FontAwesomeIcons.arrowUp;
    } else if (ex.contains('plank')) {
      return FontAwesomeIcons.squareFull;
    } else if (ex.contains('lung')) {
      return FontAwesomeIcons.personWalking;
    } else if (ex.contains('sit') || ex.contains('crunch')) {
      return FontAwesomeIcons.personBooth;
    }
    
    final category = workout.kategori.toLowerCase();
    if (category.contains('yoga') || category.contains('flexibility')) {
      return FontAwesomeIcons.spa;
    } else if (category.contains('cardio')) {
      return FontAwesomeIcons.personRunning;
    }
    
    return FontAwesomeIcons.dumbbell;
  }

  int _getTargetReps(Workout workout) {
    try {
      final desc = workout.deskripsi.toLowerCase();
      final regex = RegExp(r'(\d+)\s*reps?');
      final match = regex.firstMatch(desc);
      
      if (match != null) {
        return int.parse(match.group(1)!);
      }
      
      final exercise = workout.exercises.toLowerCase();
      if (exercise.contains('push')) return 15;
      if (exercise.contains('squat')) return 20;
      if (exercise.contains('shoulder')) return 12;
      if (exercise.contains('plank')) return 30;
      if (exercise.contains('lunge')) return 12;
      if (exercise.contains('sit') || exercise.contains('crunch')) return 20;
      
      return 12;
    } catch (e) {
      return 12;
    }
  }

  int _getTargetSets(Workout workout) {
    try {
      final desc = workout.deskripsi.toLowerCase();
      final regex = RegExp(r'(\d+)\s*sets?');
      final match = regex.firstMatch(desc);
      
      if (match != null) {
        return int.parse(match.group(1)!);
      }
      
      return 3;
    } catch (e) {
      return 3;
    }
  }

 void _navigateToCameraScreen(Workout workout) async {
  try {
    String exerciseType = workout.exercises.toLowerCase();
    
    if (exerciseType.contains('push')) {
      exerciseType = 'pushup';
    } else if (exerciseType.contains('squat')) {
      exerciseType = 'squat';
    } else if (exerciseType.contains('shoulder')) {
      exerciseType = 'shoulder_press';
    }
    
    // Update status to "sedang dilakukan" sebelum mulai
    final startResult = await WorkoutService.startWorkout(workout.id);
    
    if (startResult['success'] == true) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CameraScreen(
            workout: workout,
            exerciseType: exerciseType,
          ),
        ),
      ).then((result) async {
        // Refresh data setelah kembali dari camera screen
        if (result == true) {
          await _loadWorkouts();
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(startResult['message'] ?? 'Gagal memulai workout'),
          backgroundColor: PurplePalette.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: PurplePalette.error,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
  void _showWorkoutActionSheet(BuildContext context, Workout workout) {
    final isPlank = workout.exercises.toLowerCase().contains('plank');
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: PurplePalette.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: PurplePalette.mauve.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(workout.kategori).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getWorkoutIcon(workout),
                    color: _getCategoryColor(workout.kategori),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.namaWorkout,
                        style: const TextStyle(
                          color: PurplePalette.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        workout.kategori,
                        style: TextStyle(
                          color: _getCategoryColor(workout.kategori),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Text(
              workout.deskripsi,
              style: const TextStyle(
                color: PurplePalette.textSecondary,
                fontSize: 14,
              ),
            ),
            
            const SizedBox(height: 16),
            
            _buildDetailRow('Equipment', workout.equipment),
            _buildDetailRow('Status', workout.statusLabel),
            _buildDetailRow('Target', 
              isPlank 
                ? '${_getTargetSets(workout)} set × ${_getTargetReps(workout)} detik'
                : '${_getTargetSets(workout)} set × ${_getTargetReps(workout)} reps'
            ),
            
            if (workout.jadwal != null) ...[
              _buildDetailRow('Waktu', workout.timeDisplay),
              if (workout.jadwal!.durasiWorkout.isNotEmpty)
                _buildDetailRow('Durasi', workout.jadwal!.durasiWorkout),
            ],
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToCameraScreen(workout);
                },
                icon: const Icon(
                  FontAwesomeIcons.camera,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  'Mulai dengan Pose Detection',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PurplePalette.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  shadowColor: PurplePalette.accent.withOpacity(0.5),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showFormGuidelinesDialog(workout);
                },
                icon: const Icon(
                  FontAwesomeIcons.bookOpen,
                  color: PurplePalette.textSecondary,
                  size: 16,
                ),
                label: const Text(
                  'Lihat Panduan Form',
                  style: TextStyle(
                    color: PurplePalette.textSecondary,
                    fontSize: 14,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: PurplePalette.mauve.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Tutup',
                  style: TextStyle(
                    color: PurplePalette.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFormGuidelinesDialog(Workout workout) async {
    final guidelinesResult = await WorkoutService.getWorkoutFormGuidelines(
      workout.exercises,
    );

    if (guidelinesResult['success'] == true && guidelinesResult['data'] != null) {
      final guidelines = guidelinesResult['data'] as Map<String, dynamic>;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: PurplePalette.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Panduan Form ${workout.namaWorkout}',
            style: const TextStyle(
              color: PurplePalette.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PurplePalette.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: PurplePalette.success.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: PurplePalette.success, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'FORM YANG BENAR',
                            style: TextStyle(
                              color: PurplePalette.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        guidelines['correct_form']?.toString() ?? 'Form tidak tersedia',
                        style: const TextStyle(
                          color: PurplePalette.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PurplePalette.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: PurplePalette.warning.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber, color: PurplePalette.warning, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'KESALAHAN UMUM',
                            style: TextStyle(
                              color: PurplePalette.warning,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (guidelines['common_mistakes'] is List)
                        ...(guidelines['common_mistakes'] as List).map((mistake) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.close, color: PurplePalette.error, size: 14),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    mistake.toString(),
                                    style: const TextStyle(
                                      color: PurplePalette.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PurplePalette.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: PurplePalette.info.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb, color: PurplePalette.info, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'TIPS & TRIK',
                            style: TextStyle(
                              color: PurplePalette.info,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (guidelines['tips'] is List)
                        ...(guidelines['tips'] as List).map((tip) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.check, color: PurplePalette.success, size: 14),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    tip.toString(),
                                    style: const TextStyle(
                                      color: PurplePalette.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
                
                if (guidelines['target_angles'] != null) ...[
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PurplePalette.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: PurplePalette.accent.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.sports, color: PurplePalette.accent, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'SUDUT TARGET',
                              style: TextStyle(
                                color: PurplePalette.accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                            ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (guidelines['target_angles'] is Map<String, dynamic>)
                          ...(guidelines['target_angles'] as Map<String, dynamic>).entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _toTitleCase(entry.key.replaceAll('_', ' ')),
                                    style: const TextStyle(
                                      color: PurplePalette.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    entry.value.toString(),
                                    style: const TextStyle(
                                      color: PurplePalette.lavender,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: PurplePalette.textSecondary,
              ),
              child: const Text('Tutup'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToCameraScreen(workout);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PurplePalette.accent,
              ),
              child: const Text(
                'Mulai Workout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: PurplePalette.cardBackground,
          title: const Text(
            'Info',
            style: TextStyle(color: PurplePalette.textPrimary),
          ),
          content: const Text(
            'Panduan form tidak tersedia untuk workout ini.',
            style: TextStyle(color: PurplePalette.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: PurplePalette.accent,
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildWorkoutCard(Workout workout) {
    final statusColor = _getStatusColor(workout);
    final statusIcon = _getStatusIcon(workout);
    final workoutIcon = _getWorkoutIcon(workout);
    final categoryColor = _getCategoryColor(workout.kategori);
    final isPlank = workout.exercises.toLowerCase().contains('plank');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToCameraScreen(workout),
          onLongPress: () => _showWorkoutActionSheet(context, workout),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: PurplePalette.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: PurplePalette.mauve.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: PurplePalette.violet.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              categoryColor.withOpacity(0.3),
                              categoryColor.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: categoryColor.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            workoutIcon,
                            color: categoryColor,
                            size: 22,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'start') {
                            _navigateToCameraScreen(workout);
                          } else if (value == 'guidelines') {
                            _showFormGuidelinesDialog(workout);
                          } else if (value == 'mark_complete') {
                            _markWorkoutAsCompleted(workout);
                          } else if (value == 'reset_status') {
                            _resetWorkoutStatus(workout);
                          }
                        },
                        icon: Icon(
                          Icons.more_vert,
                          color: PurplePalette.textSecondary.withOpacity(0.7),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'start',
                            child: Row(
                              children: [
                                Icon(Icons.play_arrow, color: PurplePalette.accent, size: 20),
                                const SizedBox(width: 8),
                                const Text('Mulai Workout'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'guidelines',
                            child: Row(
                              children: [
                                Icon(Icons.info, color: PurplePalette.info, size: 20),
                                const SizedBox(width: 8),
                                const Text('Panduan Form'),
                              ],
                            ),
                          ),
                          if (workout.isStarted || workout.isCompleted)
                            PopupMenuItem(
                              value: 'reset_status',
                              child: Row(
                                children: [
                                  Icon(Icons.restart_alt, color: PurplePalette.warning, size: 20),
                                  const SizedBox(width: 8),
                                  const Text('Reset Status'),
                                ],
                              ),
                            ),
                          PopupMenuItem(
                            value: 'mark_complete',
                            child: Row(
                              children: [
                                Icon(Icons.check, color: PurplePalette.success, size: 20),
                                const SizedBox(width: 8),
                                const Text('Tandai Selesai'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    workout.namaWorkout,
                    style: const TextStyle(
                      color: PurplePalette.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 6),
                  
                  Text(
                    workout.deskripsi,
                    style: TextStyle(
                      color: PurplePalette.textSecondary.withOpacity(0.8),
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Kategori Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: categoryColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          workout.kategori.isNotEmpty ? workout.kategori : 'General',
                          style: TextStyle(
                            color: categoryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      
                      // Equipment Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: PurplePalette.orchid.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: PurplePalette.orchid.withOpacity(0.3)),
                        ),
                        child: Text(
                          workout.equipment.isNotEmpty ? workout.equipment : 'No Equipment',
                          style: const TextStyle(
                            color: PurplePalette.orchid,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusIcon,
                              color: statusColor,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              workout.statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      // Waktu Jadwal
                      if (workout.jadwal != null) ...[
                        Icon(
                          FontAwesomeIcons.clock,
                          color: PurplePalette.textSecondary.withOpacity(0.7),
                          size: 13,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          workout.timeDisplay,
                          style: TextStyle(
                            color: PurplePalette.textSecondary.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      
                      // Exercise Type
                      Icon(
                        FontAwesomeIcons.dumbbell,
                        color: PurplePalette.textSecondary.withOpacity(0.7),
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          workout.exercisesLabel,
                          style: TextStyle(
                            color: PurplePalette.textSecondary.withOpacity(0.8),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Progress Bar & Target Info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                FontAwesomeIcons.bullseye,
                                color: PurplePalette.lavender,
                                size: 12,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isPlank 
                                  ? '${_getTargetSets(workout)} set × ${_getTargetReps(workout)} detik'
                                  : '${_getTargetSets(workout)} set × ${_getTargetReps(workout)} reps',
                                style: TextStyle(
                                  color: PurplePalette.lavender,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: PurplePalette.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  FontAwesomeIcons.camera,
                                  color: PurplePalette.orchid,
                                  size: 10,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  workout.isCompleted ? 'Selesai' : 'Tap untuk mulai',
                                  style: TextStyle(
                                    color: workout.isCompleted ? PurplePalette.success : PurplePalette.orchid,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      if (workout.isStarted || workout.isCompleted) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: workout.isCompleted ? 1.0 : 0.5,
                          backgroundColor: PurplePalette.background,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            workout.isCompleted ? PurplePalette.success : PurplePalette.warning,
                          ),
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _markWorkoutAsCompleted(Workout workout) async {
    try {
      final result = await WorkoutService.completeWorkout(workout.id);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${workout.namaWorkout} berhasil ditandai selesai'),
            backgroundColor: PurplePalette.success,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        _loadWorkouts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal menandai workout'),
            backgroundColor: PurplePalette.error,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: PurplePalette.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _resetWorkoutStatus(Workout workout) async {
    try {
      final result = await WorkoutService.updateWorkoutStatus(
        workoutId: workout.id,
        status: 'belum',
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status ${workout.namaWorkout} berhasil direset'),
            backgroundColor: PurplePalette.info,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        _loadWorkouts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal reset status'),
            backgroundColor: PurplePalette.error,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: PurplePalette.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: PurplePalette.orchid,
              backgroundColor: PurplePalette.background,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Memuat data workout...',
            style: TextStyle(
              color: PurplePalette.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Menggunakan pose detection AI',
            style: TextStyle(
              color: PurplePalette.lavender,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.exclamationTriangle,
              color: PurplePalette.error,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              'Oops!',
              style: TextStyle(
                color: PurplePalette.error,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              style: const TextStyle(
                color: PurplePalette.textPrimary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadWorkouts,
              style: ElevatedButton.styleFrom(
                backgroundColor: PurplePalette.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                shadowColor: PurplePalette.accent.withOpacity(0.5),
              ),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.dumbbell,
              color: PurplePalette.lilac,
              size: 72,
            ),
            const SizedBox(height: 24),
            const Text(
              'Tidak ada workout hari ini',
              style: TextStyle(
                color: PurplePalette.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Lihat jadwal workout untuk menambahkan kegiatan\natau refresh untuk memuat ulang data',
              style: TextStyle(
                color: PurplePalette.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadWorkouts,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Refresh Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PurplePalette.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: PurplePalette.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PurplePalette.mauve.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: PurplePalette.textSecondary.withOpacity(0.7),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: const TextStyle(
                color: PurplePalette.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Cari workout...',
                hintStyle: TextStyle(
                  color: PurplePalette.textSecondary.withOpacity(0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              cursorColor: PurplePalette.accent,
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                });
              },
              icon: Icon(
                Icons.clear,
                color: PurplePalette.textSecondary.withOpacity(0.7),
                size: 18,
              ),
              splashRadius: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategory == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = index),
            child: Container(
              margin: EdgeInsets.only(
                right: index < _categories.length - 1 ? 10 : 0,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          _categoryColors[index].withOpacity(0.8),
                          _categoryColors[index],
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : PurplePalette.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? _categoryColors[index]
                      : PurplePalette.mauve.withOpacity(0.5),
                  width: isSelected ? 0 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _categoryColors[index].withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  _categories[index],
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : PurplePalette.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Workout Plan",
                    style: TextStyle(
                      color: PurplePalette.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _workoutResponse?.dateFormatted ?? 'Loading...',
                    style: TextStyle(
                      color: PurplePalette.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              if (_workoutResponse != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        PurplePalette.wildberry.withOpacity(0.8),
                        PurplePalette.wildberry,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: PurplePalette.wildberry.withOpacity(0.3),
                        blurRadius: 6,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.camera,
                        color: PurplePalette.lavender,
                        size: 12,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${_workoutResponse!.workouts.length} workout",
                        style: const TextStyle(
                          color: PurplePalette.lavender,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredWorkouts = _getFilteredWorkouts();

    return Scaffold(
      backgroundColor: PurplePalette.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            
            _buildSearchBar(),
            
            const SizedBox(height: 8),
            
            _buildCategoryChips(),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage.isNotEmpty
                      ? _buildErrorState()
                      : filteredWorkouts.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _loadWorkouts,
                              color: PurplePalette.accent,
                              backgroundColor: PurplePalette.background,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                itemCount: filteredWorkouts.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == filteredWorkouts.length) {
                                    return const SizedBox(height: 80);
                                  }
                                  return _buildWorkoutCard(filteredWorkouts[index]);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final statsResult = await WorkoutService.getWorkoutStatistics();
          if (statsResult['success'] == true && statsResult['data'] != null) {
            _showAnalyticsDialog(statsResult['data']);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(statsResult['message'] ?? 'Gagal memuat analytics'),
                backgroundColor: PurplePalette.error,
              ),
            );
          }
        },
        backgroundColor: PurplePalette.accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.analytics, size: 24),
        elevation: 4,
      ),
    );
  }

  void _showAnalyticsDialog(Map<String, dynamic>? analyticsData) {
    if (analyticsData == null && _workoutResponse == null) return;

    // Gunakan getStatistics() dari WorkoutResponse
    final statistics = _workoutResponse?.getStatistics() ?? 
      {'completed': 0, 'in_progress': 0, 'not_started': 0, 'total': 0};
    final progressPercentage = (_workoutResponse?.progressPercentage ?? 0.0) * 100;
    final nextWorkout = _workoutResponse?.nextWorkout;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PurplePalette.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Workout Analytics',
          style: TextStyle(
            color: PurplePalette.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (analyticsData != null && analyticsData.isNotEmpty) ...[
                const Text(
                  'Statistik Mingguan:',
                  style: TextStyle(
                    color: PurplePalette.lavender,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                if (analyticsData['weekly_total'] != null)
                  _buildStatItem('Total Minggu Ini', analyticsData['weekly_total'].toString(), PurplePalette.accent),
                if (analyticsData['weekly_completed'] != null)
                  _buildStatItem('Selesai Minggu Ini', analyticsData['weekly_completed'].toString(), PurplePalette.success),
                if (analyticsData['completion_rate'] != null)
                  _buildStatItem('Tingkat Penyelesaian', '${analyticsData['completion_rate']}%', PurplePalette.info),
                const SizedBox(height: 20),
              ],
              
              const Text(
                'Statistik Hari Ini:',
                style: TextStyle(
                  color: PurplePalette.lavender,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              _buildStatItem('Selesai', statistics['completed'].toString(), PurplePalette.success),
              _buildStatItem('Sedang Dilakukan', statistics['in_progress'].toString(), PurplePalette.warning),
              _buildStatItem('Belum Dimulai', statistics['not_started'].toString(), PurplePalette.textSecondary),
              _buildStatItem('Total Workout', statistics['total'].toString(), PurplePalette.accent),
              
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progress Hari Ini:',
                    style: TextStyle(
                      color: PurplePalette.lavender,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${progressPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: PurplePalette.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progressPercentage / 100,
                backgroundColor: PurplePalette.background,
                valueColor: AlwaysStoppedAnimation<Color>(PurplePalette.accent),
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),
              
              if (nextWorkout != null) ...[
                const SizedBox(height: 20),
                const Text(
                  'Workout Berikutnya:',
                  style: TextStyle(
                    color: PurplePalette.lavender,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PurplePalette.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: PurplePalette.mauve.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(nextWorkout.kategori).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(
                            _getWorkoutIcon(nextWorkout),
                            color: _getCategoryColor(nextWorkout.kategori),
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nextWorkout.namaWorkout,
                              style: const TextStyle(
                                color: PurplePalette.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nextWorkout.timeDisplay,
                              style: const TextStyle(
                                color: PurplePalette.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              const Divider(color: PurplePalette.mauve),
              const SizedBox(height: 12),
              const Text(
                'Pose Detection Features:',
                style: TextStyle(
                  color: PurplePalette.lavender,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              _buildFeatureItem('✅ Real-time form feedback'),
              _buildFeatureItem('✅ AI-powered rep counting'),
              _buildFeatureItem('✅ Multi-exercise support'),
              _buildFeatureItem('✅ TTS voice guidance'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: PurplePalette.textSecondary,
            ),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to history page
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PurplePalette.accent,
            ),
            child: const Text(
              'Lihat History',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: PurplePalette.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      )
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            color: PurplePalette.success,
            size: 8,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: PurplePalette.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      )
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: PurplePalette.textSecondary.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: PurplePalette.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      )
    );
  }
}

// Helper function untuk konversi string ke title case
String _toTitleCase(String text) {
  if (text.isEmpty) return text;
  return text.split(' ')
      .map((word) => word.isNotEmpty 
          ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' 
          : '')
      .join(' ');
}