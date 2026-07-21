import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/shared/widgets/auth_logo.dart';
import 'package:dukaapp/shared/buttons/primary_button.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  final VoidCallback? onAccept;

  const TermsAndConditionsScreen({super.key, this.onAccept});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                ),
                child: Column(
                  children: [
                    _buildLogoSection(),
                    SizedBox(height: 24.h),
                    _buildContent(),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
            _buildAcceptButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 20.w,
        vertical: 12.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Terms & Conditions',
            style: AppTypography.h6,
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: EdgeInsets.all(4.h),
              decoration: BoxDecoration(
                color: AppColors.border.withAlpha(80),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 20.h,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        const AuthLogo(size: 48),
        SizedBox(height: 8.h),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Duka',
                style: AppTypography.h5.copyWith(
                  color: AppColors.secondary,
                ),
              ),
              TextSpan(
                text: 'App',
                style: AppTypography.h5.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withAlpha(13),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DukaApp Terms & Conditions',
            style: AppTypography.h5,
          ),
          SizedBox(height: 4.h),
          Text(
            'Last Updated: June 2026',
            style: AppTypography.caption.copyWith(
              color: AppColors.textHint,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Please read these Terms & Conditions carefully before creating an account or using DukaApp. By registering, accessing, or using the platform, you agree to be bound by these terms.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          SizedBox(height: 20.h),
          _buildSection(
            '1. Account Registration',
            [
              'You agree to provide accurate, complete, and up-to-date business and personal information during registration.',
              'You are responsible for maintaining the confidentiality of your account credentials, including your username and password.',
              'You are responsible for all activities conducted through your account.',
              'DukaApp reserves the right to suspend or terminate accounts containing false, misleading, or unauthorized information.',
            ],
          ),
          _buildSection(
            '2. Business Records & Data',
            [
              'DukaApp provides tools for managing sales, inventory, purchases, expenses, customers, suppliers, and business operations.',
              'You are solely responsible for the accuracy and completeness of all data entered into the system.',
              'Reports, receipts, and financial summaries generated by the platform are based on the information you provide.',
              'Users should verify business records before making accounting, tax, legal, or financial decisions.',
            ],
          ),
          _buildSection(
            '3. Staff & User Access',
            [
              'Account owners and managers are responsible for assigning appropriate permissions to employees, attendants, and other users.',
              'Actions performed by authorized staff members are considered actions performed on behalf of the business.',
              'DukaApp is not responsible for losses resulting from incorrect permission assignments, unauthorized sharing of credentials, or staff misuse.',
            ],
          ),
          _buildSection(
            '4. Subscription & Payments',
            [
              'Certain features and modules may require an active subscription plan.',
              'Subscription fees are payable according to the selected package and billing period.',
              'Failure to renew a subscription may result in restricted access to some features or temporary suspension of services.',
              'Unless otherwise stated, subscription payments are non-refundable after activation.',
            ],
          ),
          _buildSection(
            '5. Acceptable Use',
            [
              'You agree not to:',
              '• Use the platform for unlawful, fraudulent, or misleading activities.',
              '• Attempt to gain unauthorized access to any system, account, or data.',
              '• Interfere with the security, performance, or availability of the platform.',
              '• Upload malicious software, viruses, or harmful content.',
              '• Use the platform in any manner that violates applicable laws or regulations.',
            ],
          ),
          _buildSection(
            '6. Data Ownership & Privacy',
            [
              'You retain ownership of the business data you enter into DukaApp.',
              'DukaApp may store, process, and back up your data solely for the purpose of providing and improving the service.',
              'We implement reasonable security measures to protect user information; however, no system can guarantee absolute security.',
              'Users are encouraged to maintain their own copies of critical business records where necessary.',
            ],
          ),
          _buildSection(
            '7. Service Availability',
            [
              'DukaApp strives to provide reliable and uninterrupted service.',
              'Maintenance, upgrades, technical issues, internet failures, or events beyond our control may occasionally affect service availability.',
              'We do not guarantee uninterrupted access to the platform at all times.',
            ],
          ),
          _buildSection(
            '8. Updates & Modifications',
            [
              'DukaApp may introduce new features, modify existing functionality, or discontinue certain services at its discretion.',
              'These Terms & Conditions may be updated periodically.',
              'Continued use of the platform after updates constitutes acceptance of the revised terms.',
            ],
          ),
          _buildSection(
            '9. Limitation of Liability',
            [
              'DukaApp shall not be liable for any indirect, incidental, consequential, or business losses arising from the use of the platform.',
              'We are not responsible for losses resulting from inaccurate data entry, user errors, unauthorized account access, hardware failures, internet interruptions, or third-party services.',
              'Users remain responsible for their business decisions, tax obligations, and regulatory compliance.',
            ],
          ),
          _buildSection(
            '10. Account Suspension & Termination',
            [
              'DukaApp reserves the right to suspend or terminate accounts that violate these Terms & Conditions.',
              'Users may stop using the service at any time.',
              'Upon termination, access to certain services and stored data may be limited or removed in accordance with our data retention policies.',
            ],
          ),
          _buildSection(
            '11. Governing Law',
            [
              'These Terms & Conditions shall be governed by and interpreted in accordance with the laws of the United Republic of Tanzania.',
              'Any disputes arising from the use of DukaApp shall be resolved through applicable legal procedures within Tanzania.',
            ],
          ),
          _buildSection(
            '12. Contact Information',
            [
              'For questions, support, or concerns regarding these Terms & Conditions, please contact:',
              '',
              'DukaApp Support',
              'Email: support@dukaapp.co.tz',
              'Phone: +255 755 644 282',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> points) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.h6.copyWith(fontSize: 14.sp)),
          SizedBox(height: 8.h),
          ...points.map((point) => Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Text(
                  point,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAcceptButton() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 20.w,
        vertical: 16.h,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: PrimaryButton(
        text: 'I Accept Terms',
        onPressed: onAccept,
      ),
    );
  }
}
