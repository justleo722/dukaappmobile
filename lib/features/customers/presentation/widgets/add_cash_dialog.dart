import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/features/customers/data/models/customer_model.dart';

class AddCashDialog extends ConsumerStatefulWidget {
  final Customer customer;
  final VoidCallback? onSuccess;

  const AddCashDialog({super.key, required this.customer, this.onSuccess});

  @override
  ConsumerState<AddCashDialog> createState() => _AddCashDialogState();
}

class _AddCashDialogState extends ConsumerState<AddCashDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _accounts = [];
  String? _selectedAccountId;
  bool _isLoadingAccounts = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAccounts());
  }

  Future<void> _loadAccounts() async {
    if (!mounted) return;
    setState(() => _isLoadingAccounts = true);
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getCashbookAccounts();
      final raw = res.data;
      final list = raw is List
          ? raw
          : (raw is Map ? (raw['data'] ?? raw['result'] ?? raw['items'] ?? []) : []);
      if (!mounted) return;
      setState(() {
        _accounts = (list as List).whereType<Map<String, dynamic>>().toList();
        _isLoadingAccounts = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingAccounts = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
    ));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccountId == null) {
      _snack('Please select an account', AppColors.danger);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiServiceProvider);
      final body = {
        'customer_id': widget.customer.id,
        'amount': _amountController.text.trim(),
        'account_id': _selectedAccountId,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'action': 'add_cash',
      };
      final res = await api.postWalletCustomerCreate(body);
      final ok = res['status']?.toString() == '1' ||
          res['status'] == true ||
          res['status']?.toString() == 'success';
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context);
        _snack('TZS ${_amountController.text} added to ${widget.customer.name}', AppColors.success);
        widget.onSuccess?.call();
      } else {
        _snack(res['message']?.toString() ?? 'Failed to add cash', AppColors.danger);
        setState(() => _isSaving = false);
      }
    } catch (e) {
      if (mounted) {
        _snack('Error: $e', AppColors.danger);
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReadOnlyField('Customer', widget.customer.name, Icons.person_rounded),
                      const SizedBox(height: 16),
                      _buildAmountField(),
                      const SizedBox(height: 16),
                      _buildDateField(),
                      const SizedBox(height: 16),
                      _buildAccountDropdown(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLG),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add_circle_outline_rounded, color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Add Cash', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
              Text('Add cash to customer wallet', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11)),
            ]),
          ),
          IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close_rounded, color: AppColors.textHint, size: 22)),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTypography.label.copyWith(color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(children: [
          Icon(icon, color: AppColors.textHint, size: 20),
          const SizedBox(width: 12),
          Text(value, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ]),
      ),
    ]);
  }

  Widget _buildAmountField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Amount', style: AppTypography.label.copyWith(color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      TextFormField(
        controller: _amountController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Enter amount';
          if ((double.tryParse(v) ?? 0) <= 0) return 'Enter valid amount';
          return null;
        },
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Enter amount',
          hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
          prefixIcon: const Icon(Icons.attach_money_rounded, color: AppColors.textHint, size: 20),
          filled: true, fillColor: AppColors.card,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.textFieldRadius), borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.5)),
        ),
      ),
    ]);
  }

  Widget _buildDateField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Date', style: AppTypography.label.copyWith(color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: () async {
          final d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now());
          if (d != null) setState(() => _selectedDate = d);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Text(DateFormat('dd/MM/yyyy').format(_selectedDate), style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint, size: 20),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildAccountDropdown() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Account', style: AppTypography.label.copyWith(color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      if (_isLoadingAccounts)
        const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
      else
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedAccountId,
              isExpanded: true,
              hint: Row(children: [
                const Icon(Icons.account_balance_rounded, color: AppColors.textHint, size: 20),
                const SizedBox(width: 12),
                Text('Select account', style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint)),
              ]),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint),
              items: _accounts.map((a) {
                final id = (a['account_id'] ?? a['id'] ?? '').toString();
                final name = (a['account_name'] ?? a['name'] ?? 'Account $id').toString();
                return DropdownMenuItem(value: id, child: Text(name, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)));
              }).toList(),
              onChanged: (v) => setState(() => _selectedAccountId = v),
            ),
          ),
        ),
    ]);
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLG),
      child: SizedBox(
        width: double.infinity,
        height: AppConstants.buttonHeight,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textWhite,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
          ),
          child: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Add Cash', style: AppTypography.buttonLarge.copyWith(color: AppColors.textWhite)),
        ),
      ),
    );
  }
}
