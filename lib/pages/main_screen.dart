import 'package:flutter/material.dart';
import '../components/navbottom.dart';
import 'home.dart';
import 'jadwal.dart';
import 'foodplan.dart';
import 'workout.dart';
import 'pengaturan.dart';
import '../auth/login.dart';
import '../utils/session_manager.dart';

class MainScreen extends StatefulWidget {
  final double? initialBmi;
  
  const MainScreen({super.key, this.initialBmi});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<Widget> _pages = [];
  bool _isTokenValid = false;
  bool _isCheckingToken = true;
  bool _redirectingToLogin = false;

  @override
  void initState() {
    super.initState();
    _checkTokenAndInitialize();
  }

  Future<void> _checkTokenAndInitialize() async {
    // Delay sedikit untuk menghindari race condition
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Cek apakah token ada
    final token = await SessionManager.getAuthToken();
    
    if (mounted) {
      if (token == null || token.isEmpty) {
        // Token tidak ada, set state dan redirect ke login
        setState(() {
          _isTokenValid = false;
          _isCheckingToken = false;
          _redirectingToLogin = true;
        });
        
        // Delay untuk memberikan waktu render state sebelum redirect
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _redirectToLogin();
        });
        return;
      }

      // Token ada, lanjutkan inisialisasi
      setState(() {
        _isTokenValid = true;
        _isCheckingToken = false;
        _redirectingToLogin = false;
        _pages = [
          HomePage(bmi: widget.initialBmi ?? 22.0),
          const PenjadwalanPage(),
          const FoodPlanPage(),
          const WorkoutPlanPage(),
          PengaturanPage(
            bmi: widget.initialBmi ?? 22.0,
          ),
        ];
      });

      // Mulai pengecekan berkala
      _startTokenChecker();
    }
  }

  void _redirectToLogin() {
    if (mounted && !_redirectingToLogin) {
      _redirectingToLogin = true;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  // Fungsi untuk memeriksa token secara berkala
  void _startTokenChecker() {
    Future.delayed(const Duration(minutes: 1), () async {
      if (mounted && _isTokenValid) {
        final token = await SessionManager.getAuthToken();
        if (token == null || token.isEmpty) {
          // Token tidak ada, arahkan ke login
          _redirectToLogin();
        } else {
          // Token masih ada, lanjutkan pengecekan
          _startTokenChecker();
        }
      }
    });
  }

  // Fungsi untuk menangani perubahan halaman
  void _onTabTapped(int index) async {
    // Cek token sebelum berpindah halaman
    final token = await SessionManager.getAuthToken();
    if (token == null || token.isEmpty) {
      _redirectToLogin();
      return;
    }
    
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan loading screen saat mengecek token
    if (_isCheckingToken) {
      return _buildLoadingScreen('Memverifikasi sesi...');
    }

    // Jika redirecting to login
    if (_redirectingToLogin) {
      return _buildLoadingScreen('Mengalihkan ke login...');
    }

    // Jika token tidak valid (tapi belum redirect)
    if (!_isTokenValid) {
      return _buildLoadingScreen('Menyiapkan sesi...');
    }

    // Token valid dan halaman sudah diinisialisasi
    if (_pages.isEmpty) {
      return _buildLoadingScreen('Menyiapkan halaman...');
    }

    // Token valid, tampilkan halaman utama
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  Widget _buildLoadingScreen(String message) {
    return Scaffold(
      backgroundColor: const Color(0xFF08030C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFFA32CC4),
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 10),
            if (message.contains('login'))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Silakan login kembali untuk melanjutkan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}