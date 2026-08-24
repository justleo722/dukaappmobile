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

class ProfitExpensesReportsHubPage extends StatelessWidget {
  const ProfitExpensesReportsHubPage({super.key});

  static const List<_ReportData> _reports = [
    _ReportData(
      name: 'Daily Profit',
      description: 'View daily profit breakdown.',
      icon: Icons.trending_up_rounded,
      color: AppColors.success,
      route: '/profit-expenses/reports/daily-profit',
    ),
    _ReportData(
      name: 'All Expenses',
      description: 'View all expense records.',
      icon: Icons.receipt_long_rounded,
      color: AppColors.primary,
      route: '/profit-expenses/reports/all-expenses',
    ),
    _ReportData(
      name: 'Profits',
      description: 'View profit by item sold.',
      icon: Icons.account_balance_rounded,
      color: Color(0xFF14B8A6),
      route: '/profit-expenses/reports/profits',
    ),
    _ReportData(
      name: 'Loss',
      description: 'View bad, lost and expired stock.',
      icon: Icons.warning_amber_rounded,
      color: AppColors.danger,
      route: '/profit-expenses/reports/loss',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(context),
      body: SafeArea(
        top: false,
        child: ListView.builder(
          padding: EdgeInsets.only(
            top: 12,
            bottom: 24 + bottomPadding,
          ),
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
                      content: Text(
                        '${report.name} coming soon',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textWhite,
                        ),
                      ),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                      ),
                    ),
                  );
                }
              },
            );
          },
        ),
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
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
      ),
      leadingWidth: 56,
      title: Column(
        children: [
          Text(
            'Profit & Expenses Reports',
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'View and export reports.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            ),
            child: IconButton(
              onPressed: null,
              icon: Icon(
                Icons.download_rounded,
                color: AppColors.textHint,
                size: 20,
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppColors.divider,
        ),
      ),
    );
  }
}
