import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class PayToContactsPage extends StatefulWidget {
  @override
  _PayToContactsPageState createState() => _PayToContactsPageState();
}

class _PayToContactsPageState extends State<PayToContactsPage> {
  List<Contact>? contacts;
  bool loading = true;
  bool permissionDenied = false;

  @override
  void initState() {
    super.initState();
    fetchContacts();
  }

  Future<void> fetchContacts() async {
    var status = await Permission.contacts.request();
    if (status.isGranted) {
      final fetchedContacts = await FlutterContacts.getContacts(withProperties: true);
      setState(() {
        contacts = fetchedContacts;
        loading = false;
        permissionDenied = false;
      });
    } else {
      setState(() {
        loading = false;
        permissionDenied = true;
      });
    }
  }

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
          'Pay to Contacts',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : permissionDenied
              ? const Center(
                  child: Text('Permission denied. Please enable contacts permission.', style: TextStyle(color: Colors.white)),
                )
              : contacts == null || contacts!.isEmpty
                  ? const Center(
                      child: Text('No contacts found.', style: TextStyle(color: Colors.white)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20.0),
                      itemCount: contacts!.length,
                      itemBuilder: (context, index) {
                        final contact = contacts![index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2B5A),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: const Color(0xFF10B981).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            leading: (contact.photo == null || contact.photo!.isEmpty)
                                ? Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: const Icon(Icons.person, color: Color(0xFF10B981), size: 24),
                                  )
                                : CircleAvatar(backgroundImage: MemoryImage(contact.photo!), radius: 25),
                            title: Text(
                              contact.displayName,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: contact.phones.isNotEmpty
                                ? Text(contact.phones.first.number, style: TextStyle(color: Colors.grey[400], fontSize: 14))
                                : const Text('No phone number', style: TextStyle(color: Colors.grey)),
                            trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF6366F1), size: 18),
                            onTap: () async {
                              final phoneNumberRaw = contact.phones.isNotEmpty ? contact.phones.first.number : null;
                              if (phoneNumberRaw == null) {
                                _showSnackBar('No phone number found for this contact.');
                                return;
                              }
                              String phoneNumber = phoneNumberRaw.replaceAll(RegExp(r'\s+'), '');
                              if (phoneNumber.startsWith('+91')) {
                                phoneNumber = phoneNumber.substring(3);
                              } else if (phoneNumber.startsWith('91')) {
                                phoneNumber = phoneNumber.substring(2);
                              }
                              final checkUrl = Uri.parse('$CHECK_ACCOUNT_URL?phoneNumber=$phoneNumber');
                              final checkResponse = await http.get(checkUrl);
                              if (checkResponse.statusCode == 200) {
                                final checkData = json.decode(checkResponse.body);
                                if (checkData['hasAccount'] == true) {
                                  _showPaymentDialog(contact, phoneNumber);
                                } else {
                                  _showErrorCard('No UPI account found for this contact.');
                                }
                              } else if (checkResponse.statusCode == 404) {
                                _showErrorCard('This user does not have the Voice UPI App.');
                              } else {
                                _showErrorCard('Error checking account.');
                              }
                            },
                          ),
                        );
                      },
                    ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2A2B5A),
      ),
    );
  }

  void _showErrorCard(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2B5A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 30),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 16),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentDialog(Contact contact, String phoneNumber) {
    final amountController = TextEditingController();
    final remarkController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2B5A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  (contact.photo == null || contact.photo!.isEmpty)
                      ? Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.person, color: Color(0xFF10B981), size: 20),
                        )
                      : CircleAvatar(backgroundImage: MemoryImage(contact.photo!), radius: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(contact.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(phoneNumber, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildInputField(
                controller: amountController,
                label: 'Amount',
                hint: 'Enter amount to send',
                keyboardType: TextInputType.number,
                prefixText: '₹ ',
              ),
              const SizedBox(height: 15),
              _buildInputField(
                controller: remarkController,
                label: 'Remark (Optional)',
                hint: 'Add a note for this payment',
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text.trim());
                    if (amount == null || amount <= 0) {
                      _showSnackBar('Enter a valid amount.');
                      return;
                    }
                    final prefs = await SharedPreferences.getInstance();
                    final senderPhone = prefs.getString('signedUpPhoneNumber') ?? '';
                    final sendUrl = Uri.parse(SEND_MONEY_PHONE_URL);
                    final sendResponse = await http.post(
                      sendUrl,
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'senderPhone': senderPhone,
                        'receiverPhone': phoneNumber,
                        'amount': amount,
                        'remark': remarkController.text.trim(),
                      }),
                    );
                    Navigator.pop(context);
                    if (sendResponse.statusCode == 200) {
                      _showPaymentSuccessDialog(contact, amountController.text);
                    } else {
                      final sendData = json.decode(sendResponse.body);
                      _showSnackBar(sendData['error'] ?? 'Payment failed.');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Send Money', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPaymentSuccessDialog(Contact contact, String amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2B5A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 60),
              const SizedBox(height: 20),
              const Text('Payment Successful!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('₹$amount sent to ${contact.displayName}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required TextInputType keyboardType,
    Widget? suffixIcon,
    String? prefixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixText: prefixText,
            prefixStyle: const TextStyle(color: Colors.white),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFF2A2B5A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
