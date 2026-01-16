import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token_auth');
  }

  static Future<void> setAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token_auth', token);
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      return Map<String, dynamic>.from(jsonDecode(userDataString));
    }
    return null;
  }

  static Future<void> setUserData(String userDataJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', userDataJson);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token_auth');
    await prefs.remove('user_data');
  }
}