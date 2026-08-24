import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/stock/presentation/widgets/report_card.dart';

class _ReportData {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String? route;

  const _ReportData({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.route,
  });
}

class AccountsReportsPage extends StatelessWidget {
  const AccountsReportsPage({super.key});

  static const List<_ReportData> _reports = [
    _ReportData(
      name: 'Cash InHand & InBank',
      description: 'View cash in hand and bank balances.',
      icon: Icons.account_balance_wallet_rounded,
      color: AppColors.primary,
      route: '/accounts-reports/cash-in-hand-in-bank',
    ),
    _ReportData(
      name: 'Cash In',
      description: 'View all incoming cash transactions.',
      icon: Icons.arrow_downward_rounded,
      color: AppColors.success,
      route: '/accounts-reports/cash-in',
    ),
    _ReportData(
      name: 'Cash Out',
      description: 'View all outgoing cash transactions.',
      icon: Icons.arrow_upward_rounded,
      color: AppColors.danger,
      route: '/accounts-reports/cash-out',
    ),
    _ReportData(
      name: 'Accounts Balance',
      description: 'View balances across all accounts.',
      icon: Icons.account_balance_rounded,
      color: const Color(0xFF8B5CF6),
      route: '/accounts-reports/accounts-balance',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _reports.length,
              itemBuilder: (context, index) {
                final report = _reports[index];
                return ReportCard(
                  name: report.name,
                  description: report.description,
                  icon: report.icon,
                  iconColor: report.color,
                  onTap: () {
                    if (report.route != null) {
                      context.push(report.route!);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Coming soon', style: AppTypography.bodyMedium.copyWith(color: AppColors.textWhite)),
                          backgroundColor: AppColors.textSecondary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
          _buildBottomBar(context),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
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
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
          ),
        ),
      ),
      leadingWidth: 56,
      title: Column(
        children: [
          Text('Accounts Reports', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('Select a report to view.', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10)),
        ],
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.divider),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppConstants.paddingLG,
        right: AppConstants.paddingLG,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: AppConstants.buttonHeight,
        child: OutlinedButton(
          onPressed: () => context.pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
          ),
          child: Text('Close', style: AppTypography.buttonLarge.copyWith(color: AppColors.textSecondary)),
        ),
      ),
    );
  }
}
