import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _userName = 'John Doe';
  String _userPhone = '+91 9876543210';
  String _userUPI = 'john.doe@paytm';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString('signedUpPhoneNumber');
    if (phoneNumber != null) {
      try {
        final response = await Uri.parse('$GET_PROFILE_URL?phoneNumber=$phoneNumber');
        final res = await http.get(response);
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          setState(() {
            _userName = data['upiName'] ?? 'Unknown';
            _userPhone = phoneNumber;
            _userUPI = data['upiId'] ?? 'Unknown';
          });
        } else {
          setState(() {
            _userName = 'Unknown';
            _userPhone = phoneNumber;
            _userUPI = 'Unknown';
          });
        }
      } catch (e) {
        setState(() {
          _userName = 'Unknown';
          _userPhone = phoneNumber;
          _userUPI = 'Unknown';
        });
      }
    } else {
      setState(() {
        _userName = 'John Doe';
        _userPhone = 'Couldnt find the logged in Number';
        _userUPI = 'john.doe@paytm';
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.setBool('isSignedUp', false);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/signup');
    }
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
            const SizedBox(height: 30),

            // Profile Header
            _buildProfileHeader(),
            const SizedBox(height: 40),

            // Profile Options
            Expanded(
              child: _buildProfileOptions(),
            ),

            // Logout Button
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Icon(
          Icons.arrow_back_ios,
          color: Colors.transparent,
          size: 24,
        ),
        const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          onPressed: () {
            // Edit profile
          },
          icon: const Icon(
            Icons.edit,
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 3,
            ),
          ),
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 60,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _userName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _userPhone,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2B5A),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            _userUPI,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileOptions() {
    return ListView(
      children: [
        _buildOptionTile(
          Icons.account_balance_wallet,
          'Wallet & Bank Accounts',
          'Manage your payment methods',
          const Color(0xFF10B981),
          () {},
        ),
        _buildOptionTile(
          Icons.security,
          'Security & Privacy',
          'PIN, biometric, and privacy settings',
          const Color(0xFF3B82F6),
          () {},
        ),
        _buildOptionTile(
          Icons.history,
          'Transaction History',
          'View all your transactions',
          const Color(0xFF8B5CF6),
          () {},
        ),
        _buildOptionTile(
          Icons.help_outline,
          'Help & Support',
          'FAQs, contact support',
          const Color(0xFFF59E0B),
          () {},
        ),
        _buildOptionTile(
          Icons.settings,
          'Settings',
          'App preferences and configurations',
          const Color(0xFF6B7280),
          () {},
        ),
        _buildOptionTile(
          Icons.info_outline,
          'About',
          'App version and legal information',
          const Color(0xFF06B6D4),
          () {},
        ),
      ],
    );
  }

  Widget _buildOptionTile(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2B5A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
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
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2B5A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ElevatedButton(
        onPressed: _logout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.logout,
              color: Color(0xFFEF4444),
              size: 24,
            ),
            const SizedBox(width: 10),
            const Text(
              'Logout',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
