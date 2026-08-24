// features/purchase/presentation/pages/purchase_reports/purchase_reports_hub_page.dart
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

class PurchaseReportsHubPage extends StatelessWidget {
  const PurchaseReportsHubPage({super.key});

  static const List<_ReportData> _reports = [
    _ReportData(
      name: 'Purchase History',
      description: 'View complete purchase history.',
      icon: Icons.history_rounded,
      color: AppColors.primary,
      route: '/purchases/reports/purchase_history',
    ),
    _ReportData(
      name: 'Total Purchase',
      description: 'View total purchase summary.',
      icon: Icons.shopping_cart_rounded,
      color: AppColors.success,
      route: '/purchases/reports/total_purchase',
    ),
    _ReportData(
      name: 'Orders',
      description: 'Browse all purchase orders.',
      icon: Icons.receipt_long_rounded,
      color: AppColors.secondary,
      route: '/purchases/reports/orders',
    ),
    _ReportData(
      name: 'Suppliers',
      description: 'View all suppliers.',
      icon: Icons.people_alt_rounded,
      color: Color(0xFF8B5CF6),
      route: '/purchases/reports/suppliers',
    ),
    _ReportData(
      name: 'Cash Purchase',
      description: 'View cash purchase records.',
      icon: Icons.payments_rounded,
      color: AppColors.warning,
      route: '/purchases/reports/cash_purchase',
    ),
    _ReportData(
      name: 'Credit Purchase',
      description: 'View purchases made on credit.',
      icon: Icons.credit_card_rounded,
      color: AppColors.danger,
      route: '/purchases/reports/credit_purchase',
    ),
    _ReportData(
      name: 'Purchase by Category',
      description: 'View purchases grouped by category.',
      icon: Icons.category_rounded,
      color: Color(0xFF06B6D4),
      route: '/purchases/reports/by_category',
    ),
    _ReportData(
      name: 'Purchase by Products',
      description: 'View purchases grouped by product.',
      icon: Icons.inventory_2_rounded,
      color: Color(0xFF14B8A6),
      route: '/purchases/reports/by_products',
    ),
    _ReportData(
      name: 'Purchase by Supplier',
      description: 'View purchases grouped by supplier.',
      icon: Icons.storefront_rounded,
      color: Color(0xFF6366F1),
      route: '/purchases/reports/by_supplier',
    ),
    _ReportData(
      name: 'Stock Returned',
      description: 'View stock returned to suppliers.',
      icon: Icons.assignment_return_rounded,
      color: Color(0xFFEC4899),
      route: '/purchases/reports/stock_returned',
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
            'Purchase Reports',
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'View and export purchase reports.',
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
