import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  
  late FlutterTts _tts;
  bool _isInitialized = false;
  double _volume = 1.0;
  double _pitch = 1.0;
  double _rate = 0.5; // Slower rate for instructions
  
  // PERBAIKAN: Gunakan flag manual untuk tracking speaking state
  bool _isCurrentlySpeaking = false;
  
  TTSService._internal() {
    _initTTS();
  }
  
  Future<void> _initTTS() async {
    _tts = FlutterTts();
    
    // Configure TTS
    await _tts.setLanguage("id-ID"); // Bahasa Indonesia
    await _tts.setVolume(_volume);
    await _tts.setPitch(_pitch);
    await _tts.setSpeechRate(_rate);
    
    // Set completion handler
    _tts.setCompletionHandler(() {
      _isCurrentlySpeaking = false;
    });
    
    _tts.setStartHandler(() {
      _isCurrentlySpeaking = true;
    });
    
    _tts.setErrorHandler((msg) {
      _isCurrentlySpeaking = false;
      print("TTS Error: $msg");
    });
    
    _isInitialized = true;
    print('TTS Service initialized');
  }
  
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await _initTTS();
    }
    
    if (text.isEmpty) return;
    
    try {
      await _tts.speak(text);
      _isCurrentlySpeaking = true;
    } catch (e) {
      print('TTS Speak error: $e');
      _isCurrentlySpeaking = false;
    }
  }
  
  // PERBAIKAN: Replace getter dengan method
  bool get isSpeaking => _isCurrentlySpeaking;
  
  // ... (sisanya tetap sama)
  
  Future<void> speakInstruction(String exerciseType, String instruction) async {
    final fullInstruction = _getExerciseInstruction(exerciseType, instruction);
    await speak(fullInstruction);
  }
  
  String _getExerciseInstruction(String exerciseType, String instruction) {
    switch (exerciseType.toLowerCase()) {
      case 'pushup':
        return _getPushupInstruction(instruction);
      case 'squat':
        return _getSquatInstruction(instruction);
      case 'shoulder_press':
        return _getShoulderPressInstruction(instruction);
      default:
        return instruction;
    }
  }
  
  String _getPushupInstruction(String instruction) {
    final lowerInstruction = instruction.toLowerCase();
    
    if (lowerInstruction.contains('lurus')) {
      return 'Jaga tubuh tetap lurus seperti papan. Kencangkan perut dan pantat.';
    } else if (lowerInstruction.contains('siku')) {
      return 'Jaga siku membentuk sudut 45 derajat dengan badan. Jangan terlalu keluar.';
    } else if (lowerInstruction.contains('turun')) {
      return 'Turunkan badan sampai dada hampir menyentuh lantai.';
    } else if (lowerInstruction.contains('naik')) {
      return 'Dorong badan kembali ke posisi awal dengan kekuatan dada.';
    } else {
      return instruction;
    }
  }
  
  String _getSquatInstruction(String instruction) {
    final lowerInstruction = instruction.toLowerCase();
    
    if (lowerInstruction.contains('lutut')) {
      return 'Jaga lutut sejajar dengan jari kaki, jangan maju terlalu ke depan.';
    } else if (lowerInstruction.contains('punggung')) {
      return 'Pertahankan punggung lurus, dada terbuka.';
    } else if (lowerInstruction.contains('pinggul')) {
      return 'Dorong pinggul ke belakang seperti mau duduk di kursi.';
    } else if (lowerInstruction.contains('tumit')) {
      return 'Berat badan di tumit, jangan angkat tumit dari lantai.';
    } else {
      return instruction;
    }
  }
  
  String _getShoulderPressInstruction(String instruction) {
    final lowerInstruction = instruction.toLowerCase();
    
    if (lowerInstruction.contains('siku')) {
      return 'Jaga siku sedikit di depan badan saat mulai mengangkat.';
    } else if (lowerInstruction.contains('punggung')) {
      return 'Kencangkan perut untuk melindungi punggung bawah.';
    } else if (lowerInstruction.contains('angkat')) {
      return 'Angkat beban lurus ke atas, jangan menggunakan momentum.';
    } else {
      return instruction;
    }
  }
  
  Future<void> speakRepCount(int reps) async {
    await speak('Repetisi ke $reps');
  }
  
  Future<void> speakMotivation() async {
    final motivations = [
      'Bagus! Lanjutkan!',
      'Kamu kuat!',
      'Satu lagi!',
      'Pertahankan form yang baik!',
      'Kamu bisa!',
      'Jangan menyerah!',
      'Form kamu bagus!',
      'Lakukan dengan perlahan dan terkontrol',
    ];
    
    final randomIndex = DateTime.now().millisecondsSinceEpoch % motivations.length;
    await speak(motivations[randomIndex]);
  }
  
  Future<void> stop() async {
    await _tts.stop();
    _isCurrentlySpeaking = false;
  }
  
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _tts.setVolume(_volume);
  }
  
  Future<void> setRate(double rate) async {
    _rate = rate.clamp(0.0, 1.0);
    await _tts.setSpeechRate(_rate);
  }
  
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    await _tts.setPitch(_pitch);
  }
  
  Future<void> dispose() async {
    await _tts.stop();
    _isCurrentlySpeaking = false;
  }
}