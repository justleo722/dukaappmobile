import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/app/typography.dart';

class UploadCard extends StatefulWidget {
  final String? fileName;
  final VoidCallback? onBrowse;

  const UploadCard({super.key, this.fileName, this.onBrowse});

  @override
  State<UploadCard> createState() => _UploadCardState();
}

class _UploadCardState extends State<UploadCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.shortAnimation,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = widget.fileName != null && widget.fileName!.isNotEmpty;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onBrowse?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
            border: Border.all(
              color: hasFile ? AppColors.success : AppColors.primary,
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: hasFile ? _buildFileSelected() : _buildPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.table_chart_rounded,
            size: 36,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Choose Excel file to upload',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Accepted formats: .xlsx, .csv',
          style: AppTypography.caption,
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: widget.onBrowse,
          icon: const Icon(Icons.folder_open_rounded, size: 18),
          label: Text(
            'Browse File',
            style: AppTypography.buttonMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildFileSelected() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.success.withAlpha(15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            size: 36,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          widget.fileName!,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'File selected',
          style: AppTypography.caption.copyWith(color: AppColors.success),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: widget.onBrowse,
          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
          label: Text(
            'Change File',
            style: AppTypography.buttonMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ),
      ],
    );
  }
}
