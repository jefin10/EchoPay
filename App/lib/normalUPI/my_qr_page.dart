import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class MyQRPage extends StatefulWidget {
  const MyQRPage({super.key});

  @override
  State<MyQRPage> createState() => _MyQRPageState();
}

class _MyQRPageState extends State<MyQRPage> {
  String? _userUpiId;
  String? _userName;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('phoneNumber');
      if (phoneNumber != null) {
        await _fetchUserProfile(phoneNumber);
      } else {
        setState(() {
          _error = 'Phone number not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading user data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserProfile(String phoneNumber) async {
    try {
      final url = Uri.parse('$GET_PROFILE_URL?phoneNumber=$phoneNumber');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _userUpiId = data['upiId'];
          _userName = data['upiName'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to fetch user profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  String _generateQRData() {
    if (_userUpiId == null) return '';
    return 'upi://pay?pa=$_userUpiId&pn=${Uri.encodeComponent(_userName ?? 'User')}&cu=INR';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.ink,
                  strokeWidth: 2.5,
                ),
              )
            : _error != null
                ? _buildErrorState()
                : _buildBody(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: AppColors.coral, size: 28),
            ),
            const SizedBox(height: 18),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadUserData();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _topBar(),
          const SizedBox(height: 28),
          _qrCard(),
          const SizedBox(height: 22),
          _howItWorks(),
          const SizedBox(height: 22),
          _actionButtons(),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: AppColors.ink, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Text('my qr', style: AppTypography.heading(size: 22)),
        const Spacer(),
        GestureDetector(
          onTap: _shareQR,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.share_outlined,
                color: AppColors.ink, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _qrCard() {
    final initial = _userName?.isNotEmpty == true
        ? _userName![0].toUpperCase()
        : 'U';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.pop,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName ?? 'User',
                      style: AppTypography.heading(
                        size: 17,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _userUpiId ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: QrImageView(
              data: _generateQRData(),
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.ink,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'scan to pay me',
            style: AppTypography.eyebrow(
              color: AppColors.pop,
            ),
          ),
        ],
      ),
    );
  }

  Widget _howItWorks() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('how it works', style: AppTypography.eyebrow()),
          const SizedBox(height: 14),
          _step('1', 'Show this QR to anyone who wants to pay you'),
          _step('2', 'They scan it with any UPI app'),
          _step('3', 'Money is received instantly'),
        ],
      ),
    );
  }

  Widget _step(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.pop,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _shareQR,
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text('Share QR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _saveQR,
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Save to gallery'),
          ),
        ),
      ],
    );
  }

  void _shareQR() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature coming soon')),
    );
  }

  void _saveQR() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Save feature coming soon')),
    );
  }
}
