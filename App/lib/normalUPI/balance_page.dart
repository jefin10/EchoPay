import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';

class BalancePage extends StatefulWidget {
  const BalancePage({super.key});

  @override
  State<BalancePage> createState() => _BalancePageState();
}

class _BalancePageState extends State<BalancePage> {
  double _currentBalance = 10.0;
  bool _isLoading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString('signedUpPhoneNumber');
    print(phoneNumber);
    if (phoneNumber != null) {
      try {
        final url = Uri.parse('$GET_BALANCE_URL?phoneNumber=$phoneNumber');
        final response = await http.get(url);
        print(response.body);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print(data);
          setState(() {
            _currentBalance = double.tryParse(data['balance'].toString()) ?? 100.0;
            _isLoading = false;
            _error = null;
          });
        }
        else {
          setState(() {
            _isLoading = false;
            _error = 'Failed to fetch balance: ${response.statusCode}';
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _error = 'Error: $e';
        });
      }
    }
    else {
      setState(() {
        _isLoading = false;
        _error = 'Phone number not found.';
      });
    }
  }
  bool _isBalanceVisible = true;

  final List<Map<String, dynamic>> _accounts = [
    {
      'bank': 'State Bank of India',
      'accountNumber': '****1234',
      'balance': 15000.50,
      'isDefault': true,
    },
    {
      'bank': 'HDFC Bank',
      'accountNumber': '****5678',
      'balance': 8500.25,
      'isDefault': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
  return Scaffold(
      backgroundColor: const Color(0xFF1A1B3A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Account Balance',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isBalanceVisible ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isBalanceVisible = !_isBalanceVisible;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Balance Card
            _buildMainBalanceCard(),
            const SizedBox(height: 30),

            // Quick Actions
            _buildQuickActions(),
            const SizedBox(height: 30),

            // Linked Accounts
            const Text(
              'Linked Accounts',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),

            // Account List
            Expanded(
              child: _buildAccountList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainBalanceCard() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    if (_error != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
              Color(0xFFA855F7),
            ],
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
            Color(0xFFA855F7),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Balance',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  'UPI Wallet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            _isBalanceVisible 
                ? '₹${_currentBalance.toStringAsFixed(2)}'
                : '₹••••••',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.trending_up,
                color: Color(0xFF10B981),
                size: 16,
              ),
              const SizedBox(width: 5),
              Text(
                '+₹2,450 this month',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildQuickAction(
          Icons.add,
          'Add Money',
          const Color(0xFF10B981),
          () {
            // Add money functionality
          },
        ),
        _buildQuickAction(
          Icons.send,
          'Send Money',
          const Color(0xFF3B82F6),
          () {
            // Send money functionality
          },
        ),
        _buildQuickAction(
          Icons.request_page,
          'Request',
          const Color(0xFFF59E0B),
          () {
            // Request money functionality
          },
        ),
        _buildQuickAction(
          Icons.history,
          'History',
          const Color(0xFF8B5CF6),
          () {
            // Transaction history
          },
        ),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2B5A),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountList() {
    return ListView.builder(
      itemCount: _accounts.length + 1, // +1 for add account option
      itemBuilder: (context, index) {
        if (index == _accounts.length) {
          return _buildAddAccountTile();
        }
        return _buildAccountTile(_accounts[index]);
      },
    );
  }

  Widget _buildAccountTile(Map<String, dynamic> account) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2B5A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: account['isDefault'] 
              ? const Color(0xFF10B981).withOpacity(0.5)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.account_balance,
              color: Color(0xFF6366F1),
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      account['bank'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (account['isDefault'])
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'DEFAULT',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      account['accountNumber'],
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _isBalanceVisible 
                          ? '₹${account['balance'].toStringAsFixed(2)}'
                          : '₹••••••',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddAccountTile() {
    return GestureDetector(
      onTap: () {
        // Add new account functionality
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2B5A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.add,
                color: Color(0xFF6366F1),
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            const Text(
              'Add New Bank Account',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
