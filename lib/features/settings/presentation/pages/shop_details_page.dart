import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';

class ShopDetailsPage extends StatefulWidget {
  const ShopDetailsPage({super.key});

  @override
  State<ShopDetailsPage> createState() => _ShopDetailsPageState();
}

class _ShopDetailsPageState extends State<ShopDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController(text: 'SON COLLECTION');
  final _tradingNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _stateCityController = TextEditingController();
  final _tinController = TextEditingController();
  final _vrnController = TextEditingController();

  String _shopType = 'All';
  String _shopCategory = 'Default';
  String _currency = 'TZS – Tanzanian Shilling';

  final List<String> _shopTypes = [
    'All',
    'Product & Services',
    'Manufacturing',
    'Microfinance',
    'Online Shop',
  ];

  final List<String> _currencies = [
    'TZS – Tanzanian Shilling',
    'USD – US Dollar',
    'KES – Kenyan Shilling',
    'UGX – Ugandan Shilling',
    'ZAR – South African Rand',
    'GBP – British Pound Sterling',
    'EUR – Euro',
    'CAD – Canadian Dollar',
    'AUD – Australian Dollar',
    'INR – Indian Rupee',
    'CNY – Chinese Yuan Renminbi',
    'JPY – Japanese Yen',
    'CHF – Swiss Franc',
    'NGN – Nigerian Naira',
    'ETB – Ethiopian Birr',
    'RWF – Rwandan Franc',
    'BWP – Botswana Pula',
  ];

  @override
  void dispose() {
    _shopNameController.dispose();
    _tradingNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _stateCityController.dispose();
    _tinController.dispose();
    _vrnController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      final details = {
        'shopName': _shopNameController.text.trim(),
        'tradingName': _tradingNameController.text.trim(),
        'shopType': _shopType,
        'shopCategory': _shopCategory,
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'stateCity': _stateCityController.text.trim(),
        'currency': _currency,
        'tin': _tinController.text.trim(),
        'vrn': _vrnController.text.trim(),
      };
      debugPrint('Shop details saved: $details');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shop details saved successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/shop-settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 1.5),
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            ),
            child: IconButton(
              onPressed: () => context.go('/shop-settings'),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
        ),
        leadingWidth: 56,
        title: Text(
          'Shop Details',
          style: AppTypography.h6.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Shop Name'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _shopNameController,
                hintText: 'Shop name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter shop name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Trading Name'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _tradingNameController,
                hintText: 'Trading name',
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Shop Type'),
              const SizedBox(height: 8),
              _buildDropdown<String>(
                value: _shopType,
                items: _shopTypes,
                onChanged: (value) => setState(() => _shopType = value!),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Shop Category'),
              const SizedBox(height: 8),
              _buildDropdown<String>(
                value: _shopCategory,
                items: ['Default', 'Fashion', 'Electronics', 'Food', 'Health'],
                onChanged: (value) => setState(() => _shopCategory = value!),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Business Email'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _emailController,
                hintText: 'Business email address',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Phone Number'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _phoneController,
                hintText: 'Phone number',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Address'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _addressController,
                hintText: 'Shop address',
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('State/City'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _stateCityController,
                hintText: 'State or city',
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Shop Currency'),
              const SizedBox(height: 8),
              _buildDropdown<String>(
                value: _currency,
                items: _currencies,
                onChanged: (value) => setState(() => _currency = value!),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Taxpayer Number (TIN)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _tinController,
                hintText: 'TIN number',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('VRN Number'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _vrnController,
                hintText: 'VRN number',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              _buildActionButtons(),
              SizedBox(height: 24 + bottomPadding),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.bodyMedium.copyWith(
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
      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
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
          borderSide: const BorderSide(color: AppColors.primary),
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
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: AppConstants.buttonHeight,
            child: OutlinedButton(
              onPressed: () => context.go('/shop-settings'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.textHint),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                ),
              ),
              child: Text(
                'Cancel',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: AppConstants.buttonHeight,
            child: ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                ),
                elevation: 0,
              ),
              child: Text(
                'Save Changes',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
