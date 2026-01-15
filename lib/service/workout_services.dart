import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/service/connect.dart';
import 'package:flutter_application_1/utils/session_manager.dart';

// Model untuk Exercise
class Exercise {
  final int id;
  final String namaExercise;
  final String deskripsi;
  final String equipment;
  final String kategori;
  final int repetitions;
  final int sets;
  final String durasi;
  final String videoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Exercise({
    required this.id,
    required this.namaExercise,
    required this.deskripsi,
    required this.equipment,
    required this.kategori,
    required this.repetitions,
    required this.sets,
    required this.durasi,
    required this.videoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] ?? 0,
      namaExercise: json['nama_exercise'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      equipment: json['equipment'] ?? '',
      kategori: json['kategori'] ?? '',
      repetitions: json['repetitions'] ?? 0,
      sets: json['sets'] ?? 0,
      durasi: json['durasi'] ?? '0 menit',
      videoUrl: json['video_url'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toString()),
    );
  }

  String get formattedSetsReps => '$sets sets × $repetitions reps';
  String get formattedEquipment => equipment.isNotEmpty ? equipment : 'No Equipment';
}

// Model untuk Workout
class Workout {
  final int id;
  final String namaWorkout;
  final String deskripsi;
  final String equipment;
  final String kategori;
  final int exercises;
  final String status;
  final int jadwalWorkoutId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final JadwalInfo? jadwal;

  var idWorkout;

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
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] ?? 0,
      namaWorkout: json['nama_workout'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      equipment: json['equipment'] ?? '',
      kategori: json['kategori'] ?? '',
      exercises: json['exercises'] ?? 0,
      status: json['status'] ?? 'belum',
      jadwalWorkoutId: json['jadwal_workout_id'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toString()),
      jadwal: json['jadwal'] != null ? JadwalInfo.fromJson(json['jadwal']) : null,
    );
  }

  // Helper methods
  bool get isCompleted => status.toLowerCase() == 'selesai';
  bool get isStarted => status.toLowerCase() == 'sedang';
  bool get isNotStarted => status.toLowerCase() == 'belum';

  String get statusText {
    switch (status.toLowerCase()) {
      case 'selesai':
        return 'Completed';
      case 'sedang':
        return 'In Progress';
      case 'belum':
        return 'Not Started';
      default:
        return status;
    }
  }

  String get formattedExercises => '$exercises ${exercises == 1 ? 'exercise' : 'exercises'}';

  // Get workout icon berdasarkan kategori
  IconData get workoutIcon {
    if (kategori.toLowerCase().contains('yoga') || deskripsi.toLowerCase().contains('yoga')) {
      return Icons.self_improvement;
    } else if (kategori.toLowerCase().contains('cardio') || deskripsi.toLowerCase().contains('cardio')) {
      return Icons.directions_run;
    } else if (kategori.toLowerCase().contains('strength') || 
               kategori.toLowerCase().contains('muscle') ||
               namaWorkout.toLowerCase().contains('chest') ||
               namaWorkout.toLowerCase().contains('upper body') ||
               namaWorkout.toLowerCase().contains('strength')) {
      return Icons.fitness_center;
    } else if (kategori.toLowerCase().contains('hiit')) {
      return Icons.flash_on;
    } else if (equipment.toLowerCase().contains('bodyweight') || 
               equipment.toLowerCase().contains('no equipment')) {
      return Icons.accessibility;
    }
    return Icons.sports_gymnastics;
  }

  // Get workout color berdasarkan kategori
  int get workoutColor {
    if (kategori.toLowerCase().contains('yoga') || deskripsi.toLowerCase().contains('yoga')) {
      return 0xFF66BB6A; // Hijau untuk yoga
    } else if (kategori.toLowerCase().contains('cardio') || deskripsi.toLowerCase().contains('cardio')) {
      return 0xFFEF5350; // Merah untuk cardio
    } else if (kategori.toLowerCase().contains('strength') || 
               kategori.toLowerCase().contains('muscle')) {
      return 0xFF4FC3F7; // Biru untuk strength
    } else if (kategori.toLowerCase().contains('hiit')) {
      return 0xFFFF9800; // Orange untuk HIIT
    }
    return 0xFFAF69EE; // Ungu default
  }

  // Get status color
  int get statusColorCode {
    switch (status.toLowerCase()) {
      case 'selesai':
        return 0xFF4CAF50; // Hijau untuk selesai
      case 'sedang':
        return 0xFFFF9800; // Orange untuk sedang
      case 'belum':
        return 0xFFBD93D3; // Ungu untuk belum
      default:
        return 0xFFBD93D3; // Ungu default
    }
  }

  // Format durasi dari jadwal jika ada
  String get formattedDuration {
    if (jadwal != null && jadwal!.durasiWorkout.isNotEmpty) {
      return jadwal!.durasiWorkout;
    }
    return '${exercises * 5} min'; // Estimasi 5 menit per exercise
  }

  // Get category display text
  String get categoryDisplay {
    if (equipment.toLowerCase().contains('no equipment') || 
        equipment.toLowerCase().contains('bodyweight') ||
        equipment.isEmpty) {
      return 'Without Equipment';
    }
    return 'With Equipment';
  }
}

// Model untuk Jadwal Info (embedded dalam Workout)
class JadwalInfo {
  final int id;
  final String namaJadwal;
  final String kategoriJadwal;
  final DateTime tanggal;
  final String jam;
  final String durasiWorkout;

  JadwalInfo({
    required this.id,
    required this.namaJadwal,
    required this.kategoriJadwal,
    required this.tanggal,
    required this.jam,
    required this.durasiWorkout,
  });

  factory JadwalInfo.fromJson(Map<String, dynamic> json) {
    return JadwalInfo(
      id: json['id'] ?? 0,
      namaJadwal: json['nama_jadwal'] ?? '',
      kategoriJadwal: json['kategori_jadwal'] ?? '',
      tanggal: DateTime.parse(json['tanggal'] ?? DateTime.now().toString()),
      jam: json['jam'] ?? '00:00',
      durasiWorkout: json['durasi_workout'] ?? '0 menit',
    );
  }

  String get formattedTime {
    try {
      final timeParts = jam.split(':');
      if (timeParts.length >= 2) {
        final hour = int.parse(timeParts[0]);
        final minute = timeParts[1];
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;
        return '${displayHour.toString().padLeft(2, '0')}:$minute $period';
      }
      return jam;
    } catch (e) {
      return jam;
    }
  }
}

// Model untuk Workout Response
class WorkoutResponse {
  final List<Workout> workouts;
  final String date;
  final int totalJadwals;
  final int totalWorkouts;

  WorkoutResponse({
    required this.workouts,
    required this.date,
    required this.totalJadwals,
    required this.totalWorkouts,
  });

  factory WorkoutResponse.fromJson(Map<String, dynamic> json) {
    List<Workout> workoutList = [];
    
    if (json['data'] != null && json['data'] is List) {
      workoutList = (json['data'] as List)
          .map((item) => Workout.fromJson(item))
          .toList();
    }

    return WorkoutResponse(
      workouts: workoutList,
      date: json['date'] ?? DateTime.now().toString(),
      totalJadwals: json['total_jadwals'] ?? 0,
      totalWorkouts: json['total_workouts'] ?? 0,
    );
  }

  // Method untuk mendapatkan workout yang belum dimulai (untuk slider challenge)
  List<Workout> get notStartedWorkouts {
    return workouts.where((workout) => workout.isNotStarted).toList();
  }

  // Method untuk mendapatkan workout yang sudah selesai (untuk history)
  List<Workout> get completedWorkouts {
    return workouts.where((workout) => workout.isCompleted).toList();
  }

  // Method untuk mendapatkan workout yang sedang berjalan
  List<Workout> get inProgressWorkouts {
    return workouts.where((workout) => workout.isStarted).toList();
  }

  // Method untuk menghitung statistik
  Map<String, int> getStatistics() {
    int completed = completedWorkouts.length;
    int inProgress = inProgressWorkouts.length;
    int notStarted = notStartedWorkouts.length;

    return {
      'completed': completed,
      'in_progress': inProgress,
      'not_started': notStarted,
      'total': workouts.length,
    };
  }

  // Method untuk mendapatkan progress percentage
  double get progressPercentage {
    if (workouts.isEmpty) return 0.0;
    return completedWorkouts.length / workouts.length;
  }

  // Method untuk mendapatkan next workout (yang belum dimulai dengan jadwal terdekat)
  Workout? get nextWorkout {
    if (notStartedWorkouts.isEmpty) return null;
    
    // Urutkan berdasarkan jam jadwal
    final sorted = notStartedWorkouts.where((w) => w.jadwal != null).toList()
      ..sort((a, b) => a.jadwal!.jam.compareTo(b.jadwal!.jam));
    
    return sorted.isNotEmpty ? sorted.first : notStartedWorkouts.first;
  }
}

class WorkoutService {
  // Method utama untuk mengambil data workout hari ini
  static Future<Map<String, dynamic>> getTodayWorkouts() async {
    final token = await SessionManager.getAuthToken();
    
    if (token == null) {
      return {
        'success': false,
        'message': 'Token tidak ditemukan. Silakan login kembali.',
        'data': null,
      };
    }
    
    final url = Uri.parse('$apiConnect/api/workout/today');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['status'] == 'success') {
        final workoutResponse = WorkoutResponse.fromJson(data);
        
        return {
          'success': true,
          'message': data['message'] ?? 'Workout berhasil diambil',
          'data': workoutResponse,
          'rawData': data,
        };
      } else {
        // Jika token tidak valid, clear session
        if (response.statusCode == 401) {
          await SessionManager.clearSession();
        }
        
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil workout',
          'errorCode': response.statusCode,
          'data': null,
        };
      }
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'message': 'Koneksi internet bermasalah: ${e.message}',
        'data': null,
      };
    } on FormatException catch (e) {
      return {
        'success': false,
        'message': 'Format data tidak valid: ${e.message}',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan tak terduga: ${e.toString()}',
        'data': null,
      };
    }
  }

  // Method khusus untuk home page: mendapatkan workout challenge (belum dimulai)
  static Future<Map<String, dynamic>> getWorkoutChallenges() async {
    final result = await getTodayWorkouts();
    
    if (!result['success'] || result['data'] == null) {
      return result;
    }
    
    final WorkoutResponse workoutResponse = result['data'];
    final challenges = workoutResponse.notStartedWorkouts;
    
    return {
      'success': true,
      'message': 'Workout challenges berhasil diambil',
      'data': challenges,
      'total': challenges.length,
    };
  }

  // Method khusus untuk home page: mendapatkan workout history (sudah selesai)
  static Future<Map<String, dynamic>> getWorkoutHistory() async {
    final result = await getTodayWorkouts();
    
    if (!result['success'] || result['data'] == null) {
      return result;
    }
    
    final WorkoutResponse workoutResponse = result['data'];
    final history = workoutResponse.completedWorkouts;
    
    return {
      'success': true,
      'message': 'Workout history berhasil diambil',
      'data': history,
      'total': history.length,
    };
  }

  // Method untuk mendapatkan workout statistics
  static Future<Map<String, dynamic>> getWorkoutStatistics() async {
    final result = await getTodayWorkouts();
    
    if (!result['success'] || result['data'] == null) {
      return result;
    }
    
    final WorkoutResponse workoutResponse = result['data'];
    final statistics = workoutResponse.getStatistics();
    final nextWorkout = workoutResponse.nextWorkout;
    
    return {
      'success': true,
      'message': 'Workout statistics berhasil diambil',
      'data': {
        'statistics': statistics,
        'progress_percentage': workoutResponse.progressPercentage,
        'next_workout': nextWorkout,
        'total_workouts': workoutResponse.totalWorkouts,
        'date': workoutResponse.date,
      },
    };
  }

  // Method untuk update status workout
  static Future<Map<String, dynamic>> updateWorkoutStatus({
    required int workoutId,
    required String status,
  }) async {
    final token = await SessionManager.getAuthToken();
    
    if (token == null) {
      return {
        'success': false,
        'message': 'Token tidak ditemukan. Silakan login kembali.',
        'data': null,
      };
    }
    
    final url = Uri.parse('$apiConnect/api/workout/$workoutId/status');
    
    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'message': data['message'] ?? 'Status workout berhasil diperbarui',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal memperbarui status workout',
          'errorCode': response.statusCode,
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
        'data': null,
      };
    }
  }

  // Method untuk memulai workout
  static Future<Map<String, dynamic>> startWorkout(int workoutId) async {
    return await updateWorkoutStatus(
      workoutId: workoutId,
      status: 'sedang',
    );
  }

  // Method untuk menyelesaikan workout
  static Future<Map<String, dynamic>> completeWorkout(int workoutId) async {
    return await updateWorkoutStatus(
      workoutId: workoutId,
      status: 'selesai',
    );
  }

  // Method untuk refresh token
  static Future<Map<String, dynamic>> refreshToken() async {
    final token = await SessionManager.getAuthToken();
    
    if (token == null) {
      return {
        'success': false,
        'message': 'Token tidak ditemukan',
      };
    }
    
    final url = Uri.parse('$apiConnect/api/refresh-token');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        final newToken = data['data']['token_auth'];
        await SessionManager.setAuthToken(newToken);
        
        return {
          'success': true,
          'message': 'Token berhasil diperbarui',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal memperbarui token',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal memperbarui token: ${e.toString()}',
      };
    }
  }

  // Method untuk menangani error dan retry
  static Future<Map<String, dynamic>> getTodayWorkoutsWithRetry({
    int maxRetries = 3,
    int delayInSeconds = 2,
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      final result = await getTodayWorkouts();
      
      if (result['success'] == true) {
        return result;
      }
      
      // Jika error karena token expired, coba refresh token
      if (result['errorCode'] == 401 && i < maxRetries - 1) {
        await refreshToken();
      }
      
      // Tunggu sebelum retry
      if (i < maxRetries - 1) {
        await Future.delayed(Duration(seconds: delayInSeconds));
      }
    }
    
    return {
      'success': false,
      'message': 'Gagal mengambil workout setelah beberapa percobaan',
      'data': null,
    };
  }

  // Method untuk mengambil workout challenges dengan retry
  static Future<Map<String, dynamic>> getWorkoutChallengesWithRetry({
    int maxRetries = 3,
    int delayInSeconds = 2,
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      final result = await getWorkoutChallenges();
      
      if (result['success'] == true) {
        return result;
      }
      
      if (result['errorCode'] == 401 && i < maxRetries - 1) {
        await refreshToken();
      }
      
      if (i < maxRetries - 1) {
        await Future.delayed(Duration(seconds: delayInSeconds));
      }
    }
    
    return {
      'success': false,
      'message': 'Gagal mengambil workout challenges setelah beberapa percobaan',
      'data': null,
    };
  }

  // Method untuk mengambil workout history dengan retry
  static Future<Map<String, dynamic>> getWorkoutHistoryWithRetry({
    int maxRetries = 3,
    int delayInSeconds = 2,
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      final result = await getWorkoutHistory();
      
      if (result['success'] == true) {
        return result;
      }
      
      if (result['errorCode'] == 401 && i < maxRetries - 1) {
        await refreshToken();
      }
      
      if (i < maxRetries - 1) {
        await Future.delayed(Duration(seconds: delayInSeconds));
      }
    }
    
    return {
      'success': false,
      'message': 'Gagal mengambil workout history setelah beberapa percobaan',
      'data': null,
    };
  }
}