import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/service/connect.dart';
import 'package:flutter_application_1/utils/session_manager.dart';

// Model untuk Food Item
class FoodItem {
  final int id;
  final String namaMakanan;
  final String deskripsi;
  final String kategoriMakanan;
  final int kalori;
  final String protein;
  final String karbohidrat;
  final String lemak;
  final DateTime createdAt;
  final DateTime updatedAt;

  FoodItem({
    required this.id,
    required this.namaMakanan,
    required this.deskripsi,
    required this.kategoriMakanan,
    required this.kalori,
    required this.protein,
    required this.karbohidrat,
    required this.lemak,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] ?? 0,
      namaMakanan: json['nama_makanan'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      kategoriMakanan: json['kategori_makanan'] ?? '',
      kalori: json['kalori'] ?? 0,
      protein: json['protein']?.toString() ?? '0.00',
      karbohidrat: json['karbohidrat']?.toString() ?? '0.00',
      lemak: json['lemak']?.toString() ?? '0.00',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toString()),
    );
  }

  // Helper method untuk format nilai nutrisi
  String get formattedProtein => '${double.parse(protein).toStringAsFixed(1)}g P';
  String get formattedCarbs => '${double.parse(karbohidrat).toStringAsFixed(1)}g C';
  String get formattedFat => '${double.parse(lemak).toStringAsFixed(1)}g F';
  String get formattedCalories => '$kalori kcal';
}

// Model untuk Food Plan Response
class FoodPlanResponse {
  final List<FoodItem> foods;
  final String date;
  final int total;

  FoodPlanResponse({
    required this.foods,
    required this.date,
    required this.total,
  });

  factory FoodPlanResponse.fromJson(Map<String, dynamic> json) {
    List<FoodItem> foodList = [];
    if (json['foods'] != null && json['foods'] is List) {
      foodList = (json['foods'] as List)
          .map((item) => FoodItem.fromJson(item))
          .toList();
    }

    return FoodPlanResponse(
      foods: foodList,
      date: json['date'] ?? DateTime.now().toString(),
      total: json['total'] ?? 0,
    );
  }

  // Method untuk grouping makanan berdasarkan kategori
  Map<String, List<FoodItem>> getGroupedByCategory() {
    Map<String, List<FoodItem>> grouped = {
      'pagi': [],
      'siang': [],
      'sore': [],
      'malam': [],
    };

    for (var food in foods) {
      String category = food.kategoriMakanan.toLowerCase();
      if (grouped.containsKey(category)) {
        grouped[category]!.add(food);
      } else {
        grouped[category] = [food];
      }
    }

    return grouped;
  }

  // Method untuk menghitung total nutrisi
  Map<String, double> getTotalNutrition() {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var food in foods) {
      totalCalories += food.kalori.toDouble();
      totalProtein += double.parse(food.protein);
      totalCarbs += double.parse(food.karbohidrat);
      totalFat += double.parse(food.lemak);
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
    };
  }
}

class FoodPlanService {
  // Method utama untuk mengambil data food plan
  static Future<Map<String, dynamic>> getFoodPlan() async {
    final token = await SessionManager.getAuthToken();
    
    if (token == null) {
      return {
        'success': false,
        'message': 'Token tidak ditemukan. Silakan login kembali.',
        'data': null,
      };
    }
    
    final url = Uri.parse('$apiConnect/api/foods');
    
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
        final foodPlanResponse = FoodPlanResponse.fromJson(data['data']);
        
        return {
          'success': true,
          'message': data['message'] ?? 'Food plan berhasil diambil',
          'data': foodPlanResponse,
          'rawData': data,
        };
      } else {
        // Jika token tidak valid, clear session
        if (response.statusCode == 401) {
          await SessionManager.clearSession();
        }
        
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil food plan',
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

  // Method untuk mendapatkan makanan berdasarkan kategori
  static Future<Map<String, dynamic>> getFoodByCategory(String category) async {
    final result = await getFoodPlan();
    
    if (!result['success'] || result['data'] == null) {
      return result;
    }
    
    final FoodPlanResponse foodPlan = result['data'];
    final groupedFoods = foodPlan.getGroupedByCategory();
    
    String normalizedCategory = category.toLowerCase();
    List<FoodItem> foods = groupedFoods[normalizedCategory] ?? [];
    
    return {
      'success': true,
      'message': 'Data makanan kategori $category berhasil diambil',
      'data': foods,
      'total': foods.length,
    };
  }

  // Method untuk mendapatkan total nutrisi harian
  static Future<Map<String, dynamic>> getDailyNutrition() async {
    final result = await getFoodPlan();
    
    if (!result['success'] || result['data'] == null) {
      return result;
    }
    
    final FoodPlanResponse foodPlan = result['data'];
    final nutrition = foodPlan.getTotalNutrition();
    
    return {
      'success': true,
      'message': 'Data nutrisi harian berhasil diambil',
      'data': nutrition,
      'foodCount': foodPlan.total,
    };
  }

  // Method untuk refresh token jika diperlukan (optional)
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
        'message': 'Gagal memperbarui token',
      };
    }
  }

  // Method untuk menangani error dan retry
  static Future<Map<String, dynamic>> getFoodPlanWithRetry({
    int maxRetries = 3,
    int delayInSeconds = 2,
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      final result = await getFoodPlan();
      
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
      'message': 'Gagal mengambil food plan setelah beberapa percobaan',
      'data': null,
    };
  }
}