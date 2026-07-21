import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> labels;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index == currentStep;
        final isCompleted = index < currentStep;

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isCompleted
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                  Container(
                    width: 28.h,
                    height: 28.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted || isActive
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                    child: Center(
                      child: isCompleted
                          ? Icon(Icons.check, size: 14.h, color: Colors.white)
                          : Text(
                              '${index + 1}',
                              style: AppTypography.labelSmall.copyWith(
                                color: isActive
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontSize: 11.sp,
                              ),
                            ),
                    ),
                  ),
                  if (index < totalSteps - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isCompleted
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                labels[index],
                style: AppTypography.caption.copyWith(
                  color: isActive
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 10.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }),
    );
  }
}
