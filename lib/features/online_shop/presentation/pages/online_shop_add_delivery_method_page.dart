import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/constants.dart';

class OnlineShopAddDeliveryMethodPage extends StatefulWidget {
  const OnlineShopAddDeliveryMethodPage({
    super.key,
    this.existingMethod,
  });

  final Map<String, dynamic>? existingMethod;

  @override
  State<OnlineShopAddDeliveryMethodPage> createState() =>
      _OnlineShopAddDeliveryMethodPageState();
}

class _OnlineShopAddDeliveryMethodPageState
    extends State<OnlineShopAddDeliveryMethodPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _feeController = TextEditingController();
  final _deliveryTimeController = TextEditingController();
  final _minOrderController = TextEditingController();

  String _status = 'Active';
  Map<String, dynamic>? _existingMethod;
  bool get _isEditing => _existingMethod != null;

  @override
  void initState() {
    super.initState();
    _applyMethodData(widget.existingMethod);
  }

  @override
  void didUpdateWidget(covariant OnlineShopAddDeliveryMethodPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.existingMethod != null &&
        oldWidget.existingMethod != widget.existingMethod) {
      _applyMethodData(widget.existingMethod);
    }
  }

  void _applyMethodData(Map<String, dynamic>? extra) {
    if (extra == null) return;

    _existingMethod = extra;
    _nameController.text = extra['name']?.toString() ?? '';
    _feeController.text = _extractNumericValue(extra['fee']?.toString() ?? '0');
    _deliveryTimeController.text =
        extra['estimatedDelivery']?.toString() ?? '';
    _minOrderController.text =
        _extractNumericValue(extra['minimumOrder']?.toString() ?? '0');
    _status = extra['status']?.toString() ?? 'Active';
  }

  String _extractNumericValue(String value) {
    return value.replaceAll(RegExp(r'[^0-9.]'), '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _feeController.dispose();
    _deliveryTimeController.dispose();
    _minOrderController.dispose();
    super.dispose();
  }

  void _saveMethod() {
    if (_formKey.currentState!.validate()) {
      final methodData = {
        'name': _nameController.text.trim(),
        'fee': int.tryParse(_feeController.text.trim()) ?? 0,
        'estimatedDelivery': _deliveryTimeController.text.trim(),
        'minimumOrder': int.tryParse(_minOrderController.text.trim()) ?? 0,
        'status': _status,
      };

      debugPrint('Delivery method saved: $methodData');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Delivery method updated' : 'Delivery method created',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/online-shop/delivery');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => context.go('/online-shop/delivery'),
        ),
        title: Text(
          _isEditing ? 'Edit Delivery Method' : 'Add Delivery Method',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Method Name'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nameController,
                hintText: 'Delivery method name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter delivery method name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Delivery Fee'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _feeController,
                hintText: '0',
                keyboardType: TextInputType.number,
                prefixLabel: 'TZS',
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Est. Delivery Time'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _deliveryTimeController,
                hintText: 'Estimated delivery time',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter estimated delivery time';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Min Order Amount'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _minOrderController,
                hintText: '0',
                keyboardType: TextInputType.number,
                suffixNote: '0 = No minimum',
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Status'),
              const SizedBox(height: 8),
              _buildDropdown<String>(
                value: _status,
                items: ['Active', 'Inactive'],
                onChanged: (value) {
                  setState(() {
                    _status = value!;
                  });
                },
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => context.go('/online-shop/delivery'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.textHint),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusSM),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saveMethod,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusSM),
                          ),
                        ),
                        child: Text(
                          _isEditing ? 'Update Method' : 'Save Method',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? prefixLabel,
    String? suffixNote,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle:
                GoogleFonts.poppins(fontSize: 14, color: AppColors.textHint),
            filled: true,
            fillColor: Colors.white,
            prefixText: prefixLabel != null ? '$prefixLabel ' : null,
            prefixStyle: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              borderSide: BorderSide(
                  color: AppColors.textHint.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              borderSide: BorderSide(
                  color: AppColors.textHint.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              borderSide: const BorderSide(color: AppColors.danger),
            ),
          ),
        ),
        if (suffixNote != null) ...[
          const SizedBox(height: 4),
          Text(
            suffixNote,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textHint,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
        border: Border.all(color: AppColors.textHint.withValues(alpha: 0.3)),
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: AppColors.textHint),
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              item.toString(),
              style:
                  GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
