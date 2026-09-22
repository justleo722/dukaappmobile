import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';

class OnlineShopAddCategoryPage extends ConsumerStatefulWidget {
  const OnlineShopAddCategoryPage({
    super.key,
    this.existingCategory,
  });

  final Map<String, dynamic>? existingCategory;

  @override
  ConsumerState<OnlineShopAddCategoryPage> createState() =>
      _OnlineShopAddCategoryPageState();
}

class _OnlineShopAddCategoryPageState extends ConsumerState<OnlineShopAddCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _status = 'Active';
  File? _iconFile;
  Map<String, dynamic>? _existingCategory;
  bool get _isEditing => _existingCategory != null;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _applyCategoryData(widget.existingCategory);
  }

  @override
  void didUpdateWidget(covariant OnlineShopAddCategoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.existingCategory != null &&
        oldWidget.existingCategory != widget.existingCategory) {
      _applyCategoryData(widget.existingCategory);
    }
  }

  void _applyCategoryData(Map<String, dynamic>? extra) {
    if (extra == null) return;

    _existingCategory = extra;
    _nameController.text = extra['name']?.toString() ?? '';
    _descriptionController.text = extra['description']?.toString() ?? '';
    _status = extra['status']?.toString() ?? 'Active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _iconFile = File(picked.path);
      });
    }
  }

  void _resetIcon() {
    setState(() {
      _iconFile = null;
    });
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiServiceProvider);
      final body = <String, dynamic>{
        'category': _nameController.text.trim(),
        'status': _status.toLowerCase(),
      };
      if (_isEditing) {
        body['category_id'] = (_existingCategory!['category_id'] ?? _existingCategory!['id'] ?? '').toString();
      }
      final result = await api.postOnlineshopCategorySave(body);
      if (!mounted) return;
      final status = result['status']?.toString() ?? '';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(status == 'success'
            ? (_isEditing ? 'Category updated' : 'Category created')
            : (result['message']?.toString() ?? 'Failed to save')),
        backgroundColor: status == 'success' ? AppColors.success : AppColors.danger,
      ));
      if (status == 'success') context.go('/online-shop/categories');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => context.go('/online-shop/categories'),
        ),
        title: Text(
          _isEditing ? 'Edit Category' : 'Add Category',
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
              _buildSectionTitle('Category Name'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nameController,
                hintText: 'Category name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter category name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Icon'),
              const SizedBox(height: 8),
              _buildIconPicker(),
              const SizedBox(height: 20),
              _buildSectionTitle('Description'),
              const SizedBox(height: 8),
              _buildTextArea(
                controller: _descriptionController,
                hintText: 'Short description...',
                maxLines: 4,
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
                        onPressed: () => context.go('/online-shop/categories'),
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
                        onPressed: _isSaving ? null : _saveCategory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(
                          _isEditing ? 'Update Category' : 'Save Category',
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

  Widget _buildIconPicker() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
        border: Border.all(color: AppColors.textHint.withValues(alpha: 0.3)),
      ),
      child: _iconFile != null
          ? Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                  child: Image.file(
                    _iconFile!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Icon uploaded',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'PNG file selected',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _resetIcon,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            )
          : GestureDetector(
              onTap: _pickIcon,
              child: Column(
                children: [
                  Icon(
                    Icons.folder_open_rounded,
                    size: 48,
                    color: AppColors.textHint.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to upload PNG icon',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
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

  Widget _buildTextArea({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 3,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
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
