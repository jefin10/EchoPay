import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
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
  bool _serverConnected = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _checkServerConnection();
  }

  Future<void> _checkServerConnection() async {
    final isConnected = await IntentService.checkServerHealth();
    if (mounted) setState(() => _serverConnected = isConnected);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopRow(),
              const SizedBox(height: 28),
              Text(
                'speak it.\nwe pay it.',
                style: AppTypography.heading(
                  size: 38,
                  weight: FontWeight.w800,
                ).copyWith(height: 1.05),
              ),
              const SizedBox(height: 12),
              Text(
                'Say a name, an amount, and we will line it up.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),

              const Spacer(),
              Center(child: _buildMicButton()),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'tap to speak',
                  style: AppTypography.eyebrow(color: AppColors.textSecondary),
                ),
              ),
              const Spacer(),

              _buildSamples(),
              const SizedBox(height: 16),
              _buildStartButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        Text('voice', style: AppTypography.heading(size: 22)),
        const SizedBox(width: 6),
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.pop,
            shape: BoxShape.circle,
          ),
        ),
        const Spacer(),
        _statusChip(),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _showHelpDialog,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.help_outline_rounded,
              color: AppColors.ink,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip() {
    return GestureDetector(
      onTap: _checkServerConnection,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: _serverConnected ? AppColors.mint : AppColors.coral,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              _serverConnected ? 'Online' : 'Offline',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SpeechScreen()),
      ),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 200 * _pulseAnimation.value,
                height: 200 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.pop.withOpacity(0.18),
                ),
              ),
              Container(
                width: 160,
                height: 160,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.ink,
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: AppColors.pop,
                  size: 64,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSamples() {
    final samples = const [
      'Send ₹500 to 9876543210',
      "What's my balance?",
      'Request ₹300 from Mom',
    ];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: samples.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SpeechScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.graphic_eq_rounded,
                    color: AppColors.primary, size: 14),
                const SizedBox(width: 6),
                Text(
                  '"${samples[i]}"',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SpeechScreen()),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic_rounded, size: 20),
            SizedBox(width: 10),
            Text('Start voice command'),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('voice playbook', style: AppTypography.eyebrow()),
              const SizedBox(height: 8),
              Text('Things you can say', style: AppTypography.heading(size: 22)),
              const SizedBox(height: 22),
              _helpItem(Icons.send_rounded, 'Send money',
                  '"Send 500 to John"'),
              _helpItem(Icons.account_balance_wallet_outlined, 'Check balance',
                  "\"What's my balance?\""),
              _helpItem(Icons.call_received_rounded, 'Request money',
                  '"Request 300 from Mom"'),
              _helpItem(Icons.chat_bubble_outline_rounded, 'Just chat',
                  '"Hello, how are you?"'),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _helpItem(IconData icon, String title, String example) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceDim,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.ink, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  example,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
