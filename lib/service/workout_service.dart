import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../service/connect.dart';
import '../utils/session_manager.dart';

// ========== MODELS SESUAI DATABASE ==========

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

  List<Workout> get notStartedWorkouts =>
      workouts.where((w) => w.isNotStarted).toList();

  List<Workout> get completedWorkouts =>
      workouts.where((w) => w.isCompleted).toList();

  List<Workout> get inProgressWorkouts =>
      workouts.where((w) => w.isStarted).toList();

  Map<String, int> getStatistics() {
    return {
      'completed': completedWorkouts.length,
      'in_progress': inProgressWorkouts.length,
      'not_started': notStartedWorkouts.length,
      'total': workouts.length,
    };
  }

  double get progressPercentage {
    if (workouts.isEmpty) return 0.0;
    return completedWorkouts.length / workouts.length;
  }

  Workout? get nextWorkout {
    if (notStartedWorkouts.isEmpty) return null;
    
    final withSchedule = notStartedWorkouts
        .where((w) => w.jadwal != null)
        .toList()
      ..sort((a, b) => a.jadwal!.jam.compareTo(b.jadwal!.jam));
    
    return withSchedule.isNotEmpty ? withSchedule.first : notStartedWorkouts.first;
  }
}

class Workout {
  final int id;
  final String namaWorkout;
  final String deskripsi;
  final String equipment;
  final String kategori;
  final String exercises;
  final String exercisesLabel;
  final String status;
  final String statusLabel;
  final int jadwalWorkoutId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final JadwalInfo? jadwal;

  Workout({
    required this.id,
    required this.namaWorkout,
    required this.deskripsi,
    required this.equipment,
    required this.kategori,
    required this.exercises,
    required this.exercisesLabel,
    required this.status,
    required this.statusLabel,
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
      exercises: json['exercises']?.toString() ?? '',
      exercisesLabel: json['exercises_label']?.toString() ?? _getExerciseLabel(json['exercises']?.toString() ?? ''),
      status: json['status']?.toString() ?? 'belum',
      statusLabel: json['status_label']?.toString() ?? _getStatusLabel(json['status']?.toString() ?? 'belum'),
      jadwalWorkoutId: json['jadwal_workout_id'] ?? 0,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      jadwal: json['jadwal'] != null ? JadwalInfo.fromJson(json['jadwal']) : null,
    );
  }

  static String _getExerciseLabel(String exercise) {
    final ex = exercise.toLowerCase();
    if (ex == 'pushup') return 'Push Up';
    if (ex == 'squat') return 'Squat';
    if (ex == 'shoulder_press') return 'Shoulder Press';
    return exercise.replaceAll('_', ' ').toTitleCase();
  }

  static String _getStatusLabel(String status) {
    switch (status) {
      case 'belum': return 'Belum Dimulai';
      case 'sedang dilakukan': return 'Sedang Dilakukan';
      case 'selesai': return 'Selesai';
      default: return status;
    }
  }

  static DateTime _parseDateTime(dynamic dateTime) {
    try {
      if (dateTime == null) return DateTime.now();
      if (dateTime is String) return DateTime.parse(dateTime);
      if (dateTime is DateTime) return dateTime;
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  // Helper properties
  bool get isCompleted => status == 'selesai';
  bool get isStarted => status == 'sedang dilakukan';
  bool get isNotStarted => status == 'belum';

  Color get statusColor {
    switch (status) {
      case 'selesai': return Colors.green;
      case 'sedang dilakukan': return Colors.orange;
      case 'belum': return Colors.blueGrey;
      default: return Colors.grey;
    }
  }

  IconData get exerciseIcon {
    final ex = exercises.toLowerCase();
    if (ex.contains('push')) return Icons.fitness_center;
    if (ex.contains('squat')) return Icons.directions_walk;
    if (ex.contains('shoulder')) return Icons.arrow_upward;
    return Icons.sports_gymnastics;
  }

  Color get categoryColor {
    final k = kategori.toLowerCase();
    if (k.contains('calisthenics')) return Colors.blue;
    if (k.contains('strength')) return Colors.green;
    if (k.contains('muscle')) return Colors.red;
    return Colors.purple;
  }

  String get timeDisplay => jadwal?.jamFormatted ?? '--:--';

  @override
  String toString() {
    return 'Workout{id: $id, nama: $namaWorkout, exercises: $exercises, status: $status}';
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
  final bool isToday;
  final bool isPast;
  final bool isFuture;

  JadwalInfo({
    required this.id,
    required this.namaJadwal,
    required this.kategoriJadwal,
    required this.tanggal,
    required this.tanggalFormatted,
    required this.jam,
    required this.jamFormatted,
    required this.durasiWorkout,
    required this.isToday,
    required this.isPast,
    required this.isFuture,
  });

  factory JadwalInfo.fromJson(Map<String, dynamic> json) {
    return JadwalInfo(
      id: json['id'] ?? 0,
      namaJadwal: json['nama_jadwal'] ?? '',
      kategoriJadwal: json['kategori_jadwal'] ?? '',
      tanggal: Workout._parseDateTime(json['tanggal']),
      tanggalFormatted: json['tanggal_formatted']?.toString() ?? '',
      jam: json['jam']?.toString() ?? '00:00',
      jamFormatted: json['jam_formatted']?.toString() ?? '00:00',
      durasiWorkout: json['durasi_workout']?.toString() ?? '0 menit',
      isToday: json['is_today'] ?? false,
      isPast: json['is_past'] ?? false,
      isFuture: json['is_future'] ?? false,
    );
  }
}

// ========== WORKOUT LOG MODEL SESUAI DATABASE ==========

class WorkoutLog {
  final int id;
  final int workoutId;
  final int userId;
  final String exerciseType;
  final int repetisi;
  final int set;
  final double berat;
  final int durasiDetik;
  final String durasiLabel;
  final double kaloriTerbakar;
  final int detakJantungRata;
  final double intensitas;
  final DateTime tanggalPelaksanaan;
  final String jamMulai;
  final String jamSelesai;
  final String catatan;
  final String statusLog;
  final String rating;
  final int skalaNyeri;
  final Map<String, dynamic> formAnalisis;
  final Map<String, dynamic> gerakanAnalisis;
  final double akurasiForm;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkoutLog({
    required this.id,
    required this.workoutId,
    required this.userId,
    required this.exerciseType,
    required this.repetisi,
    required this.set,
    required this.berat,
    required this.durasiDetik,
    required this.durasiLabel,
    required this.kaloriTerbakar,
    required this.detakJantungRata,
    required this.intensitas,
    required this.tanggalPelaksanaan,
    required this.jamMulai,
    required this.jamSelesai,
    required this.catatan,
    required this.statusLog,
    required this.rating,
    required this.skalaNyeri,
    required this.formAnalisis,
    required this.gerakanAnalisis,
    required this.akurasiForm,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkoutLog.fromJson(Map<String, dynamic> json) {
    return WorkoutLog(
      id: json['id'] ?? 0,
      workoutId: json['workout_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      exerciseType: json['exercise_type'] ?? '',
      repetisi: json['repetisi'] ?? 0,
      set: json['set'] ?? 0,
      berat: (json['berat'] as num?)?.toDouble() ?? 0.0,
      durasiDetik: json['durasi_detik'] ?? 0,
      durasiLabel: json['durasi_label'] ?? '',
      kaloriTerbakar: (json['kalori_terbakar'] as num?)?.toDouble() ?? 0.0,
      detakJantungRata: json['detak_jantung_rata'] ?? 0,
      intensitas: (json['intensitas'] as num?)?.toDouble() ?? 0.0,
      tanggalPelaksanaan: Workout._parseDateTime(json['tanggal_pelaksanaan']),
      jamMulai: json['jam_mulai']?.toString() ?? '',
      jamSelesai: json['jam_selesai']?.toString() ?? '',
      catatan: json['catatan'] ?? '',
      statusLog: json['status_log'] ?? 'completed',
      rating: json['rating'] ?? '',
      skalaNyeri: json['skala_nyeri'] ?? 0,
      formAnalisis: json['form_analisis'] is Map ? Map<String, dynamic>.from(json['form_analisis']) : {},
      gerakanAnalisis: json['gerakan_analisis'] is Map ? Map<String, dynamic>.from(json['gerakan_analisis']) : {},
      akurasiForm: (json['akurasi_form'] as num?)?.toDouble() ?? 0.0,
      createdAt: Workout._parseDateTime(json['created_at']),
      updatedAt: Workout._parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workout_id': workoutId,
      'exercise_type': exerciseType,
      'repetisi': repetisi,
      'set': set,
      'berat': berat,
      'durasi_detik': durasiDetik,
      'durasi_label': durasiLabel,
      'kalori_terbakar': kaloriTerbakar,
      'detak_jantung_rata': detakJantungRata,
      'intensitas': intensitas,
      'tanggal_pelaksanaan': tanggalPelaksanaan.toIso8601String(),
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      'catatan': catatan,
      'status_log': statusLog,
      'rating': rating,
      'skala_nyeri': skalaNyeri,
      'form_analisis': formAnalisis,
      'gerakan_analisis': gerakanAnalisis,
      'akurasi_form': akurasiForm,
    };
  }

  String get durasiMenit {
    if (durasiDetik > 0) {
      final minutes = durasiDetik ~/ 60;
      final seconds = durasiDetik % 60;
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return durasiLabel;
  }
}

// ========== WORKOUT SERVICE SESUAI BACKEND API ==========

class WorkoutService {
  static const String _workoutEndpoint = '/api/workouts';
  static const String _workoutLogEndpoint = '/api/workout-logs';
  static const int _maxRetries = 3;
  static const Duration _timeoutDuration = Duration(seconds: 15);

  // ========== HELPER METHODS UNTUK GET USER DATA ==========
  
  static Future<int?> _getUserId() async {
    try {
      final userData = await SessionManager.getUserData();
      if (userData != null && userData.containsKey('id')) {
        return userData['id'] as int?;
      }
      return null;
    } catch (e) {
      print('Error getting user id: $e');
      return null;
    }
  }

  static Future<String?> _getUserName() async {
    try {
      final userData = await SessionManager.getUserData();
      if (userData != null) {
        return userData['name'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting user name: $e');
      return null;
    }
  }

  static Future<String?> _getUserEmail() async {
    try {
      final userData = await SessionManager.getUserData();
      if (userData != null) {
        return userData['email'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting user email: $e');
      return null;
    }
  }

  // ========== CORE METHODS ==========

  // GET /api/workouts/today
  static Future<Map<String, dynamic>> getTodayWorkouts() async {
    final token = await SessionManager.getAuthToken();
    
    if (token == null || token.isEmpty) {
      return _errorResponse('Silakan login terlebih dahulu', 401);
    }
    
    final url = Uri.parse('$apiConnect$_workoutEndpoint/today');
    
    try {
      final response = await http.get(
        url,
        headers: _buildHeaders(token),
      ).timeout(_timeoutDuration);

      return _handleTodayWorkoutsResponse(response);
      
    } on http.ClientException catch (e) {
      return _errorResponse('Koneksi internet bermasalah: ${e.message}', 0);
    } on FormatException catch (e) {
      return _errorResponse('Format data tidak valid: ${e.message}', 0);
    } catch (e) {
      return _errorResponse('Terjadi kesalahan: ${e.toString()}', 0);
    }
  }

  // PUT /api/workouts/{id}/status
  static Future<Map<String, dynamic>> updateWorkoutStatus({
    required int workoutId,
    required String status,
  }) async {
    final token = await SessionManager.getAuthToken();
    
    if (token == null || token.isEmpty) {
      return _errorResponse('Silakan login terlebih dahulu', 401);
    }
    
    // Validate status sesuai dengan enum di database
    if (!['belum', 'sedang dilakukan', 'selesai'].contains(status)) {
      return _errorResponse('Status tidak valid. Pilihan: belum, sedang dilakukan, selesai', 400);
    }
    
    final url = Uri.parse('$apiConnect$_workoutEndpoint/$workoutId/status');
    
    try {
      final response = await http.put(
        url,
        headers: _buildHeaders(token),
        body: jsonEncode({'status': status}),
      ).timeout(_timeoutDuration);

      return _handleGenericResponse(response);
      
    } catch (e) {
      return _errorResponse('Gagal memperbarui status: ${e.toString()}', 0);
    }
  }

  // GET /api/workouts/{id}
  static Future<Map<String, dynamic>> getWorkoutById(int workoutId) async {
    final token = await SessionManager.getAuthToken();
    
    if (token == null || token.isEmpty) {
      return _errorResponse('Silakan login terlebih dahulu', 401);
    }
    
    final url = Uri.parse('$apiConnect$_workoutEndpoint/$workoutId');
    
    try {
      final response = await http.get(
        url,
        headers: _buildHeaders(token),
      ).timeout(_timeoutDuration);

      return _handleGenericResponse(response);
      
    } catch (e) {
      return _errorResponse('Gagal mengambil detail workout: ${e.toString()}', 0);
    }
  }

  // GET /api/workouts/by-exercise-type/{exerciseType}
  static Future<Map<String, dynamic>> getWorkoutsByExerciseType(String exerciseType) async {
    final token = await SessionManager.getAuthToken();
    
    if (token == null || token.isEmpty) {
      return _errorResponse('Silakan login terlebih dahulu', 401);
    }
    
    final url = Uri.parse('$apiConnect$_workoutEndpoint/by-exercise-type/$exerciseType');
    
    try {
      final response = await http.get(
        url,
        headers: _buildHeaders(token),
      ).timeout(_timeoutDuration);

      return _handleGenericResponse(response);
      
    } catch (e) {
      return _errorResponse('Gagal mengambil workout: ${e.toString()}', 0);
    }
  }

  // GET /api/workouts/statistics
  static Future<Map<String, dynamic>> getWorkoutStatistics() async {
    final token = await SessionManager.getAuthToken();
    
    if (token == null || token.isEmpty) {
      return _errorResponse('Silakan login terlebih dahulu', 401);
    }
    
    final url = Uri.parse('$apiConnect$_workoutEndpoint/statistics');
    
    try {
      final response = await http.get(
        url,
        headers: _buildHeaders(token),
      ).timeout(_timeoutDuration);

      return _handleGenericResponse(response);
      
    } catch (e) {
      return _errorResponse('Gagal mengambil statistics: ${e.toString()}', 0);
    }
  }

  // GET /api/workouts/by-status/{status}
  static Future<Map<String, dynamic>> getWorkoutsByStatus(String status) async {
    final token = await SessionManager.getAuthToken();
    
    if (token == null || token.isEmpty) {
      return _errorResponse('Silakan login terlebih dahulu', 401);
    }
    
    final url = Uri.parse('$apiConnect$_workoutEndpoint/by-status/$status');
    
    try {
      final response = await http.get(
        url,
        headers: _buildHeaders(token),
      ).timeout(_timeoutDuration);

      return _handleGenericResponse(response);
      
    } catch (e) {
      return _errorResponse('Gagal mengambil workout: ${e.toString()}', 0);
    }
  }

  // ========== WORKOUT LOG METHODS ==========

  // POST /api/workout-logs
  static Future<Map<String, dynamic>> createWorkoutLog(WorkoutLog log) async {
    final token = await SessionManager.getAuthToken();
    
    if (token == null || token.isEmpty) {
      return _errorResponse('Silakan login terlebih dahulu', 401);
    }
    
    final url = Uri.parse('$apiConnect$_workoutLogEndpoint');
    
    try {
      final response = await http.post(
        url,
        headers: _buildHeaders(token),
        body: jsonEncode(log.toJson()),
      ).timeout(_timeoutDuration);

      return _handleGenericResponse(response);
      
    } catch (e) {
      return _errorResponse('Gagal menyimpan log workout: ${e.toString()}', 0);
    }
  }

  // Method khusus untuk submit workout dengan pose detection
  static Future<Map<String, dynamic>> submitPoseDetectionWorkout({
    required int workoutId,
    required String exerciseType,
    required int totalReps,
    required int sets,
    required int durationSeconds,
    double? averageConfidence,
    Map<String, dynamic>? poseAnalysis,
    Map<String, dynamic>? movementAnalysis,
    int? heartRate,
    double? caloriesBurned,
  }) async {
    try {
      // 1. Update workout status to completed
      final statusResult = await updateWorkoutStatus(
        workoutId: workoutId,
        status: 'selesai',
      );
      
      if (!statusResult['success']) {
        return statusResult;
      }

      // 2. Get user ID from session
      final userId = await _getUserId();
      if (userId == null) {
        return _errorResponse('User ID tidak ditemukan, silakan login ulang', 401);
      }

      // 3. Create workout log with pose detection data
      final now = DateTime.now();
      final workoutLog = WorkoutLog(
        id: 0, // Will be set by database
        workoutId: workoutId,
        userId: userId,
        exerciseType: exerciseType,
        repetisi: totalReps,
        set: sets,
        berat: 0.0, // Default for bodyweight exercises
        durasiDetik: durationSeconds,
        durasiLabel: '${(durationSeconds / 60).toStringAsFixed(0)} menit',
        kaloriTerbakar: caloriesBurned ?? _calculateCalories(exerciseType, totalReps, durationSeconds),
        detakJantungRata: heartRate ?? _estimateHeartRate(exerciseType),
        intensitas: _calculateIntensity(exerciseType, totalReps),
        tanggalPelaksanaan: now,
        jamMulai: now.subtract(Duration(seconds: durationSeconds)).toString().split(' ')[1],
        jamSelesai: now.toString().split(' ')[1],
        catatan: 'Completed with AI pose detection',
        statusLog: 'completed',
        rating: 'normal',
        skalaNyeri: 3,
        formAnalisis: poseAnalysis ?? {},
        gerakanAnalisis: movementAnalysis ?? {},
        akurasiForm: averageConfidence ?? 0.0,
        createdAt: now,
        updatedAt: now,
      );

      // 4. Save workout log
      final logResult = await createWorkoutLog(workoutLog);
      
      return {
        'success': true,
        'message': 'Workout berhasil diselesaikan dan disimpan',
        'data': {
          'workout_id': workoutId,
          'total_reps': totalReps,
          'sets': sets,
          'duration': durationSeconds,
          'log_id': logResult['data']?['id'],
        },
        'statusCode': 200,
      };
      
    } catch (e) {
      return _errorResponse('Gagal menyelesaikan workout: ${e.toString()}', 0);
    }
  }

  // ========== CONVENIENCE METHODS ==========

  static Future<Map<String, dynamic>> startWorkout(int workoutId) async {
    return await updateWorkoutStatus(
      workoutId: workoutId,
      status: 'sedang dilakukan',
    );
  }

  static Future<Map<String, dynamic>> completeWorkout(int workoutId) async {
    return await updateWorkoutStatus(
      workoutId: workoutId,
      status: 'selesai',
    );
  }

  static Future<Map<String, dynamic>> getTodayWorkoutsWithRetry({
    int maxRetries = _maxRetries,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      final result = await getTodayWorkouts();
      
      if (result['success'] == true) {
        return result;
      }
      
      // Jika token expired, coba refresh
      if (result['statusCode'] == 401 && attempt < maxRetries) {
        await refreshToken();
      }
      
      // Exponential backoff
      if (attempt < maxRetries) {
        final delay = Duration(seconds: pow(2, attempt - 1).toInt());
        await Future.delayed(delay);
      }
    }
    
    return _errorResponse('Gagal mengambil data setelah $maxRetries percobaan', 0);
  }

  static Future<Map<String, dynamic>> getWorkoutChallenges() async {
    return await getWorkoutsByStatus('belum');
  }

  static Future<Map<String, dynamic>> getWorkoutHistory() async {
    return await getWorkoutsByStatus('selesai');
  }

  static Future<Map<String, dynamic>> getWorkoutInProgress() async {
    return await getWorkoutsByStatus('sedang dilakukan');
  }

  // ========== HELPER METHODS ==========

  static Map<String, String> _buildHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
    };
  }

  static Map<String, dynamic> _handleTodayWorkoutsResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        if (data['status'] == 'success') {
          final workoutResponse = WorkoutResponse.fromJson(data);
          
          return {
            'success': true,
            'message': data['message'] ?? 'Workout berhasil diambil',
            'data': workoutResponse,
            'statusCode': response.statusCode,
          };
        }
      }
      
      // Handle token expired
      if (response.statusCode == 401) {
        SessionManager.clearSession();
        return _errorResponse('Sesi telah berakhir, silakan login kembali', 401);
      }
      
      if (response.statusCode == 404) {
        return _errorResponse('Data tidak ditemukan', 404);
      }
      
      if (response.statusCode == 500) {
        return _errorResponse('Server error, silakan coba lagi nanti', 500);
      }
      
      return _errorResponse(
        data['message'] ?? data['error'] ?? 'Gagal mengambil workout',
        response.statusCode,
      );
      
    } on FormatException catch (e) {
      return _errorResponse('Format response tidak valid: ${e.message}', 0);
    } catch (e) {
      return _errorResponse('Gagal memproses response: ${e.toString()}', 0);
    }
  }

  static Map<String, dynamic> _handleGenericResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['status'] == 'success') {
          return {
            'success': true,
            'message': data['message'] ?? 'Success',
            'data': data['data'],
            'statusCode': response.statusCode,
          };
        }
      }
      
      if (response.statusCode == 401) {
        SessionManager.clearSession();
        return _errorResponse('Sesi telah berakhir, silakan login kembali', 401);
      }
      
      if (response.statusCode == 422) {
        final errors = data['errors'] ?? {};
        final errorMessages = errors.entries
            .map((entry) => '${entry.key}: ${entry.value.join(', ')}')
            .join('\n');
        return _errorResponse(
          data['message'] ?? 'Validasi gagal:\n$errorMessages',
          422,
        );
      }
      
      return _errorResponse(
        data['message'] ?? data['error'] ?? 'Request failed',
        response.statusCode,
      );
      
    } catch (e) {
      return _errorResponse('Gagal memproses response: ${e.toString()}', 0);
    }
  }

  static Map<String, dynamic> _errorResponse(String message, int statusCode) {
    return {
      'success': false,
      'message': message,
      'statusCode': statusCode,
      'data': null,
    };
  }

  static Future<Map<String, dynamic>> refreshToken() async {
    final token = await SessionManager.getAuthToken();
    
    if (token == null || token.isEmpty) {
      return {'success': false, 'message': 'Token tidak ditemukan'};
    }
    
    try {
      final response = await http.post(
        Uri.parse('$apiConnect/api/refresh-token'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(_timeoutDuration);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        if (data['status'] == 'success' || data['success'] == true) {
          final newToken = data['data']?['token_auth'] ?? data['data']?['token'] ?? data['token'];
          if (newToken != null && newToken.toString().isNotEmpty) {
            await SessionManager.setAuthToken(newToken.toString());
            return {'success': true, 'message': 'Token berhasil diperbarui'};
          }
        }
      }
      
      return {'success': false, 'message': data['message'] ?? 'Gagal memperbarui token'};
      
    } catch (e) {
      return {'success': false, 'message': 'Gagal memperbarui token: ${e.toString()}'};
    }
  }

  // ========== CALCULATION HELPERS ==========

  static double _calculateCalories(String exerciseType, int reps, int durationSeconds) {
    final caloriesPerMinute = {
      'pushup': 8.0,
      'squat': 10.0,
      'shoulder_press': 7.0,
    };
    
    final baseCalories = caloriesPerMinute[exerciseType] ?? 8.0;
    final minutes = durationSeconds / 60;
    return (baseCalories * minutes) + (reps * 0.1);
  }

  static int _estimateHeartRate(String exerciseType) {
    final baseHeartRate = {
      'pushup': 120,
      'squat': 130,
      'shoulder_press': 110,
    };
    return baseHeartRate[exerciseType] ?? 120;
  }

  static double _calculateIntensity(String exerciseType, int reps) {
    final maxReps = {
      'pushup': 50,
      'squat': 40,
      'shoulder_press': 30,
    };
    
    final max = maxReps[exerciseType] ?? 40;
    return (reps / max).clamp(0.0, 1.0);
  }

  // ========== FORM GUIDELINES ==========

  static Future<Map<String, dynamic>> getWorkoutFormGuidelines(String exerciseType) {
    // For now return static guidelines
    final guidelines = _getStaticFormGuidelines(exerciseType);
    
    return Future.value({
      'success': true,
      'message': 'Form guidelines retrieved',
      'data': guidelines,
      'statusCode': 200,
    });
  }

  static Map<String, dynamic> _getStaticFormGuidelines(String exerciseType) {
    final ex = exerciseType.toLowerCase();
    
    if (ex.contains('push')) {
      return {
        'exercise_type': 'pushup',
        'correct_form': 'Tubuh harus membentuk garis lurus dari kepala hingga kaki. Siku membentuk sudut 90 derajat saat turun.',
        'common_mistakes': [
          'Pinggul turun atau naik terlalu tinggi',
          'Siku terlalu keluar atau terlalu dekat dengan badan',
          'Tidak turun cukup rendah',
          'Leher menekuk ke depan'
        ],
        'tips': [
          'Kencangkan otot perut dan glutes',
          'Jaga siku membentuk sudut 45 derajat dengan badan',
          'Turunkan dada hingga sejajar dengan siku',
          'Tarik bahu ke belakang dan turun'
        ],
        'target_angles': {
          'elbow_angle': '90-120 derajat',
          'hip_alignment': '0-15 derajat dari horizontal',
          'shoulder_angle': '160-180 derajat'
        }
      };
    } 
    else if (ex.contains('squat')) {
      return {
        'exercise_type': 'squat',
        'correct_form': 'Pinggul turun hingga sejajar dengan lutut, dada terbuka, punggung lurus.',
        'common_mistakes': [
          'Lutut melewati jari kaki',
          'Punggung membungkuk',
          'Tidak turun cukup rendah',
          'Berdiri dengan tumit terangkat'
        ],
        'tips': [
          'Jaga berat badan di tumit',
          'Dorong pinggul ke belakang',
          'Jaga dada tetap terbuka',
          'Pertahankan tulang belakang netral'
        ],
        'target_angles': {
          'knee_angle': '70-90 derajat',
          'hip_angle': '90-120 derajat',
          'back_angle': '45-60 derajat'
        }
      };
    }
    else if (ex.contains('shoulder')) {
      return {
        'exercise_type': 'shoulder_press',
        'correct_form': 'Beban diangkat lurus ke atas, siku sedikit di depan badan, core kencang.',
        'common_mistakes': [
          'Menggunakan momentum dari kaki',
          'Punggung bawah melengkung',
          'Tidak mengangkat beban sepenuhnya',
          'Siku terlalu keluar'
        ],
        'tips': [
          'Kencangkan glutes dan core sebelum mengangkat',
          'Jaga siku sedikit di depan badan saat mulai',
          'Angkat beban dalam garis lurus di atas kepala',
          'Turunkan beban terkontrol hingga sejajar dagu'
        ],
        'target_angles': {
          'elbow_angle': '90-120 derajat',
          'shoulder_angle': '160-180 derajat'
        }
      };
    }
    else {
      return {
        'exercise_type': exerciseType,
        'correct_form': 'Pertahankan postur yang baik dan lakukan gerakan dengan kontrol penuh.',
        'common_mistakes': [
          'Form tidak konsisten',
          'Gerakan terlalu cepat',
        ],
        'tips': [
          'Fokus pada form yang benar',
          'Lakukan gerakan dengan kontrol penuh',
        ],
      };
    }
  }

  // ========== ADDITIONAL METHODS ==========

  static Future<Map<String, dynamic>> getCurrentUserInfo() async {
    try {
      final token = await SessionManager.getAuthToken();
      if (token == null || token.isEmpty) {
        return _errorResponse('Silakan login terlebih dahulu', 401);
      }

      final userId = await _getUserId();
      final userName = await _getUserName();
      final userEmail = await _getUserEmail();

      return {
        'success': true,
        'message': 'User info retrieved',
        'data': {
          'id': userId,
          'name': userName,
          'email': userEmail,
        },
        'statusCode': 200,
      };
    } catch (e) {
      return _errorResponse('Gagal mengambil info user: ${e.toString()}', 0);
    }
  }
}

// Extension untuk string utilities
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