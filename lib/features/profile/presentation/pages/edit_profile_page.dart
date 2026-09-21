import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/core/services/biometric_service.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController       = TextEditingController();
  final _regionController         = TextEditingController();
  final _emailController          = TextEditingController();
  final _phoneController          = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController    = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword     = true;
  bool _isLoading = true;
  bool _isSaving  = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadProfile();
      final avail = await BiometricService.isAvailable();
      final enabled = await BiometricService.isEnabled();
      if (mounted) setState(() { _biometricAvailable = avail; _biometricEnabled = enabled; });
    });
  }

  Future<void> _loadProfile() async {
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getSessionUser();
      final raw = res.data;
      Map<String, dynamic>? user;
      if (raw is Map<String, dynamic>) {
        user = raw['data'] is Map ? raw['data'] as Map<String, dynamic> : raw;
      } else if (raw is List && raw.isNotEmpty) {
        user = raw.first as Map<String, dynamic>;
      }
      if (!mounted) return;
      if (user != null) {
        _usernameController.text = user['username']?.toString() ?? '';
        _emailController.text    = user['email']?.toString()    ?? '';
        _phoneController.text    = user['phone']?.toString()    ?? '';
        _regionController.text   = user['region']?.toString()   ?? '';
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final newPass    = _newPasswordController.text;
    final currPass   = _currentPasswordController.text;
    final username   = _usernameController.text.trim();

    if (username.isEmpty) { _snack('Username is required', AppColors.warning); return; }
    if (newPass.isNotEmpty && currPass.isEmpty) {
      _snack('Enter current password to change password', AppColors.warning); return;
    }

    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiServiceProvider);
      final body = <String, dynamic>{
        'username': username,
        'email':    _emailController.text.trim(),
        'phone':    _phoneController.text.trim(),
        'region':   _regionController.text.trim(),
      };
      if (newPass.isNotEmpty) {
        body['current_password'] = currPass;
        body['new_password']     = newPass;
      }
      final res = await api.postSettingsProfileUpdate(body);
      if (!mounted) return;
      final status = res['status']?.toString() ?? '';
      if (status == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
        context.pop();
      } else {
        _snack(res['message']?.toString() ?? 'Update failed', AppColors.danger);
      }
    } catch (e) {
      if (mounted) _snack('Error: $e', AppColors.danger);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String msg, Color c) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: c, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM))));

  @override
  void dispose() {
    _usernameController.dispose();
    _regionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(context),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: Column(children: [
              Expanded(child: SingleChildScrollView(
                padding: EdgeInsets.only(left: AppConstants.paddingLG, right: AppConstants.paddingLG, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _sectionCard('Account Information', [
                    _fieldRow('Full Name / Username', _usernameController, 'Enter username', TextInputType.text),
                    _fieldRow('Email', _emailController, 'Enter email', TextInputType.emailAddress),
                    _fieldRow('Phone', _phoneController, 'Enter phone number', TextInputType.phone),
                    _fieldRow('Region', _regionController, 'Enter region', TextInputType.text),
                  ]),
                  const SizedBox(height: 16),
                  _sectionCard('Change Password', [
                    _passwordRow('Current Password', _currentPasswordController, _obscureCurrentPassword,
                      () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword)),
                    _passwordRow('New Password', _newPasswordController, _obscureNewPassword,
                      () => setState(() => _obscureNewPassword = !_obscureNewPassword)),
                  ]),
                  const SizedBox(height: 16),
                  _sectionCard('Security', [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(children: [
                        Icon(Icons.fingerprint_rounded, size: 24,
                            color: _biometricAvailable ? AppColors.primary : AppColors.textHint),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Biometric Login', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            _biometricAvailable
                                ? 'Ingia kwa kidole au uso wako'
                                : 'Simu hii haina biometrics zilizosanidiwa',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ])),
                        Switch(
                          value: _biometricEnabled,
                          activeColor: AppColors.primary,
                          onChanged: _biometricAvailable
                              ? (v) async {
                                  if (v) {
                                    final ok = await BiometricService.authenticate();
                                    if (!ok) return;
                                  }
                                  await BiometricService.setEnabled(v);
                                  if (mounted) setState(() => _biometricEnabled = v);
                                }
                              : null,
                        ),
                      ]),
                    ),
                  ]),
                ]),
              )),
              _buildBottomBar(),
            ]),
          ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.card, elevation: 0,
      leading: Padding(padding: const EdgeInsets.all(8.0), child: Container(
        decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
        child: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20)),
      )),
      leadingWidth: 56,
      title: Text('Edit Profile', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      centerTitle: true,
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.divider)),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
        const Divider(height: 1, color: AppColors.divider),
        ...children,
      ]),
    );
  }

  Widget _fieldRow(String label, TextEditingController ctrl, String hint, TextInputType type) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(controller: ctrl, keyboardType: type, style: AppTypography.bodyMedium,
        decoration: InputDecoration(hintText: hint, hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
          filled: true, fillColor: AppColors.background, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.5)))),
    ]));
  }

  Widget _passwordRow(String label, TextEditingController ctrl, bool obscure, VoidCallback toggle) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(controller: ctrl, obscureText: obscure, style: AppTypography.bodyMedium,
        decoration: InputDecoration(hintText: '••••••••', hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
          filled: true, fillColor: AppColors.background, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          suffixIcon: IconButton(onPressed: toggle, icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppColors.textHint, size: 20)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.5)))),
    ]));
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(left: AppConstants.paddingLG, right: AppConstants.paddingLG, top: 12, bottom: MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.divider))),
      child: SizedBox(width: double.infinity, height: AppConstants.buttonHeight, child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveProfile,
        icon: _isSaving
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.check_rounded, size: 18, color: AppColors.textWhite),
        label: Text('Save Profile', style: AppTypography.buttonLarge.copyWith(color: AppColors.textWhite)),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD))),
      )),
    );
  }
}
