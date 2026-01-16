import 'package:flutter/material.dart';

class WorkoutResponse {
  final List<Workout> workouts;
  final String date;
  final String dateFormatted;
  final String dayName;
  final int totalJadwals;
  final int totalWorkouts;

  WorkoutResponse({
    required this.workouts,
    required this.date,
    required this.dateFormatted,
    required this.dayName,
    required this.totalJadwals,
    required this.totalWorkouts,
  });

  factory WorkoutResponse.fromJson(Map<String, dynamic> json) {
    final workouts = <Workout>[];
    
    if (json['data'] is List) {
      for (var item in json['data'] as List) {
        try {
          workouts.add(Workout.fromJson(item));
        } catch (e) {
          print('Error parsing workout item: $e');
        }
      }
    }

    return WorkoutResponse(
      workouts: workouts,
      date: json['date']?.toString() ?? '',
      dateFormatted: json['date_formatted']?.toString() ?? '',
      dayName: json['day_name']?.toString() ?? '',
      totalJadwals: (json['total_jadwals'] as int?) ?? 0,
      totalWorkouts: (json['total_workouts'] as int?) ?? 0,
    );
  }

  // Helper method untuk mendapatkan statistics
  Map<String, dynamic> getStatistics() {
    final completed = workouts.where((w) => w.isCompleted).length;
    final inProgress = workouts.where((w) => w.isStarted).length;
    final notStarted = workouts.where((w) => w.isNotStarted).length;
    final total = workouts.length;
    final progressPercentage = total > 0 ? completed / total : 0.0;

    return {
      'completed': completed,
      'in_progress': inProgress,
      'not_started': notStarted,
      'total': total,
      'progress_percentage': progressPercentage,
    };
  }

  // Getter untuk progress percentage
  double get progressPercentage {
    final stats = getStatistics();
    return stats['progress_percentage'] as double;
  }

  // Getter untuk workout berikutnya
  Workout? get nextWorkout {
    try {
      return workouts.firstWhere(
        (w) => w.isNotStarted || w.isStarted,
        orElse: () => workouts.first,
      );
    } catch (e) {
      return null;
    }
  }
}

class Workout {
  final int id;
  final String namaWorkout;
  final String deskripsi;
  final String equipment;
  final String kategori;
  final String exercises;
  final String status;
  final int jadwalWorkoutId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final JadwalInfo? jadwal;

  // PROPERY TAMBAHAN untuk home.dart
  late final int statusColorCode;
  late final int workoutColor;
  late final IconData workoutIcon;
  late final String statusText;
  late final String categoryDisplay;
  late final String formattedExercises;
  late final String formattedDuration;

  Workout({
    required this.id,
    required this.namaWorkout,
    required this.deskripsi,
    required this.equipment,
    required this.kategori,
    required this.exercises,
    required this.status,
    required this.jadwalWorkoutId,
    required this.createdAt,
    required this.updatedAt,
    this.jadwal,
  }) {
    // Initialize computed properties
    statusText = statusLabel;
    statusColorCode = _getStatusColorCode();
    workoutColor = _getWorkoutColorCode();
    workoutIcon = exerciseIcon;
    categoryDisplay = _getCategoryDisplay();
    formattedExercises = exercisesLabel;
    formattedDuration = _getFormattedDuration();
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] ?? 0,
      namaWorkout: json['nama_workout'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      equipment: json['equipment'] ?? '',
      kategori: json['kategori'] ?? '',
      exercises: json['exercises'] ?? '',
      status: json['status'] ?? 'belum',
      jadwalWorkoutId: json['jadwal_workout_id'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      jadwal: json['jadwal'] != null ? JadwalInfo.fromJson(json['jadwal']) : null,
    );
  }

  // Helper properties
  bool get isCompleted => status == 'selesai';
  bool get isStarted => status == 'sedang dilakukan';
  bool get isNotStarted => status == 'belum';

  String get statusLabel {
    switch (status) {
      case 'selesai': return 'Selesai';
      case 'sedang dilakukan': return 'Sedang Dilakukan';
      case 'belum': return 'Belum Dimulai';
      default: return status;
    }
  }

  String get exercisesLabel {
    final ex = exercises.toLowerCase();
    if (ex == 'pushup') return 'Push Up';
    if (ex == 'squat') return 'Squat';
    if (ex == 'shoulder_press') return 'Shoulder Press';
    return exercises.replaceAll('_', ' ').toTitleCase();
  }

  Color get statusColor {
    switch (status) {
      case 'selesai': return Colors.green;
      case 'sedang dilakukan': return Colors.orange;
      case 'belum': return Colors.blueGrey;
      default: return Colors.grey;
    }
  }

  int _getStatusColorCode() {
    switch (status) {
      case 'selesai': return 0xFF4CAF50; // Green
      case 'sedang dilakukan': return 0xFFFF9800; // Orange
      case 'belum': return 0xFF607D8B; // Blue Grey
      default: return 0xFF9E9E9E; // Grey
    }
  }

  IconData get exerciseIcon {
    final ex = exercises.toLowerCase();
    if (ex.contains('push')) return Icons.fitness_center;
    if (ex.contains('squat')) return Icons.directions_walk;
    if (ex.contains('shoulder')) return Icons.arrow_upward;
    if (ex.contains('plank')) return Icons.square;
    if (ex.contains('lunge')) return Icons.directions_run;
    if (ex.contains('sit') || ex.contains('crunch')) return Icons.airline_seat_recline_normal;
    return Icons.sports_gymnastics;
  }

  int _getWorkoutColorCode() {
    final ex = exercises.toLowerCase();
    if (ex.contains('push')) return 0xFF2196F3; // Blue
    if (ex.contains('squat')) return 0xFF4CAF50; // Green
    if (ex.contains('shoulder')) return 0xFFFF9800; // Orange
    if (ex.contains('plank')) return 0xFF9C27B0; // Purple
    if (ex.contains('lunge')) return 0xFFF44336; // Red
    if (ex.contains('sit') || ex.contains('crunch')) return 0xFF00BCD4; // Cyan
    return 0xFFA32CC4; // Purple accent
  }

  Color get categoryColor {
    final k = kategori.toLowerCase();
    if (k.contains('calisthenics')) return Colors.blue;
    if (k.contains('strength')) return Colors.green;
    if (k.contains('muscle')) return Colors.red;
    if (k.contains('cardio')) return Colors.orange;
    if (k.contains('flexibility')) return Colors.purple;
    return Colors.purple;
  }

  String _getCategoryDisplay() {
    final k = kategori.toLowerCase();
    if (k.contains('calisthenics')) return 'Calisthenics';
    if (k.contains('strength')) return 'Strength';
    if (k.contains('muscle')) return 'Muscle Building';
    if (k.contains('cardio')) return 'Cardio';
    if (k.contains('flexibility')) return 'Flexibility';
    return 'General';
  }

  String get timeDisplay => jadwal?.jamFormatted ?? '--:--';

  String _getFormattedDuration() {
    // Contoh: Jika deskripsi mengandung durasi, ekstrak
    final desc = deskripsi.toLowerCase();
    if (desc.contains('menit')) {
      final regex = RegExp(r'(\d+)\s*menit');
      final match = regex.firstMatch(desc);
      if (match != null) {
        return '${match.group(1)} min';
      }
    }
    
    // Default berdasarkan jenis exercise
    final ex = exercises.toLowerCase();
    if (ex.contains('plank')) return 'Hold';
    if (ex.contains('push')) return '15-20 min';
    if (ex.contains('squat')) return '10-15 min';
    return '10-20 min';
  }
}

class JadwalInfo {
  final int id;
  final String namaJadwal;
  final String kategoriJadwal;
  final DateTime tanggal;
  final String tanggalFormatted;
  final String jam;
  final String jamFormatted;
  final String durasiWorkout;

  JadwalInfo({
    required this.id,
    required this.namaJadwal,
    required this.kategoriJadwal,
    required this.tanggal,
    required this.tanggalFormatted,
    required this.jam,
    required this.jamFormatted,
    required this.durasiWorkout,
  });

  factory JadwalInfo.fromJson(Map<String, dynamic> json) {
    return JadwalInfo(
      id: json['id'] ?? 0,
      namaJadwal: json['nama_jadwal'] ?? '',
      kategoriJadwal: json['kategori_jadwal'] ?? '',
      tanggal: DateTime.parse(json['tanggal'] ?? DateTime.now().toIso8601String()),
      tanggalFormatted: json['tanggal_formatted'] ?? '',
      jam: json['jam'] ?? '00:00',
      jamFormatted: json['jam_formatted'] ?? '00:00',
      durasiWorkout: json['durasi_workout'] ?? '0 menit',
    );
  }

  // Helper untuk home.dart
  String get formattedTime => '$jamFormatted ($durasiWorkout)';
}

// Extension untuk konversi string
extension StringExtensions on String {
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' 
            : '')
        .join(' ');
  }
}