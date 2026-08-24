// features/online_shop/presentation/pages/online_shop_add_coupon_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/constants.dart';

class OnlineShopAddCouponPage extends StatefulWidget {
  const OnlineShopAddCouponPage({
    super.key,
    this.existingCoupon,
  });

  final Map<String, dynamic>? existingCoupon;

  @override
  State<OnlineShopAddCouponPage> createState() => _OnlineShopAddCouponPageState();
}

class _OnlineShopAddCouponPageState extends State<OnlineShopAddCouponPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _minOrderController = TextEditingController();
  final _maxUsesController = TextEditingController();

  String _discountType = 'Percentage';
  String _status = 'Active';
  DateTime? _expiryDate;
  Map<String, dynamic>? _existingCoupon;
  bool get _isEditing => _existingCoupon != null;

  @override
  void initState() {
    super.initState();
    _applyCouponData(widget.existingCoupon);
  }

  @override
  void didUpdateWidget(covariant OnlineShopAddCouponPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.existingCoupon != null &&
        oldWidget.existingCoupon != widget.existingCoupon) {
      _applyCouponData(widget.existingCoupon);
    }
  }

  void _applyCouponData(Map<String, dynamic>? extra) {
    if (extra == null) {
      return;
    }

    _existingCoupon = extra;
    _codeController.text = extra['code']?.toString() ?? '';
    _discountType = extra['discountType']?.toString() ?? 'Percentage';
    _discountValueController.text = _extractNumericValue(extra['discountValue']?.toString() ?? '');
    _minOrderController.text = _extractNumericValue(extra['minOrder']?.toString() ?? '');
    _maxUsesController.text = extra['maxUses'] == 'Unlimited' ? '' : (extra['maxUses']?.toString() ?? '');
    _status = extra['status']?.toString() ?? 'Active';

    final expiryDateValue = extra['expiryDate'];
    if (expiryDateValue != null) {
      final parsedDate = DateTime.tryParse(expiryDateValue.toString());
      if (parsedDate != null) {
        _expiryDate = parsedDate;
      }
    }
  }

  String _extractNumericValue(String value) {
    return value.replaceAll(RegExp(r'[^0-9.]'), '');
  }

  @override
  void dispose() {
    _codeController.dispose();
    _discountValueController.dispose();
    _minOrderController.dispose();
    _maxUsesController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  void _saveCoupon() {
    if (_formKey.currentState!.validate()) {
      final couponData = {
        'id': _isEditing ? _existingCoupon!['id'] : 'CPN-${DateTime.now().millisecondsSinceEpoch}',
        'code': _codeController.text.trim().toUpperCase(),
        'discountType': _discountType,
        'discountValue': _discountType == 'Free Shipping'
            ? 'Free'
            : _discountType == 'Percentage'
                ? '${_discountValueController.text}%'
                : 'Tsh ${_discountValueController.text}',
        'minOrder': _minOrderController.text.isEmpty
            ? 'Tsh 0'
            : 'Tsh ${_minOrderController.text}',
        'maxUses': _maxUsesController.text.isEmpty ? 'Unlimited' : _maxUsesController.text,
        'usedCount': _isEditing ? _existingCoupon!['usedCount'] : 0,
        'expiryDate': _expiryDate != null
            ? '${_expiryDate!.year}-${_expiryDate!.month.toString().padLeft(2, '0')}-${_expiryDate!.day.toString().padLeft(2, '0')}'
            : '',
        'status': _status,
      };

      debugPrint('Coupon saved: $couponData');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Coupon updated' : 'Coupon created'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/online-shop/coupons');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => context.go('/online-shop/coupons'),
        ),
        title: Text(
          _isEditing ? 'Edit Coupon' : 'Add Coupon',
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
              _buildSectionTitle('Coupon Code'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _codeController,
                hintText: 'e.g. SAVE20',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter coupon code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Discount Type'),
              const SizedBox(height: 8),
              _buildDropdown<String>(
                value: _discountType,
                items: ['Percentage', 'Fixed', 'Free Shipping'],
                onChanged: (value) {
                  setState(() {
                    _discountType = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              if (_discountType != 'Free Shipping') ...[
                _buildSectionTitle(_discountType == 'Percentage' ? 'Discount Percentage' : 'Discount Amount'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _discountValueController,
                  hintText: _discountType == 'Percentage' ? 'e.g. 20' : 'e.g. 5000',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter discount value';
                    }
                    if (_discountType == 'Percentage') {
                      final num = double.tryParse(value);
                      if (num == null || num <= 0 || num > 100) {
                        return 'Enter a valid percentage (1-100)';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
              ],
              _buildSectionTitle('Minimum Order Amount (Optional)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _minOrderController,
                hintText: 'e.g. 50000',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Max Uses (Optional)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _maxUsesController,
                hintText: 'Leave empty for unlimited',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Expiry Date'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickExpiryDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                    border: Border.all(color: AppColors.textHint.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _expiryDate != null
                            ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                            : 'Select expiry date',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: _expiryDate != null ? AppColors.textPrimary : AppColors.textHint,
                        ),
                      ),
                      const Icon(Icons.calendar_today_rounded, color: AppColors.textHint, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Status'),
              const SizedBox(height: 8),
              _buildDropdown<String>(
                value: _status,
                items: ['Active', 'Inactive', 'Scheduled', 'Expired'],
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
                        onPressed: () => context.go('/online-shop/coupons'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.textHint),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radiusSM),
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
                        onPressed: _saveCoupon,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                          ),
                        ),
                        child: Text(
                          _isEditing ? 'Update Coupon' : 'Save Coupon',
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(fontSize: 14, color: AppColors.textHint),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          borderSide: BorderSide(color: AppColors.textHint.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          borderSide: BorderSide(color: AppColors.textHint.withValues(alpha: 0.3)),
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
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint),
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              item.toString(),
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
