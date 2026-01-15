import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_application_1/service/auth_services.dart';
import 'package:flutter_application_1/utils/session_manager.dart';
import 'edit_profil.dart';
import 'ubah_password.dart'; 

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
}

class PengaturanPage extends StatefulWidget {
  final double bmi;
  const PengaturanPage({super.key, required this.bmi});

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Method untuk memuat data user
  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Coba ambil dari cache/local storage terlebih dahulu
      final cachedUserData = await SessionManager.getUserData();
      if (cachedUserData != null) {
        setState(() {
          _userData = cachedUserData;
          _isLoading = false;
        });
      }

      // Kemudian fetch fresh data dari API
      final result = await AuthService.getProfile();

      if (result['success'] == true) {
        setState(() {
          _userData = result['data']['pengguna'];
          _isLoading = false;
        });
      } else {
        // Jika gagal fetch dari API, tetap gunakan data cache
        if (_userData == null) {
          setState(() {
            _errorMessage = result['message'] ?? 'Gagal memuat data user';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  // Getter untuk mendapatkan URL foto profile
  String get _profilePhotoUrl {
    if (_userData?['foto_profile_url'] != null) {
      return _userData!['foto_profile_url'];
    }
    if (_userData?['foto_profile'] != null) {
      return 'http://192.168.18.58:8000/profile/${_userData!['foto_profile']}';
    }
    return 'https://i.pinimg.com/474x/07/c4/72/07c4720d19a9e9edad9d0e939eca304a.jpg';
  }

  // Getter untuk nama user
  String get _userName {
    if (_isLoading) return 'Loading...';
    if (_userData?['nama_lengkap'] != null) {
      return _userData!['nama_lengkap'];
    }
    return 'User';
  }

  // Getter untuk email user
  String get _userEmail {
    if (_isLoading) return 'Loading...';
    if (_userData?['email'] != null) {
      return _userData!['email'];
    }
    return 'user@example.com';
  }

  // Method untuk handle logout dengan cara yang aman
  Future<void> _logout() async {
    // Set state untuk mencegah multiple clicks
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      // Panggil logout service
      final result = await AuthService.logout();

      // Hanya navigasi jika logout berhasil
      if (result['success'] == true && mounted) {
        // Gunakan WidgetsBinding untuk menunda navigasi
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        });
      } else if (mounted) {
        // Tampilkan error jika logout gagal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout gagal: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoggingOut = false;
        });
      }
    } catch (e) {
      // Tangani error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    if (_isLoggingOut) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final dialogContext = context;

        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            backgroundColor: PurplePalette.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: PurplePalette.lavender.withOpacity(0.3),
              ),
            ),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: PurplePalette.lavender.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: PurplePalette.lavender,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      FontAwesomeIcons.signOutAlt,
                      color: PurplePalette.lavender,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Logout",
                  style: TextStyle(
                    color: PurplePalette.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Are you sure you want to logout?",
                  style: TextStyle(
                    color: PurplePalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "You will need to login again to access your account.",
                  style: TextStyle(
                    color: PurplePalette.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (_isLoggingOut) ...[
                  const SizedBox(height: 16),
                  const Center(
                    child: CircularProgressIndicator(
                      color: PurplePalette.accent,
                    ),
                  ),
                ],
              ],
            ),
            actions: _isLoggingOut
                ? [] // Hilangkan tombol saat loading
                : [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: PurplePalette.textSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: PurplePalette.mauve.withOpacity(0.5),
                          ),
                        ),
                      ),
                      child: const Text("Cancel"),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            PurplePalette.eggplant.withOpacity(0.8),
                            PurplePalette.violet.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          // Tutup dialog terlebih dahulu
                          Navigator.pop(dialogContext);
                          // Jalankan logout
                          await _logout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: PurplePalette.textPrimary,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Logout"),
                      ),
                    ),
                  ],
          ),
        );
      },
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
          "Profile Settings",
          style: TextStyle(
            color: PurplePalette.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'refresh') {
                _loadUserData();
              } else if (value == 'about') {
                _showAboutDialog(context);
              }
            },
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: PurplePalette.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: PurplePalette.mauve.withOpacity(0.5),
                ),
              ),
              child: const Icon(
                Icons.more_vert,
                color: PurplePalette.textPrimary,
              ),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(FontAwesomeIcons.sync, size: 16),
                    SizedBox(width: 8),
                    Text('Refresh Data'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'about',
                child: Row(
                  children: [
                    Icon(FontAwesomeIcons.infoCircle, size: 16),
                    SizedBox(width: 8),
                    Text('About App'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            /// ================= PROFILE HEADER =================
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: PurplePalette.cardBackground,
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    PurplePalette.eggplant.withOpacity(0.8),
                    PurplePalette.violet.withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: PurplePalette.violet.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      _isLoading
                          ? Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: PurplePalette.cardBackground,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: PurplePalette.accent,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: PurplePalette.lavender,
                                  width: 3,
                                ),
                                gradient: const LinearGradient(
                                  colors: [
                                    PurplePalette.orchid,
                                    PurplePalette.lavender,
                                  ],
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 38,
                                backgroundImage: NetworkImage(_profilePhotoUrl),
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                      if (!_isLoading)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditProfilPage(),
                              ),
                            );
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      PurplePalette.lavender.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                FontAwesomeIcons.pencil,
                                color: PurplePalette.accent,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nama User
                        Text(
                          _userName,
                          style: const TextStyle(
                            color: PurplePalette.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Email User
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: PurplePalette.lavender.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: PurplePalette.lavender,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                FontAwesomeIcons.envelope,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _userEmail,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Additional User Info
                        if (_userData != null && !_isLoading)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                // BMI
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        PurplePalette.orchid.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: PurplePalette.orchid,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        FontAwesomeIcons.chartLine,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'BMI: ${_userData!['bmi']?.toStringAsFixed(1) ?? widget.bmi.toStringAsFixed(1)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // Gender
                                if (_userData!['jenis_kelamin'] != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          PurplePalette.lilac.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: PurplePalette.lilac,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _userData!['jenis_kelamin'] == 'L'
                                              ? FontAwesomeIcons.mars
                                              : FontAwesomeIcons.venus,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _userData!['jenis_kelamin'] == 'L'
                                              ? 'Laki-laki'
                                              : 'Perempuan',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// ================= ERROR MESSAGE =================
            if (_errorMessage.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      FontAwesomeIcons.exclamationTriangle,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _errorMessage = '';
                        });
                      },
                      icon: const Icon(
                        FontAwesomeIcons.times,
                        color: Colors.red,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),

            /// ================= SETTINGS SECTIONS =================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    _buildSettingsSection(
                      title: "ACCOUNT SETTINGS",
                      items: [
                        {
                          "icon": FontAwesomeIcons.userEdit,
                          "title": "Edit Profile",
                          "subtitle": "Update your personal information",
                          "color": PurplePalette.orchid,
                          "onTap": () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditProfilPage(),
                              ),
                            );
                          },
                        },
                        {
                          "icon": FontAwesomeIcons.shieldAlt,
                          "title": "Security",
                          "subtitle": "Security and password settings",
                          "color": PurplePalette.orchid,
                          "onTap": () {
                            // Navigasi ke halaman ubah password
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UbahPasswordPage(),
                              ),
                            );
                          },
                        },
                      ],
                    ),
                    const SizedBox(height: 16),

                    /// ================= LOGOUT BUTTON =================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _isLoggingOut
                          ? Container(
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: PurplePalette.cardBackground,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: PurplePalette.accent,
                                ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [
                                    PurplePalette.eggplant.withOpacity(0.8),
                                    PurplePalette.violet.withOpacity(0.8),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        PurplePalette.violet.withOpacity(0.3),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  _showLogoutConfirmation(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: PurplePalette.textPrimary,
                                  shadowColor: Colors.transparent,
                                  minimumSize: const Size(double.infinity, 56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      FontAwesomeIcons.signOutAlt,
                                      size: 20,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      "Logout",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FontAwesomeIcons.codeBranch,
                          color: PurplePalette.lavender,
                          size: 12,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "App Version 1.0.0",
                          style: TextStyle(
                            color: PurplePalette.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Map<String, dynamic>> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: const TextStyle(
              color: PurplePalette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: PurplePalette.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: PurplePalette.mauve.withOpacity(0.3),
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
          child: Column(
            children: List.generate(
              items.length,
              (index) {
                final item = items[index];
                return Column(
                  children: [
                    if (index > 0)
                      Divider(
                        color: PurplePalette.mauve.withOpacity(0.3),
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                      ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              item["color"]!.withOpacity(0.3),
                              item["color"]!.withOpacity(0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: item["color"]!.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            item["icon"] as IconData,
                            color: item["color"] as Color,
                            size: 18,
                          ),
                        ),
                      ),
                      title: Text(
                        item["title"] as String,
                        style: const TextStyle(
                          color: PurplePalette.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        item["subtitle"] as String,
                        style: const TextStyle(
                          color: PurplePalette.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: PurplePalette.cardBackground,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: PurplePalette.mauve.withOpacity(0.5),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            FontAwesomeIcons.chevronRight,
                            color: PurplePalette.textSecondary,
                            size: 14,
                          ),
                        ),
                      ),
                      onTap: item["onTap"] as Function(),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PurplePalette.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: PurplePalette.lavender.withOpacity(0.3),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: PurplePalette.lavender.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: PurplePalette.lavender,
                ),
              ),
              child: const Center(
                child: Icon(
                  FontAwesomeIcons.infoCircle,
                  color: PurplePalette.lavender,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "About App",
              style: TextStyle(
                color: PurplePalette.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "GYM GENZ",
              style: TextStyle(
                color: PurplePalette.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Version: 1.0.0",
              style: TextStyle(
                color: PurplePalette.textSecondary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Developed by: Team GYM GENZ",
              style: TextStyle(
                color: PurplePalette.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "A modern fitness app for the new generation of gym enthusiasts.",
              style: TextStyle(
                color: PurplePalette.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  PurplePalette.eggplant.withOpacity(0.8),
                  PurplePalette.violet.withOpacity(0.8),
                ],
              ),
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: PurplePalette.textPrimary,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Close"),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _isLoggingOut = true;
    super.dispose();
  }
}