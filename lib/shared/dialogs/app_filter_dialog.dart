import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/shared/providers/filter_provider.dart';
import 'package:dukaapp/shared/widgets/filter_option_button.dart';
import 'package:dukaapp/shared/widgets/date_input_field.dart';

/// Global filter dialog.
///
/// On Apply it updates [filterProvider] so every page that
/// `ref.listen(filterProvider, …)` automatically reloads with new dates.
///
/// Call it the same way as before:
/// ```dart
/// AppFilterDialog.show(context);
/// ```
/// No callbacks needed — state flows via [filterProvider].
class AppFilterDialog extends ConsumerStatefulWidget {
  // Legacy optional callbacks kept for backward compatibility
  final String? selectedFilter;
  final ValueChanged<String>? onFilterSelected;
  final VoidCallback? onApply;
  final VoidCallback? onCustomApply;

  const AppFilterDialog({
    super.key,
    this.selectedFilter,
    this.onFilterSelected,
    this.onApply,
    this.onCustomApply,
  });

  static Future<void> show(
    BuildContext context, {
    String? selectedFilter,
    ValueChanged<String>? onFilterSelected,
    VoidCallback? onApply,
    VoidCallback? onCustomApply,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: AppColors.overlay,
      builder: (_) => AppFilterDialog(
        selectedFilter: selectedFilter,
        onFilterSelected: onFilterSelected,
        onApply: onApply,
        onCustomApply: onCustomApply,
      ),
    );
  }

  @override
  ConsumerState<AppFilterDialog> createState() => _AppFilterDialogState();
}

class _AppFilterDialogState extends ConsumerState<AppFilterDialog>
    with SingleTickerProviderStateMixin {
  late String? _selectedFilter;
  bool _isCustomExpanded = false;
  late AnimationController _expandController;
  DateTime? _fromDate;
  DateTime? _toDate;

  final DateFormat _dateFormat = DateFormat('MM/dd/yyyy');

  final List<Map<String, String>> _filterOptions = [
    {'label': 'Today', 'value': 'today'},
    {'label': 'Yesterday', 'value': 'yesterday'},
    {'label': 'This Week', 'value': 'this_week'},
    {'label': 'Last Week', 'value': 'last_week'},
    {'label': 'This Month', 'value': 'this_month'},
    {'label': 'Last Month', 'value': 'last_month'},
    {'label': 'Last 3 Months', 'value': 'last_3_months'},
    {'label': 'This Year', 'value': 'this_year'},
    {'label': 'All Time', 'value': 'all_time'},
  ];

  @override
  void initState() {
    super.initState();
    // Initialise from global state
    final current = ref.read(filterProvider);
    _selectedFilter = widget.selectedFilter ?? current.key;
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    // If global filter is custom, expand the section
    if (current.key == 'custom') {
      _isCustomExpanded = true;
      _expandController.value = 1.0;
      try {
        _fromDate = DateTime.parse(current.from);
        _toDate = DateTime.parse(current.to);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleCustom() {
    setState(() {
      _isCustomExpanded = !_isCustomExpanded;
      if (_isCustomExpanded) {
        _selectedFilter = null; // deselect preset when opening custom
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  void _onFilterTap(String value) {
    setState(() {
      _selectedFilter = value;
      // Collapse custom panel when a preset is selected
      if (_isCustomExpanded) {
        _isCustomExpanded = false;
        _expandController.reverse();
      }
    });
    widget.onFilterSelected?.call(value);
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom
        ? (_fromDate ?? DateTime.now())
        : (_toDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textWhite,
              surface: AppColors.card,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  void _apply() {
    if (_isCustomExpanded) {
      // Custom range
      final from = _fromDate;
      final to = _toDate;
      if (from == null || to == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both From and To dates')),
        );
        return;
      }
      // Update global filter
      ref.read(filterProvider.notifier).applyCustom(from, to);
      widget.onCustomApply?.call();
    } else {
      // Preset
      final key = _selectedFilter ?? 'today';
      ref.read(filterProvider.notifier).applyPreset(key);
      widget.onApply?.call();
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Read current global filter to show active label badge
    final currentFilter = ref.watch(filterProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingXL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(currentFilter),
                  const SizedBox(height: 20),
                  _buildFilterGrid(isSmallScreen),
                  const SizedBox(height: 16),
                  _buildCustomButton(),
                  _buildExpandableSection(),
                  const SizedBox(height: 20),
                  _buildApplyButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(FilterState current) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select filter to proceed',
                style: AppTypography.h5.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              // Show currently active filter
              Text(
                'Active: ${current.label}  (${current.from} → ${current.to})',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.close_rounded,
            color: AppColors.textSecondary,
            size: 24,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildFilterGrid(bool isSmallScreen) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isSmallScreen ? 1 : 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: isSmallScreen ? 3.5 : 2.2,
      ),
      itemCount: _filterOptions.length,
      itemBuilder: (context, index) {
        final option = _filterOptions[index];
        final isSelected = _selectedFilter == option['value'];
        return FilterOptionButton(
          label: option['label']!,
          isSelected: isSelected,
          onTap: () => _onFilterTap(option['value']!),
        );
      },
    );
  }

  Widget _buildCustomButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: _toggleCustom,
        style: OutlinedButton.styleFrom(
          backgroundColor: _isCustomExpanded
              ? AppColors.primary.withAlpha(15)
              : AppColors.card,
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Custom',
              style: AppTypography.buttonMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedRotation(
              turns: _isCustomExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 250),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableSection() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: _isCustomExpanded
          ? Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DateInputField(
                          label: 'From',
                          hintText: 'MM/DD/YYYY',
                          value: _fromDate != null
                              ? _dateFormat.format(_fromDate!)
                              : null,
                          onTap: () => _pickDate(isFrom: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DateInputField(
                          label: 'To',
                          hintText: 'MM/DD/YYYY',
                          value: _toDate != null
                              ? _dateFormat.format(_toDate!)
                              : null,
                          onTap: () => _pickDate(isFrom: false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildApplyButton() {
    return SizedBox(
      width: double.infinity,
      height: AppConstants.buttonHeight,
      child: ElevatedButton(
        onPressed: _apply,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          ),
        ),
        child: Text(
          'Apply Filter',
          style: AppTypography.buttonLarge,
        ),
      ),
    );
  }
}
