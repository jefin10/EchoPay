import 'package:flutter/material.dart';
import '../voiceToText/voiceToText.dart';
import '../services/intent_service.dart';

class VoiceAssistantPage extends StatefulWidget {
  const VoiceAssistantPage({super.key});

  @override
  State<VoiceAssistantPage> createState() => _VoiceAssistantPageState();
}

class _VoiceAssistantPageState extends State<VoiceAssistantPage> 
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isListening = false;
  bool _serverConnected = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _checkServerConnection();
  }

  void _checkServerConnection() async {
    final isConnected = await IntentService.checkServerHealth();
    setState(() {
      _serverConnected = isConnected;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(),
            const SizedBox(height: 40),

            // Voice Assistant Title
            _buildTitle(),
            const SizedBox(height: 40),

            // Main Voice Interface
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildVoiceInterface(),
                  const SizedBox(height: 40),
                  _buildQuickCommands(),
                ],
              ),
            ),

            // Quick Access Button
            _buildQuickAccessButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            // Show help dialog
            _showHelpDialog();
          },
          icon: const Icon(
            Icons.help_outline,
            color: Colors.white,
            size: 24,
          ),
        ),
        const Text(
          'Voice Assistant',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            // Server status indicator
            GestureDetector(
              onTap: _checkServerConnection,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _serverConnected 
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _serverConnected ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _serverConnected ? Icons.cloud_done : Icons.cloud_off,
                      color: _serverConnected ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _serverConnected ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: _serverConnected ? Colors.green : Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.settings,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Voice Assistant Help'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Available Commands:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text('💰 Transfer Money:'),
                Text('  "Send 500 rupees to 9876543210"'),
                Text('  "Transfer 1000 to john@upi"'),
                SizedBox(height: 8),
                Text('💳 Check Balance:'),
                Text('  "What is my balance?"'),
                Text('  "Check my account balance"'),
                SizedBox(height: 8),
                Text('💸 Request Money:'),
                Text('  "Request 300 from 9876543210"'),
                Text('  "Ask dad for 500 rupees"'),
                SizedBox(height: 8),
                Text('💬 General Chat:'),
                Text('  "Hello, how are you?"'),
                Text('  "Tell me about yourself"'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it!'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        const Text(
          'How can I help you?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'I can transfer money, check balance, handle requests, or just chat!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF6366F1).withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.psychology,
                color: const Color(0xFF6366F1),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'AI-Powered Voice Assistant',
                style: TextStyle(
                  color: const Color(0xFF6366F1),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceInterface() {
    return Column(
      children: [
        // Main Microphone Button
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SpeechScreen(),
              ),
            );
          },
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isListening ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isListening
                          ? [
                              const Color(0xFF10B981),
                              const Color(0xFF059669),
                              const Color(0xFF047857),
                            ]
                          : [
                              const Color(0xFF6366F1),
                              const Color(0xFF8B5CF6),
                              const Color(0xFFA855F7),
                            ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening 
                            ? const Color(0xFF10B981) 
                            : const Color(0xFF6366F1)).withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 80,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 30),

        // Status Text
        Text(
          _isListening ? 'Listening...' : 'Tap to speak',
          style: TextStyle(
            color: _isListening ? const Color(0xFF10B981) : Colors.grey[400],
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickCommands() {
    final commands = [
      {
        'text': 'Send ₹500 to 9876543210',
        'description': 'Transfer money to phone number',
        'icon': Icons.send,
        'color': Colors.green,
      },
      {
        'text': 'Check my balance',
        'description': 'View current account balance',
        'icon': Icons.account_balance_wallet,
        'color': Colors.blue,
      },
      {
        'text': 'Request ₹300 from 9123456789',
        'description': 'Request money from contact',
        'icon': Icons.request_quote,
        'color': Colors.purple,
      },
      {
        'text': 'Hello, how are you?',
        'description': 'General conversation',
        'icon': Icons.chat,
        'color': Colors.orange,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Try saying:',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 15),
        ...commands.map((command) => _buildEnhancedCommandChip(command)).toList(),
      ],
    );
  }

  Widget _buildEnhancedCommandChip(Map<String, dynamic> command) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SpeechScreen(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF2A2B5A),
                const Color(0xFF2A2B5A).withOpacity(0.8),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (command['color'] as Color).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (command['color'] as Color).withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (command['color'] as Color).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  command['icon'] as IconData,
                  color: command['color'] as Color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '"${command['text']}"',
                      style: TextStyle(
                        color: Colors.grey[200],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      command['description'] as String,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[500],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SpeechScreen(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Text(
          'Start Voice Command',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
