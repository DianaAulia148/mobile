import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/service/connect.dart';
import 'package:flutter_application_1/utils/session_manager.dart';

// Model untuk Jadwal Workout
class JadwalWorkout {
  final int id;
  final String namaJadwal;
  final String kategoriJadwal;
  final DateTime tanggal;
  final String jam;
  final String durasiWorkout;
  final DateTime createdAt;
  final DateTime updatedAt;

  JadwalWorkout({
    required this.id,
    required this.namaJadwal,
    required this.kategoriJadwal,
    required this.tanggal,
    required this.jam,
    required this.durasiWorkout,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JadwalWorkout.fromJson(Map<String, dynamic> json) {
    return JadwalWorkout(
      id: json['id'] ?? 0,
      namaJadwal: json['nama_jadwal'] ?? '',
      kategoriJadwal: json['kategori_jadwal'] ?? '',
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
      }
      return jam;
    } catch (e) {
      return jam;
    }
  }

  String get formattedTanggal {
    return '${tanggal.day}/${tanggal.month}/${tanggal.year}';
  }
}

// Model untuk Jadwal Workout Response
class JadwalWorkoutResponse {
  final List<JadwalWorkout> jadwals;
  final String date;
  final int total;

  JadwalWorkoutResponse({
    required this.jadwals,
    required this.date,
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
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(jadwal);
    }

    return grouped;
  }

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
      }
    }

    return grouped;
  }
}

class JadwalWorkoutService {
  // Method utama untuk mengambil data jadwal hari ini
  static Future<Map<String, dynamic>> getTodayJadwal() async {
    final token = await SessionManager.getAuthToken();
    
    if (token == null) {
      return {
        'success': false,
        'message': 'Token tidak ditemukan. Silakan login kembali.',
        'data': null,
      };
    }
    
    final url = Uri.parse('$apiConnect/api/jadwal/today');
    
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
        final jadwalResponse = JadwalWorkoutResponse.fromJson(data);
        
        return {
          'success': true,
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

  // Method untuk mendapatkan jadwal berdasarkan kategori
  static Future<Map<String, dynamic>> getJadwalByCategory(String category) async {
    final result = await getTodayJadwal();
    
    if (!result['success'] || result['data'] == null) {
      return result;
    }
    
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
    final result = await getTodayJadwal();
    
    if (!result['success'] || result['data'] == null) {
      return result;
    }
    
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
    };
  }
}