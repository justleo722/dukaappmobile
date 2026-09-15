import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/staff/data/models/staff_models.dart';
import 'package:dukaapp/features/staff/presentation/providers/staff_provider.dart';

class StaffManagementPage extends ConsumerStatefulWidget {
  const StaffManagementPage({super.key});

  @override
  ConsumerState<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends ConsumerState<StaffManagementPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Attendant> _attendants = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTeam());
  }

  Future<void> _loadTeam() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(staffRepositoryProvider);
      final list = await repo.fetchTeam();
      if (!mounted) return;
      setState(() {
        _attendants = list;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Attendant> get _filteredAttendants {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return _attendants;
    return _attendants.where((a) => a.name.toLowerCase().contains(query) || a.phone.contains(query)).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(Attendant attendant) async {
    final result = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Attendant', style: AppTypography.h6.copyWith(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete "${attendant.name}"?',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete', style: AppTypography.bodyMedium.copyWith(color: AppColors.danger, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (result == true && mounted) {
      try {
        final repo = ref.read(staffRepositoryProvider);
        // Soft-delete only — backend marks record_status = 'deleted', never hard DELETE
        await repo.deleteAttendant({'role_id': attendant.roleId.toString()});
        if (!mounted) return;
        await _loadTeam();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${attendant.name} deleted'), backgroundColor: AppColors.danger),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendants = _filteredAttendants;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(context),
      body: Column(children: [
        _buildSearchField(),
        const SizedBox(height: 12),
        _buildAddButton(context),
        const SizedBox(height: 12),
        Expanded(child: attendants.isEmpty ? _buildEmptyState() : _buildAttendantList(attendants)),
      ]),
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
      title: Text('Attendants & Staff Management', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      centerTitle: true,
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.divider)),
    );
  }

  Widget _buildSearchField() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG, vertical: 10), child: TextField(
      controller: _searchController, onChanged: (_) => setState(() {}), style: AppTypography.bodyMedium,
      decoration: InputDecoration(hintText: 'Search attendant by name or phone…', hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
        suffixIcon: _searchController.text.isNotEmpty ? IconButton(onPressed: () { _searchController.clear(); setState(() {}); }, icon: const Icon(Icons.close_rounded, color: AppColors.textHint, size: 18)) : null,
        filled: true, fillColor: AppColors.card, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.5)),
      ),
    ));
  }

  Widget _buildAddButton(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG), child: SizedBox(
      width: double.infinity, height: AppConstants.buttonHeight,
      child: ElevatedButton.icon(
        onPressed: () => context.push('/staff/add'),
        icon: const Icon(Icons.add_rounded, size: 20, color: AppColors.textWhite),
        label: Text('Add New Attendant', style: AppTypography.buttonLarge.copyWith(color: AppColors.textWhite)),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD))),
      ),
    ));
  }

  Widget _buildAttendantList(List<Attendant> attendants) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
      itemCount: attendants.length,
      itemBuilder: (ctx, i) => _buildAttendantCard(attendants[i]),
    );
  }

  Widget _buildAttendantCard(Attendant attendant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFFCE8F3), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.person_rounded, color: Color(0xFFEC4899), size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(attendant.name, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('ID: ${attendant.userId ?? attendant.roleId?.toString() ?? '-'}  •  ${attendant.isManager ? 'Manager' : 'Attendant'}', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11)),
          ])),
          Switch(
            value: attendant.isActive,
            onChanged: (v) async {
              try {
                final repo = ref.read(staffRepositoryProvider);
                await repo.updateStatus({'role_id': attendant.roleId.toString(), 'status': v == true ? 'active' : 'inactive'});
                if (mounted) await _loadTeam();
              } catch (_) {}
            },
            activeThumbColor: AppColors.primary,
          ),
        ]),
        const Divider(height: 20),
        Row(children: [
          Icon(Icons.phone_rounded, size: 14, color: AppColors.textHint), const SizedBox(width: 6),
          Flexible(child: Text(attendant.phone, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 6, children: [
          _actionChip(Icons.edit_rounded, 'Edit', AppColors.primary, () => context.push('/staff/edit', extra: {
            'name': attendant.name,
            'phone': attendant.phone,
            'role': attendant.staffRole,
            'shops': attendant.shopId != null ? [attendant.shopId!] : <String>[],
            'roleId': attendant.roleId?.toString(),
            'isManager': attendant.isManager,
          })),
          _actionChip(Icons.security_rounded, 'Permissions', const Color(0xFF8B5CF6),
              () => context.push('/staff/permissions', extra: {'roleId': attendant.roleId?.toString()})),
          _actionChip(Icons.delete_rounded, 'Delete', AppColors.danger, () => _confirmDelete(attendant)),
        ]),
      ]),
    );
  }

  Widget _actionChip(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color), const SizedBox(width: 4),
        Text(label, style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w600, fontSize: 11)),
      ]),
    ));
  }

  Widget _buildEmptyState() {
    return Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingXXL, vertical: 60), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 100, height: 100, decoration: BoxDecoration(color: const Color(0xFFFCE8F3), shape: BoxShape.circle),
        child: Icon(Icons.people_rounded, size: 48, color: const Color(0xFFEC4899).withValues(alpha: 0.4))),
      const SizedBox(height: 20),
      Text('No Attendants Found', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text('Tap "Add New Attendant" to get started.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
    ])));
  }
}
