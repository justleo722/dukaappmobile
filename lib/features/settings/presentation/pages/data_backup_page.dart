import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';

class DataBackupPage extends ConsumerStatefulWidget {
  const DataBackupPage({super.key});

  @override
  ConsumerState<DataBackupPage> createState() => _DataBackupPageState();
}

class _DataBackupPageState extends ConsumerState<DataBackupPage> {
  final _emailController = TextEditingController();
  String _backupInterval = 'Manual Only';
  bool _isCreating = false;
  String? _lastDownloadUrl;
  String? _lastBackupAt;

  static const List<String> _intervals = ['Manual Only', '28th of Every Month'];

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _createBackup() async {
    setState(() { _isCreating = true; _lastDownloadUrl = null; });
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.postSettingsBackupCreate({
        'backup_email': _emailController.text.trim(),
        'backup_interval': _backupInterval,
      });
      if (!mounted) return;
      final status = res['status']?.toString() ?? '';
      if (status == 'success') {
        _lastDownloadUrl = res['download_url']?.toString();
        _lastBackupAt    = res['backup_at']?.toString() ?? res['created_at']?.toString();
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_lastDownloadUrl != null ? 'Backup ready — tap Download' : 'Backup created successfully'),
          backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message']?.toString() ?? 'Backup failed'),
          backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.card, elevation: 0,
        leading: Padding(padding: const EdgeInsets.all(8.0), child: Container(
          decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
          child: IconButton(onPressed: () => context.go('/shop-settings'),
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20)),
        )),
        leadingWidth: 56,
        title: Text('Data Backup', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.divider)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomPadding),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withValues(alpha: 0.15))),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text('Backup exports all your shop data as an Excel file. Database restore is not available.', style: AppTypography.bodySmall.copyWith(color: AppColors.primary))),
            ]),
          ),
          const SizedBox(height: 24),

          // Email field
          Text('Email (optional)', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: AppTypography.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Send backup to email',
              hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM), borderSide: BorderSide(color: AppColors.textHint.withValues(alpha: 0.3))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM), borderSide: BorderSide(color: AppColors.textHint.withValues(alpha: 0.3))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM), borderSide: const BorderSide(color: AppColors.primary)),
            ),
          ),
          const SizedBox(height: 20),

          // Interval dropdown
          Text('Backup Interval', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppConstants.radiusSM), border: Border.all(color: AppColors.textHint.withValues(alpha: 0.3))),
            child: DropdownButton<String>(
              value: _backupInterval, isExpanded: true, underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint),
              items: _intervals.map((v) => DropdownMenuItem(value: v, child: Text(v, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)))).toList(),
              onChanged: (v) { if (v != null) setState(() => _backupInterval = v); },
            ),
          ),
          const SizedBox(height: 32),

          // Create backup button
          SizedBox(width: double.infinity, height: AppConstants.buttonHeight, child: ElevatedButton.icon(
            onPressed: _isCreating ? null : _createBackup,
            icon: _isCreating
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.backup_rounded, size: 18, color: Colors.white),
            label: Text(_isCreating ? 'Creating Backup…' : 'Create Backup Now',
              style: AppTypography.buttonLarge.copyWith(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD))),
          )),

          // Download link after backup
          if (_lastDownloadUrl != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.success.withValues(alpha: 0.2))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Text('Backup ready!', style: AppTypography.bodyMedium.copyWith(color: AppColors.success, fontWeight: FontWeight.w600)),
                ]),
                if (_lastBackupAt != null) ...[
                  const SizedBox(height: 4),
                  Text('Created: $_lastBackupAt', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
                const SizedBox(height: 10),
                SelectableText(_lastDownloadUrl!, style: AppTypography.bodySmall.copyWith(color: AppColors.primary, decoration: TextDecoration.underline)),
                const SizedBox(height: 6),
                Text('Copy the link above and open it in your browser to download.', style: AppTypography.caption.copyWith(color: AppColors.textHint)),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}
