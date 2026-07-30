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

class StockReportsPage extends StatelessWidget {
  const StockReportsPage({super.key});

  static const List<_ReportData> _reports = [
    _ReportData(
      name: 'All Stock',
      description: 'View all available stock items.',
      icon: Icons.inventory_2_rounded,
      color: AppColors.primary,
      route: '/stock-reports/all-stock',
    ),
    _ReportData(
      name: 'Combined Stock Value',
      description: 'View the total value of current inventory.',
      icon: Icons.payments_rounded,
      color: AppColors.success,
      route: '/stock-reports/combined-stock-value',
    ),
    _ReportData(
      name: 'Stock by Category',
      description: 'Browse stock grouped by category.',
      icon: Icons.category_rounded,
      color: AppColors.secondary,
      route: '/stock-reports/stock-by-category',
    ),
    _ReportData(
      name: 'Price List',
      description: 'View buying and selling prices.',
      icon: Icons.local_offer_rounded,
      color: Color(0xFF8B5CF6),
      route: '/stock-reports/price-list',
    ),
    _ReportData(
      name: 'Counting Sheet',
      description: 'Generate a stock counting sheet.',
      icon: Icons.checklist_rounded,
      color: Color(0xFF06B6D4),
      route: '/stock-reports/counting-sheet',
    ),
    _ReportData(
      name: 'Low Stock',
      description: 'Products that are running low.',
      icon: Icons.warning_amber_rounded,
      color: AppColors.warning,
      route: '/stock-reports/low-stock',
    ),
    _ReportData(
      name: 'Bad Stock',
      description: 'Damaged products report.',
      icon: Icons.error_outline_rounded,
      color: AppColors.secondary,
      route: '/stock-reports/bad-stock',
    ),
    _ReportData(
      name: 'Lost Stock',
      description: 'Lost inventory report.',
      icon: Icons.remove_shopping_cart_rounded,
      color: AppColors.textSecondary,
      route: '/stock-reports/lost-stock',
    ),
    _ReportData(
      name: 'About to Expire',
      description: 'Products nearing expiry.',
      icon: Icons.schedule_rounded,
      color: AppColors.warning,
      route: '/stock-reports/about-to-expire',
    ),
    _ReportData(
      name: 'Expired',
      description: 'Expired products.',
      icon: Icons.event_busy_rounded,
      color: AppColors.danger,
      route: '/stock-reports/expired',
    ),
    _ReportData(
      name: 'Import History',
      description: 'View previous stock imports.',
      icon: Icons.history_rounded,
      color: AppColors.primary,
      route: '/stock-reports/import-history',
    ),
    _ReportData(
      name: 'Generate Barcodes',
      description: 'Generate printable product barcodes.',
      icon: Icons.qr_code_rounded,
      color: Color(0xFF8B5CF6),
      route: '/stock-reports/generate-barcode',
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
      bottomNavigationBar: _buildBottomBar(context),
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
            'Stock Reports',
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'View and export inventory reports.',
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

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppConstants.paddingLG,
        right: AppConstants.paddingLG,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: const Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: AppConstants.buttonHeight,
        child: OutlinedButton(
          onPressed: () => context.pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(
              color: AppColors.border,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            ),
          ),
          child: Text(
            'Close',
            style: AppTypography.buttonLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
