import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/service/auth_services.dart';

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

class EditProfilPage extends StatefulWidget {
  const EditProfilPage({super.key});

  @override
  State<EditProfilPage> createState() => _EditProfilPageState();
}

class _EditProfilPageState extends State<EditProfilPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _tinggiBadanController = TextEditingController();
  final _beratBadanController = TextEditingController();
  final _alergiController = TextEditingController();

  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _jenisKelamin;
  String? _golonganDarah;
  File? _fotoProfile;
  String _errorMessage = '';
  String _successMessage = '';

  final List<Map<String, dynamic>> _golonganDarahList = [
    {'value': null, 'label': 'Pilih Golongan Darah'},
    {'value': 'A', 'label': 'A'},
    {'value': 'B', 'label': 'B'},
    {'value': 'AB', 'label': 'AB'},
    {'value': 'O', 'label': 'O'},
  ];

  final ImagePicker _picker = ImagePicker();

  // Variabel untuk menandai apakah widget masih mounted
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _loadUserData();
  }

  @override
  void dispose() {
    _isMounted = false;
    _namaController.dispose();
    _tinggiBadanController.dispose();
    _beratBadanController.dispose();
    _alergiController.dispose();
    super.dispose();
  }

  // Helper method untuk aman memanggil setState
  void _safeSetState(VoidCallback fn) {
    if (_isMounted) {
      setState(fn);
    }
  }

  // Method untuk memuat data user
  Future<void> _loadUserData() async {
    try {
      _safeSetState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final result = await AuthService.getProfile();

      if (result['success'] == true && _isMounted) {
        final userData = result['data']['pengguna'];
        _safeSetState(() {
          _userData = userData;
          _namaController.text = userData['nama_lengkap'] ?? '';
          _jenisKelamin = userData['jenis_kelamin'];
          _tinggiBadanController.text = userData['tinggi_badan']?.toString() ?? '';
          _beratBadanController.text = userData['berat_badan']?.toString() ?? '';
          _alergiController.text = userData['alergi'] ?? '';
          _golonganDarah = userData['golongan_darah'];
          _isLoading = false;
        });
      } else if (_isMounted) {
        _safeSetState(() {
          _errorMessage = result['message'] ?? 'Gagal memuat data user';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (_isMounted) {
        _safeSetState(() {
          _errorMessage = 'Terjadi kesalahan: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null && _isMounted) {
        _safeSetState(() {
          _fotoProfile = File(image.path);
        });
      }
    } catch (e) {
      if (_isMounted) {
        _showSnackBar('Gagal memilih gambar: $e');
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_jenisKelamin == null) {
      _showSnackBar('Pilih jenis kelamin terlebih dahulu');
      return;
    }

    _safeSetState(() {
      _isSaving = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final result = await AuthService.updateProfile(
        namaLengkap: _namaController.text.trim(),
        jenisKelamin: _jenisKelamin!,
        tinggiBadan: _tinggiBadanController.text.isNotEmpty
            ? double.tryParse(_tinggiBadanController.text)
            : null,
        beratBadan: _beratBadanController.text.isNotEmpty
            ? double.tryParse(_beratBadanController.text)
            : null,
        alergi: _alergiController.text.isNotEmpty
            ? _alergiController.text.trim()
            : null,
        golonganDarah: _golonganDarah,
        fotoProfile: _fotoProfile,
      );

      if (_isMounted) {
        if (result['success'] == true) {
          _safeSetState(() {
            _successMessage = result['message'];
            _isSaving = false;
            // Update local user data
            _userData = result['data']['pengguna'];
          });

          // Tampilkan dialog sukses
          _showSuccessDialog(result['message']);

          // Refresh data setelah 2 detik
          Future.delayed(const Duration(seconds: 2), () {
            if (_isMounted) {
              _loadUserData();
            }
          });
        } else {
          _safeSetState(() {
            _errorMessage = result['message'];
            _isSaving = false;
          });
        }
      }
    } catch (e) {
      if (_isMounted) {
        _safeSetState(() {
          _errorMessage = 'Terjadi kesalahan: $e';
          _isSaving = false;
        });
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // Timer untuk auto close dialog setelah 3 detik
        Future.delayed(const Duration(seconds: 3), () {
          if (_isMounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });

        return AlertDialog(
          backgroundColor: PurplePalette.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: PurplePalette.lavender.withOpacity(0.3),
            ),
          ),
          title: const Text(
                "Sukses!",
                style: TextStyle(
                  color: PurplePalette.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                FontAwesomeIcons.userCheck,
                color: PurplePalette.lavender,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  color: PurplePalette.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Data akan diperbarui dalam beberapa detik...",
                style: TextStyle(
                  color: PurplePalette.textSecondary.withOpacity(0.7),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackBar(String message) {
    if (_isMounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String? _validateNama(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama lengkap wajib diisi';
    }
    if (value.length < 3) {
      return 'Nama minimal 3 karakter';
    }
    return null;
  }

  String? _validateTinggiBadan(String? value) {
    if (value != null && value.isNotEmpty) {
      final tinggi = double.tryParse(value);
      if (tinggi == null) {
        return 'Masukkan angka yang valid';
      }
      if (tinggi < 50 || tinggi > 250) {
        return 'Tinggi badan harus antara 50-250 cm';
      }
    }
    return null;
  }

  String? _validateBeratBadan(String? value) {
    if (value != null && value.isNotEmpty) {
      final berat = double.tryParse(value);
      if (berat == null) {
        return 'Masukkan angka yang valid';
      }
      if (berat < 20 || berat > 300) {
        return 'Berat badan harus antara 20-300 kg';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PurplePalette.background,
      appBar: AppBar(
        backgroundColor: PurplePalette.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
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
              Icons.arrow_back_ios_new_rounded,
              color: PurplePalette.textPrimary,
              size: 20,
            ),
          ),
        ),
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            color: PurplePalette.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: PurplePalette.accent,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: PurplePalette.accent,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// ================= SUCCESS MESSAGE =================
                    if (_successMessage.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: PurplePalette.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: PurplePalette.success),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              FontAwesomeIcons.checkCircle,
                              color: PurplePalette.success,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _successMessage,
                                style: const TextStyle(
                                  color: PurplePalette.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    /// ================= ERROR MESSAGE =================
                    if (_errorMessage.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
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
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                _safeSetState(() {
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

                    /// ================= FOTO PROFILE =================
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        PurplePalette.orchid,
                                        PurplePalette.lavender,
                                      ],
                                    ),
                                    border: Border.all(
                                      color: PurplePalette.lavender,
                                      width: 3,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(60),
                                    child: _fotoProfile != null
                                        ? Image.file(
                                            _fotoProfile!,
                                            fit: BoxFit.cover,
                                          )
                                        : (_userData?['foto_profile_url'] != null
                                            ? Image.network(
                                                _userData!['foto_profile_url'],
                                                fit: BoxFit.cover,
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) return child;
                                                  return Center(
                                                    child: CircularProgressIndicator(
                                                      value: loadingProgress.expectedTotalBytes != null
                                                          ? loadingProgress.cumulativeBytesLoaded /
                                                              loadingProgress.expectedTotalBytes!
                                                          : null,
                                                      color: PurplePalette.lavender,
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (context, error, stackTrace) {
                                                  return const Icon(
                                                    FontAwesomeIcons.user,
                                                    color: Colors.white,
                                                    size: 40,
                                                  );
                                                },
                                              )
                                            : const Icon(
                                                FontAwesomeIcons.user,
                                                color: Colors.white,
                                                size: 40,
                                              )),
                                  ),
                                ),
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: PurplePalette.lavender.withOpacity(0.5),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      FontAwesomeIcons.camera,
                                      color: PurplePalette.accent,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _fotoProfile != null ? "Foto baru terpilih" : "Klik untuk ubah foto",
                            style: const TextStyle(
                              color: PurplePalette.lavender,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// ================= NAMA LENGKAP =================
                    _buildTextField(
                      controller: _namaController,
                      label: "Nama Lengkap",
                      hint: "Masukkan nama lengkap Anda",
                      icon: FontAwesomeIcons.user,
                      validator: _validateNama,
                    ),

                    const SizedBox(height: 20),

                    /// ================= JENIS KELAMIN =================
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Jenis Kelamin *",
                          style: TextStyle(
                            color: PurplePalette.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildGenderOption(
                                value: 'L',
                                label: 'Laki-laki',
                                icon: FontAwesomeIcons.mars,
                                isSelected: _jenisKelamin == 'L',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildGenderOption(
                                value: 'P',
                                label: 'Perempuan',
                                icon: FontAwesomeIcons.venus,
                                isSelected: _jenisKelamin == 'P',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// ================= TINGGI & BERAT BADAN =================
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _tinggiBadanController,
                            label: "Tinggi Badan (cm)",
                            hint: "Contoh: 175 (50-250 cm)",
                            icon: FontAwesomeIcons.rulerVertical,
                            validator: _validateTinggiBadan,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _beratBadanController,
                            label: "Berat Badan (kg)",
                            hint: "Contoh: 70 (20-300 kg)",
                            icon: FontAwesomeIcons.weight,
                            validator: _validateBeratBadan,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),

                    /// ================= BMI INFO =================
                    if (_userData?['bmi'] != null)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: PurplePalette.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: PurplePalette.orchid.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "BMI Anda:",
                              style: TextStyle(
                                color: PurplePalette.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: PurplePalette.orchid.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: PurplePalette.orchid,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    _userData!['bmi']?.toStringAsFixed(1) ?? '0.0',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _userData!['bmi_category'] ?? 'Normal',
                                    style: const TextStyle(
                                      color: PurplePalette.lavender,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    /// ================= ALERGI =================
                    _buildTextField(
                      controller: _alergiController,
                      label: "Alergi (Opsional)",
                      hint: "Contoh: udang, kacang, seafood",
                      icon: FontAwesomeIcons.exclamationTriangle,
                      maxLines: 2,
                    ),

                    const SizedBox(height: 20),

                    /// ================= GOLONGAN DARAH =================
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Golongan Darah",
                          style: TextStyle(
                            color: PurplePalette.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: PurplePalette.cardBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: PurplePalette.mauve.withOpacity(0.3),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _golonganDarah,
                              isExpanded: true,
                              dropdownColor: PurplePalette.cardBackground,
                              icon: const Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: Icon(
                                  FontAwesomeIcons.chevronDown,
                                  color: PurplePalette.textSecondary,
                                  size: 18,
                                ),
                              ),
                              style: const TextStyle(
                                color: PurplePalette.textPrimary,
                                fontSize: 16,
                              ),
                              hint: Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Text(
                                  "Pilih Golongan Darah",
                                  style: TextStyle(
                                    color: PurplePalette.textSecondary.withOpacity(0.7),
                                  ),
                                ),
                              ),
                              items: _golonganDarahList.map((item) {
                                return DropdownMenuItem<String>(
                                  value: item['value'],
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: Text(
                                      item['label'],
                                      style: TextStyle(
                                        color: item['value'] == null
                                            ? PurplePalette.textSecondary.withOpacity(0.7)
                                            : PurplePalette.textPrimary,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                _safeSetState(() {
                                  _golonganDarah = newValue;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    /// ================= SIMPAN BUTTON =================
                    Container(
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
                            color: PurplePalette.violet.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: PurplePalette.textPrimary,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    FontAwesomeIcons.save,
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    "Simpan Perubahan",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// ================= BATAL BUTTON =================
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: PurplePalette.mauve.withOpacity(0.5),
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? null
                            : () {
                                Navigator.pop(context);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: PurplePalette.textSecondary,
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
                              FontAwesomeIcons.times,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Batal",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: PurplePalette.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: PurplePalette.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: PurplePalette.cardBackground,
            hintText: hint,
            hintStyle: TextStyle(
              color: PurplePalette.textSecondary.withOpacity(0.7),
            ),
            prefixIcon: Icon(
              icon,
              color: PurplePalette.textSecondary,
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: PurplePalette.accent,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderOption({
    required String value,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        _safeSetState(() {
          _jenisKelamin = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? PurplePalette.orchid.withOpacity(0.2)
              : PurplePalette.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? PurplePalette.orchid : PurplePalette.mauve.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? PurplePalette.lavender : PurplePalette.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? PurplePalette.textPrimary : PurplePalette.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}