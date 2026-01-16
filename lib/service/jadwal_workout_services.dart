import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/service/connect.dart';
import 'package:flutter_application_1/utils/session_manager.dart';

<<<<<<< HEAD
// Model untuk Jadwal Workout dengan workout details
=======
// Model untuk Jadwal Workout
>>>>>>> 441b0de51d7c29b5e6216c60163c8fd2f6fb9907
class JadwalWorkout {
  final int id;
  final String namaJadwal;
  final String kategoriJadwal;
  final DateTime tanggal;
  final String jam;
  final String durasiWorkout;
  final DateTime createdAt;
  final DateTime updatedAt;
<<<<<<< HEAD
  final WorkoutInfo? workout; // ⬅️ Tambahkan workout info
=======
>>>>>>> 441b0de51d7c29b5e6216c60163c8fd2f6fb9907

  JadwalWorkout({
    required this.id,
    required this.namaJadwal,
    required this.kategoriJadwal,
    required this.tanggal,
    required this.jam,
    required this.durasiWorkout,
    required this.createdAt,
    required this.updatedAt,
<<<<<<< HEAD
    this.workout,
=======
>>>>>>> 441b0de51d7c29b5e6216c60163c8fd2f6fb9907
  });

  factory JadwalWorkout.fromJson(Map<String, dynamic> json) {
    return JadwalWorkout(
      id: json['id'] ?? 0,
      namaJadwal: json['nama_jadwal'] ?? '',
      kategoriJadwal: json['kategori_jadwal'] ?? '',
<<<<<<< HEAD
      tanggal: _parseDateTime(json['tanggal']),
      jam: json['jam']?.toString() ?? '00:00',
      durasiWorkout: json['durasi_workout']?.toString() ?? '0 menit',
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      workout: json['workout'] != null ? WorkoutInfo.fromJson(json['workout']) : null,
    );
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

  // Helper methods
  String get formattedTime {
    try {
      final parts = jam.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = parts[1];
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;
        return '${displayHour.toString().padLeft(2, '0')}:${minute.padLeft(2, '0')} $period';
=======
      tanggal: DateTime.parse(json['tanggal'] ?? DateTime.now().toString()),
      jam: json['jam'] ?? '00:00',
      durasiWorkout: json['durasi_workout'] ?? '0 menit',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toString()),
    );
  }

  // Helper methods
  String get formattedTime {
    try {
      final timeParts = jam.split(':');
      if (timeParts.length >= 2) {
        final hour = int.parse(timeParts[0]);
        final minute = timeParts[1];
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;
        return '${displayHour.toString().padLeft(2, '0')}:$minute $period';
>>>>>>> 441b0de51d7c29b5e6216c60163c8fd2f6fb9907
      }
      return jam;
    } catch (e) {
      return jam;
    }
  }

  String get formattedTanggal {
    return '${tanggal.day}/${tanggal.month}/${tanggal.year}';
  }
<<<<<<< HEAD

  String get dayName {
    final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    return days[tanggal.weekday % 7];
  }

  bool get hasWorkout => workout != null;
  bool get isToday {
    final now = DateTime.now();
    return tanggal.year == now.year &&
        tanggal.month == now.month &&
        tanggal.day == now.day;
  }

  bool get isPast {
    final now = DateTime.now();
    return tanggal.isBefore(DateTime(now.year, now.month, now.day));
  }

  bool get isFuture {
    final now = DateTime.now();
    return tanggal.isAfter(DateTime(now.year, now.month, now.day));
  }
}

// Model untuk Workout Info (embedded dalam Jadwal)
class WorkoutInfo {
  final int id;
  final String namaWorkout;
  final String exercises;
  final String status;
  final String? exercisesLabel;
  final String? statusLabel;

  WorkoutInfo({
    required this.id,
    required this.namaWorkout,
    required this.exercises,
    required this.status,
    this.exercisesLabel,
    this.statusLabel,
  });

  factory WorkoutInfo.fromJson(Map<String, dynamic> json) {
    return WorkoutInfo(
      id: json['id'] ?? 0,
      namaWorkout: json['nama_workout'] ?? '',
      exercises: json['exercises']?.toString() ?? '',
      status: json['status']?.toString().toLowerCase() ?? 'belum',
      exercisesLabel: json['exercises_label']?.toString(),
      statusLabel: json['status_label']?.toString(),
    );
  }

  bool get isCompleted => status == 'selesai';
  bool get isStarted => status == 'sedang dilakukan';
  bool get isNotStarted => status == 'belum';

  String get exercisesDisplay {
    final ex = exercises.toLowerCase();
    switch (ex) {
      case 'pushup':
        return 'Push-up';
      case 'squat':
        return 'Squat';
      case 'shoulder_press':
        return 'Shoulder Press';
      default:
        return ex.replaceAll('_', ' ');
    }
  }

  String get statusDisplay {
    if (statusLabel != null && statusLabel!.isNotEmpty) {
      return statusLabel!;
    }
    switch (status) {
      case 'selesai':
        return 'Selesai';
      case 'sedang dilakukan':
        return 'Sedang Dilakukan';
      case 'belum':
        return 'Belum Dimulai';
      default:
        return status;
    }
  }
}

// Model untuk Jadwal Workout Response sesuai backend
class JadwalWorkoutResponse {
  final List<JadwalWorkout> jadwals;
  final String date;
  final String dateFormatted;
  final int totalSchedules;
  final Map<String, dynamic> statistics;
=======
}

// Model untuk Jadwal Workout Response
class JadwalWorkoutResponse {
  final List<JadwalWorkout> jadwals;
  final String date;
  final int total;
>>>>>>> 441b0de51d7c29b5e6216c60163c8fd2f6fb9907

  JadwalWorkoutResponse({
    required this.jadwals,
    required this.date,
<<<<<<< HEAD
    required this.dateFormatted,
    required this.totalSchedules,
    required this.statistics,
  });

  factory JadwalWorkoutResponse.fromJson(Map<String, dynamic> json) {
    final jadwals = <JadwalWorkout>[];
    
    if (json['data'] is List) {
      for (var item in json['data'] as List) {
        try {
          jadwals.add(JadwalWorkout.fromJson(item));
        } catch (e) {
          print('Error parsing jadwal item: $e');
        }
      }
    }

    return JadwalWorkoutResponse(
      jadwals: jadwals,
      date: json['date']?.toString() ?? '',
      dateFormatted: json['date_formatted']?.toString() ?? '',
      totalSchedules: (json['total_schedules'] as int?) ?? 0,
      statistics: json['statistics'] is Map ? Map<String, dynamic>.from(json['statistics']) : {},
    );
  }

  // Statistics getters
  int get schedulesWithWorkout => statistics['schedules_with_workout'] ?? 0;
  int get schedulesWithoutWorkout => statistics['schedules_without_workout'] ?? 0;

  // Grouping methods
  Map<String, List<JadwalWorkout>> getGroupedByCategory() {
    final grouped = <String, List<JadwalWorkout>>{};

    for (var jadwal in jadwals) {
      final category = jadwal.kategoriJadwal;
=======
    required this.total,
  });

  factory JadwalWorkoutResponse.fromJson(Map<String, dynamic> json) {
    List<JadwalWorkout> jadwalList = [];
    
    if (json['data'] != null && json['data'] is List) {
      jadwalList = (json['data'] as List)
          .map((item) => JadwalWorkout.fromJson(item))
          .toList();
    }

    return JadwalWorkoutResponse(
      jadwals: jadwalList,
      date: json['date'] ?? DateTime.now().toString(),
      total: json['total'] ?? 0,
    );
  }

  // Method untuk grouping jadwal berdasarkan kategori
  Map<String, List<JadwalWorkout>> getGroupedByCategory() {
    Map<String, List<JadwalWorkout>> grouped = {};

    for (var jadwal in jadwals) {
      String category = jadwal.kategoriJadwal;
>>>>>>> 441b0de51d7c29b5e6216c60163c8fd2f6fb9907
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(jadwal);
    }

    return grouped;
  }

<<<<<<< HEAD
  Map<String, List<JadwalWorkout>> getGroupedByWorkoutStatus() {
    final grouped = <String, List<JadwalWorkout>>{
      'Belum Dimulai': [],
      'Sedang Dilakukan': [],
      'Selesai': [],
    };

    for (var jadwal in jadwals) {
      final workout = jadwal.workout;
      if (workout == null) {
        grouped['Belum Dimulai']!.add(jadwal);
      } else {
        switch (workout.status) {
          case 'belum':
            grouped['Belum Dimulai']!.add(jadwal);
            break;
          case 'sedang dilakukan':
            grouped['Sedang Dilakukan']!.add(jadwal);
            break;
          case 'selesai':
            grouped['Selesai']!.add(jadwal);
            break;
        }
=======
  // Method untuk mendapatkan jadwal berdasarkan waktu (pagi/siang/sore/malam)
  Map<String, List<JadwalWorkout>> getGroupedByTime() {
    Map<String, List<JadwalWorkout>> grouped = {
      'Pagi': [],    // 05:00 - 11:00
      'Siang': [],   // 11:00 - 15:00
      'Sore': [],    // 15:00 - 18:00
      'Malam': [],   // 18:00 - 22:00
    };

    for (var jadwal in jadwals) {
      try {
        final timeParts = jadwal.jam.split(':');
        if (timeParts.length >= 2) {
          final hour = int.parse(timeParts[0]);
          
          if (hour >= 5 && hour < 11) {
            grouped['Pagi']!.add(jadwal);
          } else if (hour >= 11 && hour < 15) {
            grouped['Siang']!.add(jadwal);
          } else if (hour >= 15 && hour < 18) {
            grouped['Sore']!.add(jadwal);
          } else if (hour >= 18 && hour < 22) {
            grouped['Malam']!.add(jadwal);
          }
        }
      } catch (e) {
        // Skip jika format waktu tidak valid
>>>>>>> 441b0de51d7c29b5e6216c60163c8fd2f6fb9907
      }
    }

    return grouped;
  }
}

class JadwalWorkoutService {
<<<<<<< HEAD
  static const String _jadwalEndpoint = '/api/jadwal';
  
=======
>>>>>>> 441b0de51d7c29b5e6216c60163c8fd2f6fb9907
  // Method utama untuk mengambil data jadwal hari ini
  static Future<Map<String, dynamic>> getTodayJadwal() async {
    final token = await SessionManager.getAuthToken();
    
<<<<<<< HEAD
    if (token == null || token.isEmpty) {
      return _errorResponse('Silakan login terlebih dahulu', 401);
    }
    
    final url = Uri.parse('$apiConnect$_jadwalEndpoint/today');
=======
    if (token == null) {
      return {
        'success': false,
        'message': 'Token tidak ditemukan. Silakan login kembali.',
        'data': null,
      };
    }
    
    final url = Uri.parse('$apiConnect/api/jadwal/today');
>>>>>>> 441b0de51d7c29b5e6216c60163c8fd2f6fb9907
    
    try {
      final response = await http.get(
        url,
<<<<<<< HEAD
        headers: _buildHeaders(token),
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
      
    } on http.ClientException catch (e) {
      return _errorResponse('Koneksi internet bermasalah: ${e.message}', 0);
    } on FormatException catch (e) {
      return _errorResponse('Format data tidak valid: ${e.message}', 0);
    } catch (e) {
      return _errorResponse('Terjadi kesalahan: ${e.toString()}', 0);
    }
  }

  // Helper untuk build headers
  static Map<String, String> _buildHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // Helper untuk handle response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      
      // Debug log untuk development
      if (data['data'] != null && data['data'] is List && data['data'].isNotEmpty) {
        final sample = data['data'][0];
        print('DEBUG - First jadwal sample:');
        print('  has_workout: ${sample['has_workout']}');
        print('  workout: ${sample['workout']}');
      }
      
=======
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
>>>>>>> 441b0de51d7c29b5e6216c60163c8fd2f6fb9907
      if (response.statusCode == 200 && data['status'] == 'success') {
        final jadwalResponse = JadwalWorkoutResponse.fromJson(data);
        
        return {
          'success': true,
<<<<<<< HEAD
          'message': data['message'] ?? 'Jadwal berhasil diambil',
          'data': jadwalResponse,
          'statusCode': response.statusCode,
        };
      }
      
      // Handle token expired
      if (response.statusCode == 401) {
        SessionManager.clearSession();
        return _errorResponse('Sesi telah berakhir, silakan login kembali', 401);
      }
      
      return _errorResponse(
        data['message'] ?? 'Gagal mengambil jadwal',
        response.statusCode,
      );
      
    } catch (e) {
      return _errorResponse('Gagal memproses response: ${e.toString()}', 0);
    }
  }

  // Helper untuk error response
  static Map<String, dynamic> _errorResponse(String message, int statusCode) {
    return {
      'success': false,
      'message': message,
      'statusCode': statusCode,
      'data': null,
    };
  }

  // Method untuk mengambil jadwal berdasarkan date range
  static Future<Map<String, dynamic>> getJadwalByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final token = await SessionManager.getAuthToken();
    
    if (token == null || token.isEmpty) {
      return _errorResponse('Silakan login terlebih dahulu', 401);
    }
    
    final url = Uri.parse('$apiConnect$_jadwalEndpoint/range');
    
    try {
      final response = await http.post(
        url,
        headers: _buildHeaders(token),
        body: jsonEncode({
          'start_date': startDate.toIso8601String().split('T')[0],
          'end_date': endDate.toIso8601String().split('T')[0],
        }),
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
      
    } catch (e) {
      return _errorResponse('Gagal mengambil jadwal: ${e.toString()}', 0);
    }
  }

  // Method untuk mengambil jadwal by ID
  static Future<Map<String, dynamic>> getJadwalById(int id) async {
    final token = await SessionManager.getAuthToken();
    
    if (token == null || token.isEmpty) {
      return _errorResponse('Silakan login terlebih dahulu', 401);
    }
    
    final url = Uri.parse('$apiConnect$_jadwalEndpoint/$id');
=======
          'message': data['message'] ?? 'Jadwal workout berhasil diambil',
          'data': jadwalResponse,
          'rawData': data,
        };
      } else {
        // Jika token tidak valid, clear session
        if (response.statusCode == 401) {
          await SessionManager.clearSession();
        }
        
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil jadwal workout',
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

  // Method untuk mengambil jadwal berdasarkan tanggal tertentu
  static Future<Map<String, dynamic>> getJadwalByDate(DateTime date) async {
    final token = await SessionManager.getAuthToken();
    
    if (token == null) {
      return {
        'success': false,
        'message': 'Token tidak ditemukan. Silakan login kembali.',
        'data': null,
      };
    }
    
    final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final url = Uri.parse('$apiConnect/api/jadwal/date/$formattedDate');
>>>>>>> 441b0de51d7c29b5e6216c60163c8fd2f6fb9907
    
    try {
      final response = await http.get(
        url,
<<<<<<< HEAD
        headers: _buildHeaders(token),
      ).timeout(const Duration(seconds: 10));

      return _handleResponseById(response);
      
    } catch (e) {
      return _errorResponse('Gagal mengambil detail jadwal: ${e.toString()}', 0);
    }
  }

  // Handler khusus untuk response by ID
  static Map<String, dynamic> _handleResponseById(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['status'] == 'success') {
        final jadwal = JadwalWorkout.fromJson(data['data']);
        
        return {
          'success': true,
          'message': data['message'] ?? 'Detail jadwal berhasil diambil',
          'data': jadwal,
          'statusCode': response.statusCode,
        };
      }
      
      if (response.statusCode == 401) {
        SessionManager.clearSession();
        return _errorResponse('Sesi telah berakhir, silakan login kembali', 401);
      }
      
      return _errorResponse(
        data['message'] ?? 'Jadwal tidak ditemukan',
        response.statusCode,
      );
      
    } catch (e) {
      return _errorResponse('Gagal memproses response: ${e.toString()}', 0);
    }
  }

  // Refresh token method
  static Future<Map<String, dynamic>> refreshToken() async {
    final token = await SessionManager.getAuthToken();
    
    if (token == null || token.isEmpty) {
      return {'success': false, 'message': 'Token tidak ditemukan'};
    }
    
    try {
      final response = await http.post(
        Uri.parse('$apiConnect/api/refresh-token'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        final newToken = data['data']?['token_auth']?.toString();
        if (newToken != null && newToken.isNotEmpty) {
          await SessionManager.setAuthToken(newToken);
          return {'success': true, 'message': 'Token berhasil diperbarui'};
        }
      }
      
      return {'success': false, 'message': 'Gagal memperbarui token'};
      
    } catch (e) {
      return {'success': false, 'message': 'Gagal memperbarui token: ${e.toString()}'};
    }
  }

  // Retry logic dengan exponential backoff
  static Future<Map<String, dynamic>> getTodayJadwalWithRetry({
    int maxRetries = 3,
    int initialDelay = 1,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      final result = await getTodayJadwal();
      
      if (result['success'] == true) {
        return result;
      }
      
      // Jika token expired, coba refresh
      if (result['statusCode'] == 401 && attempt < maxRetries) {
        await refreshToken();
      }
      
      // Exponential backoff delay
      if (attempt < maxRetries) {
        final delay = Duration(seconds: initialDelay * (1 << (attempt - 1)));
        await Future.delayed(delay);
      }
    }
    
    return _errorResponse('Gagal mengambil data setelah $maxRetries percobaan', 0);
  }

=======
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['status'] == 'success') {
        final jadwalResponse = JadwalWorkoutResponse.fromJson(data);
        
        return {
          'success': true,
          'message': data['message'] ?? 'Jadwal workout berhasil diambil',
          'data': jadwalResponse,
          'rawData': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil jadwal workout',
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

>>>>>>> 441b0de51d7c29b5e6216c60163c8fd2f6fb9907
  // Method untuk mendapatkan jadwal berdasarkan kategori
  static Future<Map<String, dynamic>> getJadwalByCategory(String category) async {
    final result = await getTodayJadwal();
    
    if (!result['success'] || result['data'] == null) {
      return result;
    }
    
<<<<<<< HEAD
    final jadwalResponse = result['data'] as JadwalWorkoutResponse;
    final grouped = jadwalResponse.getGroupedByCategory();
    final jadwals = grouped[category] ?? [];
    
    return {
      'success': true,
      'message': '${jadwals.length} jadwal ditemukan untuk kategori $category',
      'data': jadwals,
      'total': jadwals.length,
      'statusCode': 200,
    };
  }

  // Method untuk mendapatkan jadwal berdasarkan workout status
  static Future<Map<String, dynamic>> getJadwalByWorkoutStatus(String status) async {
=======
    final JadwalWorkoutResponse jadwalResponse = result['data'];
    final groupedJadwals = jadwalResponse.getGroupedByCategory();
    
    List<JadwalWorkout> jadwals = groupedJadwals[category] ?? [];
    
    return {
      'success': true,
      'message': 'Jadwal kategori $category berhasil diambil',
      'data': jadwals,
      'total': jadwals.length,
    };
  }

  // Method untuk mendapatkan jadwal berdasarkan waktu
  static Future<Map<String, dynamic>> getJadwalByTime(String time) async {
>>>>>>> 441b0de51d7c29b5e6216c60163c8fd2f6fb9907
    final result = await getTodayJadwal();
    
    if (!result['success'] || result['data'] == null) {
      return result;
    }
    
<<<<<<< HEAD
    final jadwalResponse = result['data'] as JadwalWorkoutResponse;
    final grouped = jadwalResponse.getGroupedByWorkoutStatus();
    final jadwals = grouped[status] ?? [];
    
    return {
      'success': true,
      'message': '${jadwals.length} jadwal dengan status $status',
      'data': jadwals,
      'total': jadwals.length,
      'statusCode': 200,
    };
  }

  // Method untuk mendapatkan statistics
  static Future<Map<String, dynamic>> getJadwalStatistics() async {
    final result = await getTodayJadwal();
    
    if (!result['success'] || result['data'] == null) {
      return result;
    }
    
    final jadwalResponse = result['data'] as JadwalWorkoutResponse;
    
    return {
      'success': true,
      'message': 'Statistics berhasil diambil',
      'data': {
        'statistics': jadwalResponse.statistics,
        'total_schedules': jadwalResponse.totalSchedules,
        'schedules_with_workout': jadwalResponse.schedulesWithWorkout,
        'schedules_without_workout': jadwalResponse.schedulesWithoutWorkout,
        'date': jadwalResponse.dateFormatted,
      },
      'statusCode': 200,
    };
  }

  // Method untuk mendapatkan upcoming jadwal (masa depan)
  static Future<Map<String, dynamic>> getUpcomingJadwal() async {
    final result = await getTodayJadwal();
    
    if (!result['success'] || result['data'] == null) {
      return result;
    }
    
    final jadwalResponse = result['data'] as JadwalWorkoutResponse;
    final upcoming = jadwalResponse.jadwals.where((j) => j.isFuture).toList();
    
    return {
      'success': true,
      'message': '${upcoming.length} jadwal mendatang',
      'data': upcoming,
      'total': upcoming.length,
      'statusCode': 200,
    };
  }

  // Method untuk mendapatkan completed jadwal (dengan workout selesai)
  static Future<Map<String, dynamic>> getCompletedJadwal() async {
    final result = await getTodayJadwal();
    
    if (!result['success'] || result['data'] == null) {
      return result;
    }
    
    final jadwalResponse = result['data'] as JadwalWorkoutResponse;
    final completed = jadwalResponse.jadwals
        .where((j) => j.workout != null && j.workout!.isCompleted)
        .toList();
    
    return {
      'success': true,
      'message': '${completed.length} jadwal selesai',
      'data': completed,
      'total': completed.length,
      'statusCode': 200,
=======
    final JadwalWorkoutResponse jadwalResponse = result['data'];
    final groupedByTime = jadwalResponse.getGroupedByTime();
    
    List<JadwalWorkout> jadwals = groupedByTime[time] ?? [];
    
    return {
      'success': true,
      'message': 'Jadwal waktu $time berhasil diambil',
      'data': jadwals,
      'total': jadwals.length,
    };
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
  static Future<Map<String, dynamic>> getTodayJadwalWithRetry({
    int maxRetries = 3,
    int delayInSeconds = 2,
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      final result = await getTodayJadwal();
      
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
      'message': 'Gagal mengambil jadwal workout setelah beberapa percobaan',
      'data': null,
>>>>>>> 441b0de51d7c29b5e6216c60163c8fd2f6fb9907
    };
  }
}