import 'package:flutter/material.dart';
import 'package:flutter_application_1/service/jadwal_workout_services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

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

  // Category colors
  static const Color muscleColor =
      Color(0xFF4FC3F7); // Biru untuk muscle building
  static const Color cardioColor = Color(0xFFEF5350); // Merah untuk cardio
  static const Color yogaColor =
      Color(0xFF66BB6A); // Hijau untuk yoga/flexibility
  static const Color hiitColor = Color(0xFFFF9800); // Orange untuk HIIT
  static const Color defaultColor = Color(0xFFBD93D3); // Ungu default
}

class PenjadwalanPage extends StatefulWidget {
  const PenjadwalanPage({super.key});

  @override
  State<PenjadwalanPage> createState() => _PenjadwalanPageState();
}

class _PenjadwalanPageState extends State<PenjadwalanPage> {
  int _selectedFilter = 0; // 0: Semua, 1: Muscle, 2: Cardio, 3: Yoga
  final List<String> filterNames = ["Semua", "Muscle", "Cardio", "Yoga"];
  final List<Color> filterColors = [
    PurplePalette.accent,
    PurplePalette.muscleColor,
    PurplePalette.cardioColor,
    PurplePalette.yogaColor,
  ];

  // State untuk data
  JadwalWorkoutResponse? _jadwalResponse;
  Map<String, List<JadwalWorkout>> _jadwalByTime = {
    'Pagi': [],
    'Siang': [],
    'Sore': [],
    'Malam': [],
  };
  bool _isLoading = true;
  String _errorMessage = '';
  String _currentDate = '';

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('EEEE, dd MMM yyyy').format(DateTime.now());
    _loadJadwal();
  }

  Future<void> _loadJadwal() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final result = await JadwalWorkoutService.getTodayJadwalWithRetry();

    if (result['success'] == true && result['data'] != null) {
      setState(() {
        _jadwalResponse = result['data'];
        _jadwalByTime = _jadwalResponse?.getGroupedByTime() ?? _jadwalByTime;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Gagal memuat jadwal workout';
        _isLoading = false;
      });
    }
  }

  List<JadwalWorkout> _getFilteredJadwal() {
    if (_jadwalResponse == null) return [];

    if (_selectedFilter == 0) {
      return _jadwalResponse!.jadwals;
    } else {
      String filterCategory = '';
      switch (_selectedFilter) {
        case 1:
          filterCategory = 'Muscle Building';
          break;
        case 2:
          filterCategory = 'Cardio';
          break;
        case 3:
          filterCategory = 'Flexibility';
          break;
      }

      return _jadwalResponse!.jadwals
          .where((jadwal) => jadwal.kategoriJadwal
              .toLowerCase()
              .contains(filterCategory.toLowerCase()))
          .toList();
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: PurplePalette.orchid,
          ),
          SizedBox(height: 20),
          Text(
            'Memuat jadwal workout...',
            style: TextStyle(
              color: PurplePalette.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            FontAwesomeIcons.exclamationTriangle,
            color: PurplePalette.error,
            size: 64,
          ),
          const SizedBox(height: 20),
          Text(
            _errorMessage,
            style: const TextStyle(
              color: PurplePalette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadJadwal,
            style: ElevatedButton.styleFrom(
              backgroundColor: PurplePalette.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text(
              'Coba Lagi',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            FontAwesomeIcons.calendarPlus,
            color: PurplePalette.lilac,
            size: 64,
          ),
          const SizedBox(height: 20),
          const Text(
            'Tidak ada jadwal workout hari ini',
            style: TextStyle(
              color: PurplePalette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
  
        ],
      ),
    );
  }

  Widget _buildTimeSection(String time, List<JadwalWorkout> jadwals) {
    if (jadwals.isEmpty) return Container();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            time,
            style: const TextStyle(
              color: PurplePalette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...jadwals.map((jadwal) => _buildWorkoutCard(jadwal)),
      ],
    );
  }

  Widget _buildWorkoutCard(JadwalWorkout jadwal) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  PurplePalette.orchid.withOpacity(0.3),
                  PurplePalette.lavender.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: PurplePalette.orchid.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.fitness_center,
                color: PurplePalette.orchid,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        jadwal.namaJadwal,
                        style: const TextStyle(
                          color: PurplePalette.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // TODO: Navigate to workout detail
                      },
                      icon: const Icon(
                        FontAwesomeIcons.chevronRight,
                        color: PurplePalette.textSecondary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            PurplePalette.orchid.withOpacity(0.3),
                            PurplePalette.lavender.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: PurplePalette.orchid.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        jadwal.kategoriJadwal,
                        // ignore: prefer_const_constructors
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          FontAwesomeIcons.clock,
                          color: PurplePalette.textSecondary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          jadwal.formattedTime,
                          style: const TextStyle(
                            color: PurplePalette.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "•",
                          style: TextStyle(
                            color: PurplePalette.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          jadwal.durasiWorkout,
                          style: const TextStyle(
                            color: PurplePalette.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PurplePalette.background,
      appBar: AppBar(
        backgroundColor: PurplePalette.background,
        elevation: 0,
        title: const Text(
          "Jadwal Workout",
          style: TextStyle(
            color: PurplePalette.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadJadwal,
            icon: const Icon(
              Icons.refresh,
              color: PurplePalette.lavender,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            /// ================= FILTER BUTTONS =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: filterNames.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilter = index),
                      child: Container(
                        margin: EdgeInsets.only(
                          right: index < filterNames.length - 1 ? 8 : 0,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: _selectedFilter == index
                              ? LinearGradient(
                                  colors: [
                                    filterColors[index].withOpacity(0.8),
                                    filterColors[index],
                                  ],
                                )
                              : null,
                          color: _selectedFilter == index
                              ? null
                              : PurplePalette.cardBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _selectedFilter == index
                                ? filterColors[index]
                                : PurplePalette.mauve.withOpacity(0.5),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            filterNames[index],
                            style: TextStyle(
                              color: _selectedFilter == index
                                  ? PurplePalette.textPrimary
                                  : PurplePalette.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            /// ================= DATE HEADER =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentDate,
                        style: const TextStyle(
                          color: PurplePalette.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Hari ini",
                        style: TextStyle(
                          color: PurplePalette.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: PurplePalette.wildberry.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: PurplePalette.wildberry,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          FontAwesomeIcons.dumbbell,
                          color: PurplePalette.lavender,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _jadwalResponse != null
                              ? "${_jadwalResponse!.total} Workouts"
                              : "0 Workouts",
                          style: const TextStyle(
                            color: PurplePalette.lavender,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// ================= WORKOUT LIST =================
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage.isNotEmpty
                      ? _buildErrorState()
                      : _jadwalResponse == null ||
                              _jadwalResponse!.jadwals.isEmpty
                          ? _buildEmptyState()
                          : SingleChildScrollView(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                children: [
                                  if (_selectedFilter == 0)
                                    ..._jadwalByTime.entries.map((entry) {
                                      if (entry.value.isNotEmpty) {
                                        return _buildTimeSection(
                                            entry.key, entry.value);
                                      }
                                      return Container();
                                    }).toList()
                                  else
                                    ..._getFilteredJadwal().map(
                                        (jadwal) => _buildWorkoutCard(jadwal)),
                                  const SizedBox(height: 80),
                                ],
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
