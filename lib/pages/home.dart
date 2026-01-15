import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_application_1/service/auth_services.dart';
import 'package:flutter_application_1/service/workout_services.dart';
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
  // State untuk data user
  Map<String, dynamic>? _userData;
  bool _isLoadingUser = true;
  String _userErrorMessage = '';

  // State untuk data workout
  List<Workout> _workoutChallenges = []; // Workout dengan status "belum"
  List<Workout> _completedWorkouts = []; // Workout dengan status "selesai"
  bool _isLoadingWorkouts = true;
  String _workoutErrorMessage = '';

  // State untuk statistics
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

  // Method untuk memuat semua data
  Future<void> _loadAllData() async {
    await Future.wait([
      _loadUserData(),
      _loadWorkoutData(),
    ]);
  }

  // Method untuk memuat data user
  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoadingUser = true;
        _userErrorMessage = '';
      });

      // Coba ambil dari cache/local storage terlebih dahulu
      final cachedUserData = await SessionManager.getUserData();
      if (cachedUserData != null) {
        setState(() {
          _userData = cachedUserData;
          _isLoadingUser = false;
        });

        // Update nameNotifier untuk widget lain
        nameNotifier.value = _userData?['nama_lengkap'] ?? 'User';
      }

      // Kemudian fetch fresh data dari API
      final result = await AuthService.getProfile();

      if (result['success'] == true) {
        setState(() {
          _userData = result['data']['pengguna'];
          _isLoadingUser = false;
        });

        // Update nameNotifier untuk widget lain
        nameNotifier.value = _userData?['nama_lengkap'] ?? 'User';
      } else {
        // Jika gagal fetch dari API, tetap gunakan data cache
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

  // Method untuk memuat data workout
  Future<void> _loadWorkoutData() async {
    try {
      setState(() {
        _isLoadingWorkouts = true;
        _workoutErrorMessage = '';
      });

      // Ambil data workout challenges (belum dimulai)
      final challengesResult =
          await WorkoutService.getWorkoutChallengesWithRetry();

      // Ambil data workout history (sudah selesai)
      final historyResult = await WorkoutService.getWorkoutHistoryWithRetry();

      // Ambil data statistics
      final statsResult = await WorkoutService.getWorkoutStatistics();

      if (challengesResult['success'] == true) {
        setState(() {
          _workoutChallenges = challengesResult['data'] ?? [];
        });
      } else {
        setState(() {
          _workoutErrorMessage =
              challengesResult['message'] ?? 'Gagal memuat workout challenges';
        });
      }

      if (historyResult['success'] == true) {
        setState(() {
          _completedWorkouts = historyResult['data'] ?? [];
        });
      } else if (_workoutErrorMessage.isEmpty) {
        setState(() {
          _workoutErrorMessage =
              historyResult['message'] ?? 'Gagal memuat workout history';
        });
      }

      if (statsResult['success'] == true) {
        setState(() {
          _workoutStats = statsResult['data'] ?? _workoutStats;
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

  // Method untuk refresh semua data
  Future<void> _refreshData() async {
    await _loadAllData();
  }

  // Method untuk memulai workout
  Future<void> _startWorkout(Workout workout) async {
    final result = await WorkoutService.startWorkout(workout.id);

    if (result['success'] == true) {
      // Refresh data workout setelah berhasil memulai
      await _loadWorkoutData();

      // Tampilkan snackbar sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Memulai ${workout.namaWorkout}'),
          backgroundColor: PurplePalette.success,
        ),
      );

      // TODO: Navigate to workout detail page
    } else {
      // Tampilkan error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal memulai workout'),
          backgroundColor: PurplePalette.error,
        ),
      );
    }
  }

  // Method untuk melihat detail workout
  void _viewWorkoutDetail(Workout workout) {
    // TODO: Implement workout detail page navigation
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: PurplePalette.cardBackground,
          title: Text(
            workout.namaWorkout,
            style: const TextStyle(
              color: PurplePalette.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                workout.deskripsi,
                style: const TextStyle(
                  color: PurplePalette.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildDetailItem(
                      Icons.fitness_center, workout.formattedExercises),
                  const SizedBox(width: 12),
                  _buildDetailItem(Icons.timer, workout.formattedDuration),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Equipment: ${workout.equipment}',
                style: const TextStyle(
                  color: PurplePalette.textSecondary,
                  fontSize: 12,
                ),
              ),
              if (workout.jadwal != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Jadwal: ${workout.jadwal!.namaJadwal} (${workout.jadwal!.formattedTime})',
                  style: const TextStyle(
                    color: PurplePalette.lavender,
                    fontSize: 12,
                  ),
                ),
              ],
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
            if (workout.isNotStarted)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startWorkout(workout);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: PurplePalette.accent,
                ),
                child: const Text('Mulai Workout'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: PurplePalette.textSecondary,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: PurplePalette.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // Getter untuk mendapatkan URL foto profile
  String get _profilePhotoUrl {
    if (_userData?['foto_profile_url'] != null) {
      return _userData!['foto_profile_url'];
    }
    if (_userData?['foto_profile'] != null) {
      return 'http://192.168.18.58:8000/profile/${_userData!['foto_profile']}';
    }
    return 'https://i.pinimg.com/474x/07/c4/72/07c4720d19a9e9edad9d0e939eca304a.jpg';
  }

  // Getter untuk nama user
  String get _userName {
    if (_isLoadingUser) return 'Loading...';
    if (_userData?['nama_lengkap'] != null) {
      return _userData!['nama_lengkap'];
    }
    return 'User';
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

  Widget _buildChallengeCard(Workout workout) {
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
            // Gradient Overlay
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
                  workout.categoryDisplay,
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
                    workout.namaWorkout,
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
                    workout.deskripsi,
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
                        workout.formattedDuration,
                      ),
                      const SizedBox(width: 16),
                      _buildChallengeInfo(
                        Icons.fitness_center,
                        workout.formattedExercises,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: PurplePalette.orchid.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: PurplePalette.orchid.withOpacity(0.4),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.fitness_center,
                    color: PurplePalette.orchid,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildWorkoutHistoryCard(Workout workout) {
    final statusColor = Color(workout.statusColorCode);

    return GestureDetector(
      onTap: () => _viewWorkoutDetail(workout),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    Color(workout.workoutColor).withOpacity(0.3),
                    Color(workout.workoutColor).withOpacity(0.1),
                  ],
                ),
                border: Border.all(
                  color: Color(workout.workoutColor).withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  workout.workoutIcon,
                  color: Color(workout.workoutColor),
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
                        workout.namaWorkout,
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
                          workout.statusText.toUpperCase(),
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
                  if (workout.jadwal != null)
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
                        workout.jadwal!.kategoriJadwal,
                        style: const TextStyle(
                          color: PurplePalette.lavender,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildWorkoutDetail(
                        Icons.timer,
                        workout.formattedDuration,
                      ),
                      const SizedBox(width: 16),
                      _buildWorkoutDetail(
                        Icons.fitness_center,
                        workout.formattedExercises,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () => _viewWorkoutDetail(workout),
              icon: const Icon(
                FontAwesomeIcons.chevronRight,
                color: PurplePalette.textSecondary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildWorkoutDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: PurplePalette.textSecondary,
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: PurplePalette.textSecondary,
            fontSize: 14,
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
          onRefresh: _refreshData,
          color: PurplePalette.accent,
          backgroundColor: PurplePalette.background,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                /// ================= HEADER =================
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Foto Profile dengan loading state
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
                              : GestureDetector(
                                  onTap: () {
                                    // Tampilkan dialog info user
                                    _showUserInfo();
                                  },
                                  child: CircleAvatar(
                                    radius: 26,
                                    backgroundColor:
                                        PurplePalette.cardBackground,
                                    backgroundImage:
                                        _userData?['foto_profile'] != null
                                            ? NetworkImage(_profilePhotoUrl)
                                            : const NetworkImage(
                                                "https://i.pinimg.com/474x/07/c4/72/07c4720d19a9e9edad9d0e939eca304a.jpg",
                                              ) as ImageProvider,
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
                                        "Hi, $_userName",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: PurplePalette.textPrimary,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    FontAwesomeIcons.hands,
                                    color: PurplePalette.accent,
                                    size: 20,
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

                /// ================= ERROR MESSAGES =================
                if (_userErrorMessage.isNotEmpty)
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          FontAwesomeIcons.exclamationTriangle,
                          color: Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _userErrorMessage,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _userErrorMessage = '';
                            });
                          },
                          icon: const Icon(
                            FontAwesomeIcons.times,
                            color: Colors.red,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_workoutErrorMessage.isNotEmpty)
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          FontAwesomeIcons.exclamationTriangle,
                          color: Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _workoutErrorMessage,
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _loadWorkoutData,
                          icon: const Icon(
                            FontAwesomeIcons.redo,
                            color: Colors.orange,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                /// ================= DAILY CHALLENGE =================
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Workout Challenge",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: PurplePalette.textPrimary,
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                /// ================= CHALLENGE CAROUSEL =================
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
                                final workout = _workoutChallenges[index];
                                return _buildChallengeCard(workout);
                              },
                            ),
                ),
                const SizedBox(height: 14),

                /// ================= USER STATS =================
                if (_userData != null && !_isLoadingUser)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
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
                              Text(
                                'Status: ${_userData!['bmi_category'] ?? 'Normal'}',
                                style: const TextStyle(
                                  color: PurplePalette.lavender,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (_userData?['jenis_kelamin'] != null)
                            Container(
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
                                _userData!['jenis_kelamin'] == 'L'
                                    ? 'Laki-laki'
                                    : 'Perempuan',
                                style: const TextStyle(
                                  color: PurplePalette.lavender,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                /// ================= COMPLETED WORKOUTS =================
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _isLoadingWorkouts
                      ? _buildLoadingIndicator()
                      : _completedWorkouts.isEmpty
                          ? _buildEmptyState(
                              'Tidak Ada Riwayat Hari Ini',
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

  // Method untuk menampilkan dialog info user
  void _showUserInfo() {
    if (_userData == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: PurplePalette.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Foto Profile
                CircleAvatar(
                  radius: 50,
                  backgroundColor: PurplePalette.background,
                  backgroundImage: _userData?['foto_profile'] != null
                      ? NetworkImage(_profilePhotoUrl)
                      : const NetworkImage(
                          "https://i.pinimg.com/474x/07/c4/72/07c4720d19a9e9edad9d0e939eca304a.jpg",
                        ) as ImageProvider,
                ),
                const SizedBox(height: 16),

                // Nama Lengkap
                Text(
                  _userData!['nama_lengkap'],
                  style: const TextStyle(
                    color: PurplePalette.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Email
                Text(
                  _userData!['email'],
                  style: const TextStyle(
                    color: PurplePalette.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),

                // Info Tambahan
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildUserInfoItem('BMI',
                        '${_userData!['bmi']?.toStringAsFixed(1) ?? '-'}'),
                    _buildUserInfoItem('Gender',
                        _userData!['jenis_kelamin'] == 'L' ? 'Male' : 'Female'),
                    _buildUserInfoItem(
                        'Blood Type', _userData!['golongan_darah'] ?? '-'),
                  ],
                ),
                const SizedBox(height: 20),

                // Today's Workout Stats
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PurplePalette.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildUserInfoItem(
                          'Workouts', '${_workoutStats['total']}'),
                      _buildUserInfoItem(
                          'Completed', '${_workoutStats['completed']}'),
                      _buildUserInfoItem(
                          'Pending', '${_workoutStats['not_started']}'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Button Tutup
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PurplePalette.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(200, 40),
                  ),
                  child: const Text('Tutup'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserInfoItem(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: PurplePalette.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: PurplePalette.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Method untuk membuat floating button chatbot
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
