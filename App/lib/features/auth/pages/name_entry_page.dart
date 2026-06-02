import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/motion.dart';
import '../providers/auth_providers.dart';

class NameEntryPage extends ConsumerStatefulWidget {
  final String phoneNumber;
  const NameEntryPage({super.key, required this.phoneNumber});

  @override
  ConsumerState<NameEntryPage> createState() => _NameEntryPageState();
}

class _NameEntryPageState extends ConsumerState<NameEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await ref.read(authRepositoryProvider).signUp(
            phoneNumber: widget.phoneNumber,
            upiName: _nameController.text,
          );
      await ref.read(sessionStoreProvider).saveSession(
            phoneNumber: widget.phoneNumber,
            userName: profile.userName,
            upiId: profile.upiId,
          );
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pushReplacementNamed(context, '/biometric');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Entrance(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBackButton(),
                const SizedBox(height: 28),

                Text(
                  'one last step',
                  style: AppTypography.eyebrow(color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  'What should\nwe call you?',
                  style: AppTypography.heading(
                    size: 38,
                    weight: FontWeight.w800,
                  ).copyWith(height: 1.05),
                ),
                const SizedBox(height: 14),
                Text(
                  'Your name appears on your UPI handle and receipts.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 36),

                _buildNameInput(),

                AnimatedSize(
                  duration: AppMotion.medium,
                  curve: AppMotion.out,
                  alignment: Alignment.topCenter,
                  child: _error == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Entrance(child: _buildErrorChip(_error!)),
                        ),
                ),

                const SizedBox(height: 24),
                _buildPerk(),

                const SizedBox(height: 36),
                AppButton(
                  label: 'Create account',
                  icon: Icons.arrow_forward_rounded,
                  loading: _isLoading,
                  onPressed: _isLoading ? null : _createAccount,
                ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Pressable(
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
        child: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.ink,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildNameInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderStrong, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: TextFormField(
        controller: _nameController,
        focusNode: _nameFocusNode,
        keyboardType: TextInputType.name,
        textCapitalization: TextCapitalization.words,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        decoration: const InputDecoration(
          hintText: 'Your full name',
          hintStyle: TextStyle(
            color: AppColors.textMuted,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 20),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your name';
          }
          if (value.length < 2) {
            return 'Name must be at least 2 characters';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPerk() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 18, 14),
      decoration: BoxDecoration(
        color: AppColors.popSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.pop.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.pop,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: AppColors.ink,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'welcome bonus',
                  style: AppTypography.eyebrow(
                    color: AppColors.ink,
                    size: 10,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '₹5,000 ready to spend',
                  style: AppTypography.heading(size: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorChip(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.coral.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.coral, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.coral,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
