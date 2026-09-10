import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dukaapp/shared/cards/app_card.dart';
import 'package:dukaapp/shared/textfields/app_text_field.dart';
import 'package:dukaapp/shared/buttons/primary_button.dart';

class ResetPasswordCard extends StatelessWidget {
  final TextEditingController identifierController;
  final bool isLoading;
  final VoidCallback onSendCode;

  const ResetPasswordCard({
    super.key,
    required this.identifierController,
    this.isLoading = false,
    required this.onSendCode,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderRadius: 24,
      padding: EdgeInsets.symmetric(
        horizontal: 24.w,
        vertical: 28.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: 'User ID, Phone, or Email',
            hintText: 'Enter user ID, phone, or email',
            controller: identifierController,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.person_outline,
          ),
          SizedBox(height: 24.h),
          PrimaryButton(
            text: 'Reset',
            isLoading: isLoading,
            onPressed: onSendCode,
          ),
        ],
      ),
    );
  }
}
