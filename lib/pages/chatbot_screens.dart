import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ChatbotScreens extends StatefulWidget {
  const ChatbotScreens({Key? key}) : super(key: key);

  @override
  State<ChatbotScreens> createState() => _ChatbotScreensState();
}

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class _ChatbotScreensState extends State<ChatbotScreens> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  // Purple palette untuk konsistensi dengan home.dart
  static const Color background = Color(0xFF08030C);
  static const Color cardBackground = Color(0xFF2C123A);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFC7B8D6);
  static const Color accent = Color(0xFFA32CC4);
  static const Color lavender = Color(0xFFE39FF6);
  static const Color amethyst = Color(0xFF9966CC);
  static const Color wildberry = Color(0xFF8B2991);
  static const Color iris = Color(0xFF9866C5);
  static const Color orchid = Color(0xFFAF69EE);

  // Responses untuk chatbot (Gen Z style)
  final List<Map<String, dynamic>> _botResponses = [
    {
      'keywords': ['hai', 'hello', 'halo', 'hi', 'hey', 'hallo'],
      'responses': [
        'Yow! 👋 Ada yang bisa gue bantu soal workout?',
        'Wassup bro! 💪 Ready to crush some gains?',
        'Halo! Gym time? Let\'s gooo! 🔥',
        'Hey there! Ada yang mau ditanyain soal gym?'
      ]
    },
    {
      'keywords': ['workout', 'latihan', 'olahraga', 'exercise'],
      'responses': [
        'Workout itu kunci! Mau yang cardio atau strength training? 🏋️‍♂️',
        'Gue recommend full body workout 3x seminggu buat pemula!',
        'Jangan lupa warm up dulu sebelum workout, bro!',
        'Consistency is key! Better 30 mins daily than 3 hours once a week 💯'
      ]
    },
    {
      'keywords': ['diet', 'makan', 'nutrisi', 'protein'],
      'responses': [
        'Protein is king! 🍗 Aim for 1.6-2.2g per kg berat badan',
        'Carbs bukan musuh! Mereka bahan bakar buat workout 💪',
        'Stay hydrated bro! Minum air putih itu wajib! 💧',
        'Meal prep bisa save time dan bantu diet lebih konsisten 📝'
      ]
    },
    {
      'keywords': ['cardio', 'lari', 'treadmill', 'sepeda'],
      'responses': [
        'Cardio mantap buat burning calories! 150 mins per week recommended 🏃‍♂️',
        'HIIT > steady state cardio buat fat loss! Try it!',
        'Jangan lupa cool down setelah cardio, bro!',
        'LISS cardio juga bagus buat recovery days 🤙'
      ]
    },
    {
      'keywords': ['strength', 'angkat', 'beban', 'dumbell'],
      'responses': [
        'Progressive overload itu wajib! Tambah berat atau reps setiap minggu 🏋️',
        'Form > ego lifting! Better safe than sorry bro!',
        'Compound movements FTW! Squat, deadlift, bench press 🚀',
        'Rest between sets penting banget! 1-3 minutes ideal 💤'
      ]
    },
    {
      'keywords': ['recovery', 'istirahat', 'tidur', 'pemulihan'],
      'responses': [
        'Sleep is non-negotiable! 7-9 hours per night, bro 😴',
        'Recovery sama pentingnya dengan workout! Listen to your body',
        'Foam rolling bisa bantu kurangi muscle soreness 🎯',
        'Active recovery > total rest! Coba jalan kaki atau stretching ringan'
      ]
    },
    {
      'keywords': ['motivasi', 'malas', 'bosan', 'semangat'],
      'responses': [
        'Don\'t stop when you\'re tired, stop when you\'re done! 💯',
        'Progress takes time! Trust the process bro 🌱',
        'Every expert was once a beginner! Keep grinding!',
        'The only bad workout is the one that didn\'t happen! 🚀'
      ]
    },
    {
      'keywords': ['bmi', 'berat', 'badan', 'ideal'],
      'responses': [
        'BMI cuma salah satu indikator! Muscle lebih berat daripada fat 💪',
        'Focus on body composition, not just weight!',
        'Progress pics > scale! Take photos setiap bulan 📸',
        'How you feel > how you look! Health is the real goal 🌟'
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    // Add initial bot message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addBotMessage(
          'Yo! Gue GymBro 🤖, personal AI trainer kamu! '
          'Ada yang mau ditanyain soal workout, diet, atau butuh motivasi? 🔥',
          false);
    });
  }

  void _addBotMessage(String text, bool isUser) {
    setState(() {
      _messages.add(Message(
        text: text,
        isUser: isUser,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String _getBotResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();
    
    // Cari response berdasarkan keyword
    for (var responseGroup in _botResponses) {
      for (var keyword in responseGroup['keywords'] as List<String>) {
        if (lowerMessage.contains(keyword)) {
          final responses = responseGroup['responses'] as List<String>;
          return responses[DateTime.now().millisecondsSinceEpoch % responses.length];
        }
      }
    }
    
    // Default responses
    final defaultResponses = [
      'Interesting question! Bisa jelasin lebih detail? 🤔',
      'Gue masih belajar nih! Coba tanya soal workout atau diet dulu! 💪',
      'Waduh, itu di luar expertise gue bro! Tanya trainer langsung mungkin?',
      'Try to ask about workout routines or nutrition tips! 🏋️‍♂️',
      'Good question! Mau gue cariin info lebih lanjut?',
      'Hold up! Let me think about that... 🧠',
      'That\'s deep bro! But honestly, consistency is the real answer 💯',
    ];
    
    return defaultResponses[DateTime.now().millisecondsSinceEpoch % defaultResponses.length];
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Add user message
    _addBotMessage(text, true);
    _messageController.clear();

    // Show loading
    setState(() {
      _isLoading = true;
    });

    // Simulate bot thinking
    Future.delayed(const Duration(seconds: 1), () {
      final response = _getBotResponse(text);
      _addBotMessage(response, false);
      setState(() {
        _isLoading = false;
      });
    });
  }

  void _showQuickReplies() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final quickQuestions = [
          'Workout buat pemula?',
          'Tips diet yang sehat?',
          'Cardio vs strength training?',
          'Butuh motivasi!',
          'Berapa kali workout per minggu?',
          'Protein sources terbaik?',
          'Cara kurangi muscle soreness?',
          'Workout tanpa equipment?',
        ];

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Quick Questions 🤙',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: quickQuestions.map((question) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _messageController.text = question;
                      _sendMessage();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accent.withOpacity(0.4)),
                      ),
                      child: Text(
                        question,
                        style: const TextStyle(
                          color: lavender,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: wildberry,
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [wildberry, amethyst],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Icon(
                  FontAwesomeIcons.solidMessage,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser ? accent : cardBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                    ),
                    gradient: isUser
                        ? const LinearGradient(
                            colors: [accent, iris],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [cardBackground.withOpacity(0.8), cardBackground],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    border: Border.all(
                      color: isUser ? Colors.transparent : lavender.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : textPrimary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    color: textSecondary.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [orchid, accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Icon(
                  FontAwesomeIcons.user,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(FontAwesomeIcons.chevronLeft),
          color: textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [wildberry, amethyst],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(
                  FontAwesomeIcons.solidMessage,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GymBro AI',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Online • Gen Z Style',
                  style: TextStyle(
                    color: lavender,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.bolt),
            color: lavender,
            onPressed: _showQuickReplies,
          ),
          IconButton(
            icon: const Icon(FontAwesomeIcons.ellipsisVertical),
            color: textSecondary,
            onPressed: () {
              // Show options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [wildberry, amethyst],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: Text(
                              '🤖',
                              style: TextStyle(fontSize: 36),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'GymBro AI 🤖',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ask me anything about fitness!\nGen Z style answers guaranteed 🔥',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: lavender.withOpacity(0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                FontAwesomeIcons.lightbulb,
                                color: lavender,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Try: "Workout buat pemula?"',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // Typing indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cardBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        '🤖',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTypingDot(0),
                        _buildTypingDot(1),
                        _buildTypingDot(2),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBackground,
              border: Border(
                top: BorderSide(color: lavender.withOpacity(0.1)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: lavender.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(color: textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Type your message...',
                              hintStyle: TextStyle(color: textSecondary.withOpacity(0.6)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            FontAwesomeIcons.faceSmile,
                            color: lavender,
                            size: 20,
                          ),
                          onPressed: () {
                            // Emoji picker
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [accent, orchid],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      FontAwesomeIcons.paperPlane,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: lavender.withOpacity(0.5),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}