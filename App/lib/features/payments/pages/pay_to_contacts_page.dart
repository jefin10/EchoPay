import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/payment_providers.dart';

class PayToContactsPage extends ConsumerStatefulWidget {
  const PayToContactsPage({super.key});

  @override
  ConsumerState<PayToContactsPage> createState() => _PayToContactsPageState();
}

class _PayToContactsPageState extends ConsumerState<PayToContactsPage> {
  List<Contact>? contacts;
  List<Contact>? filteredContacts;
  bool loading = true;
  bool permissionDenied = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchContacts();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredContacts = contacts;
      } else {
        filteredContacts = contacts?.where((c) {
          return c.displayName.toLowerCase().contains(query) ||
              (c.phones.isNotEmpty && c.phones.first.number.contains(query));
        }).toList();
      }
    });
  }

  Future<void> _fetchContacts() async {
    var status = await Permission.contacts.request();
    if (status.isGranted) {
      final fetched = await FlutterContacts.getContacts(withProperties: true);
      setState(() {
        contacts = fetched;
        filteredContacts = fetched;
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
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            const SizedBox(height: 18),
            _searchBox(),
            const SizedBox(height: 14),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Pressable(
            scale: 0.9,
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
          Text('contacts', style: AppTypography.heading(size: 22)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${filteredContacts?.length ?? 0}',
              style: const TextStyle(
                color: AppColors.pop,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            const Icon(Icons.search_rounded,
                color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search contacts',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              Pressable(
                scale: 0.85,
                onTap: _searchController.clear,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded,
                      color: AppColors.textSecondary, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.ink, strokeWidth: 2.5),
      );
    }
    if (permissionDenied) return _permissionDenied();
    if (filteredContacts == null || filteredContacts!.isEmpty) {
      return _emptyState();
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: filteredContacts!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _contactRow(filteredContacts![i]),
    );
  }

  Widget _permissionDenied() {
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
              child: const Icon(Icons.contacts_outlined,
                  color: AppColors.ink, size: 28),
            ),
            const SizedBox(height: 18),
            Text(
              'Contacts permission needed',
              style: AppTypography.heading(size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Allow access so you can pay people in your address book.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            AppButton(
              label: 'Open settings',
              expand: false,
              onPressed: () => openAppSettings(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
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
              child: const Icon(Icons.person_search_outlined,
                  color: AppColors.ink, size: 28),
            ),
            const SizedBox(height: 18),
            Text(
              _searchController.text.isEmpty
                  ? 'No contacts found'
                  : 'No matching contacts',
              style: AppTypography.heading(size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactRow(Contact contact) {
    final hasPhoto = contact.photo != null && contact.photo!.isNotEmpty;
    final initial = contact.displayName.isNotEmpty
        ? contact.displayName[0].toUpperCase()
        : '?';
    final phone = contact.phones.isNotEmpty
        ? contact.phones.first.number
        : 'No phone number';

    return Pressable(
      scale: 0.98,
      onTap: () => _handleContactTap(contact),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            hasPhoto
                ? CircleAvatar(
                    radius: 22,
                    backgroundImage: MemoryImage(contact.photo!),
                  )
                : Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDim,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.displayName,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    phone,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded,
                color: AppColors.ink, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _handleContactTap(Contact contact) async {
    final raw = contact.phones.isNotEmpty ? contact.phones.first.number : null;
    if (raw == null) {
      _showSnackBar('No phone number found for this contact.');
      return;
    }
    String phoneNumber = raw.replaceAll(RegExp(r'\s+'), '');
    if (phoneNumber.startsWith('+91')) {
      phoneNumber = phoneNumber.substring(3);
    } else if (phoneNumber.startsWith('91')) {
      phoneNumber = phoneNumber.substring(2);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const CircularProgressIndicator(
            color: AppColors.ink,
            strokeWidth: 2.5,
          ),
        ),
      ),
    );

    final hasAccount =
        await ref.read(paymentRepositoryProvider).hasAccount(phoneNumber);
    if (!mounted) return;
    Navigator.pop(context);
    if (hasAccount) {
      _showPaymentSheet(contact, phoneNumber);
    } else {
      _showInfoCard('No UPI account found for this contact.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showInfoCard(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.coral.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.info_outline_rounded,
                    color: AppColors.coral, size: 24),
              ),
              const SizedBox(height: 14),
              Text(
                message,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              AppButton(
                label: 'OK',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentSheet(Contact contact, String phoneNumber) {
    final amountController = TextEditingController();
    final remarkController = TextEditingController();
    final hasPhoto = contact.photo != null && contact.photo!.isNotEmpty;
    final initial = contact.displayName.isNotEmpty
        ? contact.displayName[0].toUpperCase()
        : '?';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Padding(
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
                const SizedBox(height: 22),
                Row(
                  children: [
                    hasPhoto
                        ? CircleAvatar(
                            radius: 26,
                            backgroundImage: MemoryImage(contact.photo!),
                          )
                        : Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceDim,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact.displayName,
                            style: AppTypography.heading(size: 18),
                          ),
                          Text(
                            phoneNumber,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.mint.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded,
                              color: AppColors.mint, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'verified',
                            style: AppTypography.eyebrow(
                              color: AppColors.mint,
                              size: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _label('Amount'),
                const SizedBox(height: 8),
                _input(amountController, '0', TextInputType.number, prefix: '₹ '),
                const SizedBox(height: 16),
                _label('Note (optional)'),
                const SizedBox(height: 8),
                _input(remarkController, 'Add a note', TextInputType.text),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Pay now',
                  onPressed: () async {
                    final amount =
                        double.tryParse(amountController.text.trim());
                    if (amount == null || amount <= 0) {
                      _showSnackBar('Enter a valid amount.');
                      return;
                    }
                    final senderPhone =
                        ref.read(sessionStoreProvider).phoneNumber ?? '';
                    final result =
                        await ref.read(paymentRepositoryProvider).sendByPhone(
                              senderPhone: senderPhone,
                              receiverPhone: phoneNumber,
                              amount: amount,
                              remark: remarkController.text.trim(),
                            );
                    if (!mounted) return;
                    Navigator.pop(context);
                    if (result.success) {
                      _showPaymentSuccess(contact, amountController.text);
                    } else {
                      _showSnackBar(result.message);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPaymentSuccess(Contact contact, String amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.mint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.mint, size: 32),
              ),
              const SizedBox(height: 18),
              Text('Payment sent', style: AppTypography.heading(size: 22)),
              const SizedBox(height: 4),
              Text(
                '₹$amount to ${contact.displayName}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              AppButton(
                label: 'Done',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      );

  Widget _input(
    TextEditingController controller,
    String hint,
    TextInputType keyboardType, {
    String? prefix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDim,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
          prefixText: prefix,
          prefixStyle: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
