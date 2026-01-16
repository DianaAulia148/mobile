import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_application_1/service/auth_services.dart';
import 'package:flutter_application_1/service/workout_service.dart';
import 'package:flutter_application_1/utils/session_manager.dart';
import 'package:flutter_application_1/pages/chatbot_screens.dart';

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
}

/// ================= THEME CONTROLLER =================
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

/// ================= PROFILE NAME =================
final ValueNotifier<String> nameNotifier = ValueNotifier("User");

class HomePage extends StatefulWidget {
  final double bmi;
  const HomePage({super.key, required this.bmi});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _userData;
  bool _isLoadingUser = true;
  String _userErrorMessage = '';

  // State untuk data workout
  List<dynamic> _workoutChallenges = []; // Ubah ke dynamic untuk fleksibilitas
  List<dynamic> _completedWorkouts = [];
  bool _isLoadingWorkouts = true;
  String _workoutErrorMessage = '';

  Map<String, dynamic> _workoutStats = {
    'completed': 0,
    'in_progress': 0,
    'not_started': 0,
    'total': 0,
    'progress_percentage': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadUserData(),
      _loadWorkoutData(),
    ]);
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoadingUser = true;
        _userErrorMessage = '';
      });

      final cachedUserData = await SessionManager.getUserData();
      if (cachedUserData != null) {
        setState(() {
          _userData = cachedUserData;
          _isLoadingUser = false;
        });
        nameNotifier.value = _userData?['nama_lengkap'] ?? 'User';
      }

      final result = await AuthService.getProfile();

      if (result['success'] == true) {
        setState(() {
          _userData = result['data']['pengguna'];
          _isLoadingUser = false;
        });
        nameNotifier.value = _userData?['nama_lengkap'] ?? 'User';
      } else {
        if (_userData == null) {
          setState(() {
            _userErrorMessage = result['message'] ?? 'Gagal memuat data user';
            _isLoadingUser = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _userErrorMessage = 'Terjadi kesalahan: $e';
        _isLoadingUser = false;
      });
    }
  }

  Future<void> _loadWorkoutData() async {
    try {
      setState(() {
        _isLoadingWorkouts = true;
        _workoutErrorMessage = '';
      });

      // Panggil API workout untuk hari ini
      final todayWorkoutsResult = await WorkoutService.getTodayWorkoutsWithRetry();

      if (todayWorkoutsResult['success'] == true) {
        final workoutResponse = todayWorkoutsResult['data'] as WorkoutResponse;
        
        // Filter workouts berdasarkan status
        setState(() {
          _workoutChallenges = workoutResponse.workouts
              .where((workout) => workout.status == 'belum')
              .toList();
          
          _completedWorkouts = workoutResponse.workouts
              .where((workout) => workout.status == 'selesai')
              .toList();
          
          // Hitung statistik
          _workoutStats = {
            'total': workoutResponse.workouts.length,
            'completed': _completedWorkouts.length,
            'in_progress': workoutResponse.workouts
                .where((workout) => workout.status == 'sedang dilakukan')
                .length,
            'not_started': _workoutChallenges.length,
            'progress_percentage': _completedWorkouts.length / workoutResponse.workouts.length,
          };
        });
      } else {
        setState(() {
          _workoutErrorMessage = todayWorkoutsResult['message'] ?? 'Gagal memuat data workout';
        });
      }

      setState(() {
        _isLoadingWorkouts = false;
      });
    } catch (e) {
      setState(() {
        _workoutErrorMessage = 'Terjadi kesalahan: $e';
        _isLoadingWorkouts = false;
      });
    }
  }

  // Helper method untuk mendapatkan data workout
  String _getWorkoutProperty(dynamic workout, String property) {
    if (workout is Workout) {
      switch (property) {
        case 'nama_workout':
          return workout.namaWorkout;
        case 'deskripsi':
          return workout.deskripsi;
        case 'equipment':
          return workout.equipment;
        case 'kategori':
          return workout.kategori;
        case 'exercises':
          return workout.exercises;
        case 'status':
          return workout.status;
        default:
          return '';
      }
    } else if (workout is Map<String, dynamic>) {
      return workout[property]?.toString() ?? '';
    }
    return '';
  }

  Widget _buildChallengeCard(dynamic workout) {
    final workoutName = _getWorkoutProperty(workout, 'nama_workout');
    final description = _getWorkoutProperty(workout, 'deskripsi');
    final category = _getWorkoutProperty(workout, 'kategori');

    return GestureDetector(
      onTap: () => _viewWorkoutDetail(workout),
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: PurplePalette.cardBackground,
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              PurplePalette.eggplant.withOpacity(0.3),
              PurplePalette.violet.withOpacity(0.3),
            ],
          ),
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    PurplePalette.background.withOpacity(0.8),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: PurplePalette.orchid.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: PurplePalette.orchid.withOpacity(0.4),
                  ),
                ),
                child: Text(
                  category.isNotEmpty ? category : 'General',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workoutName,
                    style: const TextStyle(
                      color: PurplePalette.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: PurplePalette.textSecondary,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildChallengeInfo(
                        Icons.timer,
                        '10 min',
                      ),
                      const SizedBox(width: 16),
                      _buildChallengeInfo(
                        Icons.fitness_center,
                        'Beginner',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutHistoryCard(dynamic workout) {
    final workoutName = _getWorkoutProperty(workout, 'nama_workout');
    final status = _getWorkoutProperty(workout, 'status');
    final category = _getWorkoutProperty(workout, 'kategori');

    Color getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'selesai':
          return Colors.green;
        case 'sedang dilakukan':
          return Colors.orange;
        case 'belum':
          return Colors.blue;
        default:
          return Colors.grey;
      }
    }

    String getStatusText(String status) {
      switch (status.toLowerCase()) {
        case 'selesai':
          return 'SELESAI';
        case 'sedang dilakukan':
          return 'SEDANG DILAKUKAN';
        case 'belum':
          return 'BELUM DIMULAI';
        default:
          return status.toUpperCase();
      }
    }

    IconData getWorkoutIcon(String category) {
      final cat = category.toLowerCase();
      if (cat.contains('push')) return FontAwesomeIcons.handSparkles;
      if (cat.contains('squat')) return FontAwesomeIcons.personWalking;
      if (cat.contains('shoulder')) return FontAwesomeIcons.arrowUp;
      if (cat.contains('yoga')) return FontAwesomeIcons.spa;
      return FontAwesomeIcons.dumbbell;
    }

    Color getWorkoutColor(String category) {
      final cat = category.toLowerCase();
      if (cat.contains('push')) return Colors.blue;
      if (cat.contains('squat')) return Colors.green;
      if (cat.contains('shoulder')) return Colors.orange;
      if (cat.contains('yoga')) return Colors.purple;
      return Colors.grey;
    }

    final statusColor = getStatusColor(status);
    final statusText = getStatusText(status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PurplePalette.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  getWorkoutColor(category).withOpacity(0.3),
                  getWorkoutColor(category).withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: getWorkoutColor(category).withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Center(
              child: Icon(
                getWorkoutIcon(category),
                color: getWorkoutColor(category),
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workoutName,
                      style: const TextStyle(
                        color: PurplePalette.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: statusColor.withOpacity(0.4),
                        ),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (category.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: PurplePalette.wildberry.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: PurplePalette.wildberry,
                      ),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: PurplePalette.lavender,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _viewWorkoutDetail(dynamic workout) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: PurplePalette.cardBackground,
          title: Text(
            _getWorkoutProperty(workout, 'nama_workout'),
            style: const TextStyle(
              color: PurplePalette.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getWorkoutProperty(workout, 'deskripsi'),
                style: const TextStyle(
                  color: PurplePalette.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Equipment: ${_getWorkoutProperty(workout, 'equipment')}',
                style: const TextStyle(
                  color: PurplePalette.textSecondary,
                  fontSize: 14,
                ),
              ),
              Text(
                'Category: ${_getWorkoutProperty(workout, 'kategori')}',
                style: const TextStyle(
                  color: PurplePalette.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Tutup',
                style: TextStyle(color: PurplePalette.textSecondary),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChallengeInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: PurplePalette.lavender,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: PurplePalette.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PurplePalette.background,
      floatingActionButton: _buildChatbotFloatingButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAllData,
          color: PurplePalette.accent,
          backgroundColor: PurplePalette.background,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header section
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _isLoadingUser
                              ? Container(
                                  width: 52,
                                  height: 52,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: PurplePalette.cardBackground,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: PurplePalette.accent,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : CircleAvatar(
                                  radius: 26,
                                  backgroundColor:
                                      PurplePalette.cardBackground,
                                  backgroundImage: const NetworkImage(
                                    "https://i.pinimg.com/474x/07/c4/72/07c4720d19a9e9edad9d0e939eca304a.jpg",
                                  ),
                                ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "WELCOME BACK",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: PurplePalette.textSecondary,
                                ),
                              ),
                              Row(
                                children: [
                                  ValueListenableBuilder<String>(
                                    valueListenable: nameNotifier,
                                    builder: (context, name, child) {
                                      return Text(
                                        "Hi, $name",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: PurplePalette.textPrimary,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Error messages
                if (_userErrorMessage.isNotEmpty)
                  _buildErrorContainer(_userErrorMessage, true),
                if (_workoutErrorMessage.isNotEmpty)
                  _buildErrorContainer(_workoutErrorMessage, false),

                // Daily Challenge section
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        "Workout Challenge",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: PurplePalette.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Challenge carousel
                SizedBox(
                  height: 200,
                  child: _isLoadingWorkouts
                      ? _buildLoadingIndicator()
                      : _workoutChallenges.isEmpty
                          ? _buildEmptyState(
                              'Tidak Ada Workout Hari Ini',
                              'Semua latihan telah selesai atau sedang berlangsung!',
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _workoutChallenges.length,
                              itemBuilder: (context, index) {
                                return _buildChallengeCard(
                                    _workoutChallenges[index]);
                              },
                            ),
                ),

                // User stats section
                if (_userData != null && !_isLoadingUser)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: PurplePalette.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userData!['nama_lengkap'],
                                style: const TextStyle(
                                  color: PurplePalette.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'BMI: ${_userData!['bmi']?.toStringAsFixed(1) ?? widget.bmi.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  color: PurplePalette.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                // Completed workouts section
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        "Workout History",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: PurplePalette.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                // History list
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _isLoadingWorkouts
                      ? _buildLoadingIndicator()
                      : _completedWorkouts.isEmpty
                          ? _buildEmptyState(
                              'Tidak Ada Riwayat',
                              'Selesaikan latihan pertama Anda untuk melihatnya di sini!',
                            )
                          : Column(
                              children: _completedWorkouts
                                  .map((workout) =>
                                      _buildWorkoutHistoryCard(workout))
                                  .toList(),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorContainer(String message, bool isUserError) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isUserError ? Colors.red : Colors.orange).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isUserError ? Colors.red : Colors.orange).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            FontAwesomeIcons.exclamationTriangle,
            color: isUserError ? Colors.red : Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isUserError ? Colors.red : Colors.orange,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              if (isUserError) {
                setState(() {
                  _userErrorMessage = '';
                });
              } else {
                _loadWorkoutData();
              }
            },
            icon: Icon(
              isUserError ? FontAwesomeIcons.times : FontAwesomeIcons.redo,
              color: isUserError ? Colors.red : Colors.orange,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: PurplePalette.orchid,
          ),
          SizedBox(height: 10),
          Text(
            'Memuat...',
            style: TextStyle(
              color: PurplePalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 80),
        const Icon(
          FontAwesomeIcons.dumbbell,
          color: PurplePalette.lilac,
          size: 48,
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            color: PurplePalette.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: const TextStyle(
            color: PurplePalette.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildChatbotFloatingButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, right: 8),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatbotScreens(),
            ),
          );
        },
        backgroundColor: PurplePalette.accent,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                PurplePalette.orchid,
                PurplePalette.accent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: PurplePalette.orchid.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              FontAwesomeIcons.solidMessage,
              size: 24,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}