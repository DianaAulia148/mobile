import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_application_1/service/connect.dart';
import 'package:flutter_application_1/utils/session_manager.dart';

class AuthService {
  static String? _token;
  static Map<String, dynamic>? _userData;
  
  static String? getAuthToken() => _token;
  static Map<String, dynamic>? getUserData() => _userData;

  // Method untuk register
  static Future<Map<String, dynamic>> register({
    required String namaLengkap,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String jenisKelamin,
    double? tinggiBadan,
    double? beratBadan,
    String? alergi,
    String? golonganDarah,
    File? fotoProfile,
  }) async {
    try {
      // Buat multipart request
      final url = Uri.parse('$apiConnect/api/register');
      var request = http.MultipartRequest('POST', url);

      // Tambahkan fields
      request.fields['nama_lengkap'] = namaLengkap;
      request.fields['email'] = email;
      request.fields['password'] = password;
      request.fields['password_confirmation'] = passwordConfirmation;
      request.fields['jenis_kelamin'] = jenisKelamin;
      
      if (tinggiBadan != null) {
        request.fields['tinggi_badan'] = tinggiBadan.toString();
      }
      
      if (beratBadan != null) {
        request.fields['berat_badan'] = beratBadan.toString();
      }
      
      if (alergi != null && alergi.isNotEmpty) {
        request.fields['alergi'] = alergi;
      }
      
      if (golonganDarah != null && golonganDarah.isNotEmpty) {
        request.fields['golongan_darah'] = golonganDarah;
      }

      // Tambahkan file foto profile jika ada
      if (fotoProfile != null) {
        final fileStream = http.ByteStream(fotoProfile.openRead());
        final fileLength = await fotoProfile.length();
        
        final multipartFile = http.MultipartFile(
          'foto_profile',
          fileStream,
          fileLength,
          filename: fotoProfile.path.split('/').last,
          contentType: MediaType('image', 'jpeg'),
        );
        
        request.files.add(multipartFile);
      }

      // Kirim request
      final response = await request.send();
      final responseString = await response.stream.bytesToString();
      final data = jsonDecode(responseString);

      if (response.statusCode == 201 && data['success'] == true) {
        // Simpan token dan data user setelah registrasi berhasil
        _token = data['data']['token_auth'];
        _userData = data['data'];
        
        await SessionManager.setAuthToken(_token!);
        await SessionManager.setUserData(jsonEncode(data['data']['pengguna']));
        
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        String errorMessage = 'Registrasi gagal';
        
        if (data.containsKey('errors')) {
          final errors = data['errors'];
          if (errors['email'] != null) {
            errorMessage = errors['email'][0];
          } else if (errors['password'] != null) {
            errorMessage = errors['password'][0];
          } else if (errors['nama_lengkap'] != null) {
            errorMessage = errors['nama_lengkap'][0];
          } else if (data['message'] != null) {
            errorMessage = data['message'];
          }
        } else if (data['message'] != null) {
          errorMessage = data['message'];
        }
        
        return {
          'success': false,
          'message': errorMessage,
          'errors': data['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan. Periksa koneksi internet Anda.',
      };
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$apiConnect/api/login');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        // Simpan token dan data user
        _token = data['data']['token_auth'];
        _userData = data['data'];
        
        await SessionManager.setAuthToken(_token!);
        await SessionManager.setUserData(jsonEncode(data['data']['pengguna']));
        
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        String errorMessage = 'Login gagal';
        if (data.containsKey('errors')) {
          final errors = data['errors'];
          if (errors['email'] != null) {
            errorMessage = errors['email'][0];
          } else if (data['message'] != null) {
            errorMessage = data['message'];
          }
        }
        
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan. Periksa koneksi internet Anda.',
      };
    }
  }

  // Method untuk mengambil data profile dari API
  static Future<Map<String, dynamic>> getProfile() async {
    final token = await SessionManager.getAuthToken();
    
    if (token == null) {
      return {
        'success': false,
        'message': 'Token tidak ditemukan',
      };
    }
    
    final url = Uri.parse('$apiConnect/api/profile');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        // Update local data
        _userData = data['data'];
        await SessionManager.setUserData(jsonEncode(data['data']['pengguna']));
        
        return {
          'success': true,
          'message': 'Profile berhasil diambil',
          'data': data['data'],
        };
      } else {
        // Jika token tidak valid, clear session
        if (response.statusCode == 401) {
          await _clearLocalData();
        }
        
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan. Periksa koneksi internet Anda.',
      };
    }
  }

  // Method untuk update profile
  static Future<Map<String, dynamic>> updateProfile({
    required String namaLengkap,
    required String jenisKelamin,
    double? tinggiBadan,
    double? beratBadan,
    String? alergi,
    String? golonganDarah,
    File? fotoProfile,
  }) async {
    final token = await SessionManager.getAuthToken();
    
    if (token == null) {
      return {
        'success': false,
        'message': 'Token tidak ditemukan. Silakan login kembali.',
      };
    }
    
    try {
      // Buat multipart request
      final url = Uri.parse('$apiConnect/api/profile/update');
      var request = http.MultipartRequest('POST', url);

      // Tambahkan headers
      request.headers['Authorization'] = 'Bearer $token';

      // Tambahkan fields
      request.fields['nama_lengkap'] = namaLengkap;
      request.fields['jenis_kelamin'] = jenisKelamin;
      
      if (tinggiBadan != null) {
        request.fields['tinggi_badan'] = tinggiBadan.toString();
      } else {
        request.fields['tinggi_badan'] = '';
      }
      
      if (beratBadan != null) {
        request.fields['berat_badan'] = beratBadan.toString();
      } else {
        request.fields['berat_badan'] = '';
      }
      
      if (alergi != null && alergi.isNotEmpty) {
        request.fields['alergi'] = alergi;
      } else {
        request.fields['alergi'] = '';
      }
      
      if (golonganDarah != null && golonganDarah.isNotEmpty) {
        request.fields['golongan_darah'] = golonganDarah;
      } else {
        request.fields['golongan_darah'] = '';
      }

      // Tambahkan file foto profile jika ada
      if (fotoProfile != null) {
        final fileStream = http.ByteStream(fotoProfile.openRead());
        final fileLength = await fotoProfile.length();
        
        final multipartFile = http.MultipartFile(
          'foto_profile',
          fileStream,
          fileLength,
          filename: fotoProfile.path.split('/').last,
          contentType: MediaType('image', 'jpeg'),
        );
        
        request.files.add(multipartFile);
      }

      // Kirim request
      final response = await request.send();
      final responseString = await response.stream.bytesToString();
      final data = jsonDecode(responseString);

      if (response.statusCode == 200 && data['success'] == true) {
        // Update local data
        _userData = data['data'];
        await SessionManager.setUserData(jsonEncode(data['data']['pengguna']));
        
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        String errorMessage = 'Gagal memperbarui profile';
        
        if (data.containsKey('errors')) {
          final errors = data['errors'];
          if (errors['nama_lengkap'] != null) {
            errorMessage = errors['nama_lengkap'][0];
          } else if (errors['email'] != null) {
            errorMessage = errors['email'][0];
          } else if (data['message'] != null) {
            errorMessage = data['message'];
          }
        } else if (data['message'] != null) {
          errorMessage = data['message'];
        }
        
        return {
          'success': false,
          'message': errorMessage,
          'errors': data['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan. Periksa koneksi internet Anda.',
      };
    }
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final token = await SessionManager.getAuthToken();
    
    if (token == null) {
      return {
        'success': false,
        'message': 'Token tidak ditemukan. Silakan login kembali.',
      };
    }
    
    final url = Uri.parse('$apiConnect/api/profile/change-password');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': confirmPassword,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Password berhasil diubah',
        };
      } else {
        String errorMessage = 'Gagal mengubah password';
        
        if (data.containsKey('errors')) {
          final errors = data['errors'];
          if (errors['current_password'] != null) {
            errorMessage = errors['current_password'][0];
          } else if (errors['new_password'] != null) {
            errorMessage = errors['new_password'][0];
          } else if (data['message'] != null) {
            errorMessage = data['message'];
          }
        } else if (data['message'] != null) {
          errorMessage = data['message'];
        }
        
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan. Periksa koneksi internet Anda.',
      };
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    final token = await SessionManager.getAuthToken();
    
    try {
      if (token != null) {
        final url = Uri.parse('$apiConnect/api/logout');
        
        final response = await http.post(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          await _clearLocalData();
          return {
            'success': true,
            'message': 'Logout berhasil',
          };
        }
      }
      
      await _clearLocalData();
      return {
        'success': true,
        'message': 'Logout berhasil',
      };
    } catch (e) {
      await _clearLocalData();
      return {
        'success': true,
        'message': 'Logout berhasil',
      };
    }
  }

  // Helper method untuk clear data lokal
  static Future<void> _clearLocalData() async {
    _token = null;
    _userData = null;
    await SessionManager.clearSession();
  }

  static Future<bool> isLoggedIn() async {
    final token = await SessionManager.getAuthToken();
    return token != null && token.isNotEmpty;
  }
}