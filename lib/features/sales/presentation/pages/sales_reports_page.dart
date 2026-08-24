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

class SalesReportsPage extends StatelessWidget {
  const SalesReportsPage({super.key});

  static const List<_ReportData> _reports = [
    _ReportData(
      name: 'Total Sales',
      description: 'View complete sales summary.',
      icon: Icons.point_of_sale_rounded,
      color: AppColors.primary,
      route: '/sales/reports/total-sales',
    ),
    _ReportData(
      name: 'Combined Total Sales',
      description: 'View sales across all staff.',
      icon: Icons.summarize_rounded,
      color: AppColors.success,
      route: '/sales/reports/combined-total-sales',
    ),
    _ReportData(
      name: 'All Orders',
      description: 'Browse all orders placed.',
      icon: Icons.receipt_long_rounded,
      color: AppColors.secondary,
      route: '/sales/reports/all-orders',
    ),
    _ReportData(
      name: 'Invoices',
      description: 'View generated invoices.',
      icon: Icons.description_rounded,
      color: Color(0xFF8B5CF6),
      route: '/sales/reports/invoices',
    ),
    _ReportData(
      name: 'Credit Sales',
      description: 'View sales made on credit.',
      icon: Icons.credit_card_rounded,
      color: AppColors.warning,
      route: '/sales/reports/credit-sales',
    ),
    _ReportData(
      name: 'Customer on Credit',
      description: 'View customers with outstanding credit.',
      icon: Icons.people_alt_rounded,
      color: AppColors.danger,
      route: '/sales/reports/customer-on-credit',
    ),
    _ReportData(
      name: 'Sales by Payments',
      description: 'View sales grouped by payment method.',
      icon: Icons.payments_rounded,
      color: Color(0xFF06B6D4),
      route: '/sales/reports/sales-by-payments',
    ),
    _ReportData(
      name: 'Sales by Category',
      description: 'View sales grouped by category.',
      icon: Icons.category_rounded,
      color: Color(0xFF14B8A6),
      route: '/sales/reports/sales-by-category',
    ),
    _ReportData(
      name: 'Sales by Product',
      description: 'View sales grouped by product.',
      icon: Icons.inventory_2_rounded,
      color: Color(0xFF6366F1),
      route: '/sales/reports/sales-by-product',
    ),
    _ReportData(
      name: 'Unpaid Sales by Product',
      description: 'View unpaid sales for each product.',
      icon: Icons.shopping_cart_rounded,
      color: AppColors.secondary,
      route: '/sales/reports/unpaid-sales-by-product',
    ),
    _ReportData(
      name: 'Sales with VAT',
      description: 'View sales that include VAT.',
      icon: Icons.receipt_rounded,
      color: AppColors.primary,
      route: '/sales/reports/sales-with-vat',
    ),
    _ReportData(
      name: 'Sales without VAT',
      description: 'View sales that exclude VAT.',
      icon: Icons.receipt_long_rounded,
      color: AppColors.textSecondary,
      route: '/sales/reports/sales-without-vat',
    ),
    _ReportData(
      name: 'Staff Sales (By Items)',
      description: 'View sales per staff by item sold.',
      icon: Icons.badge_rounded,
      color: Color(0xFFEC4899),
      route: '/sales/reports/staff-sales-by-items',
    ),
    _ReportData(
      name: 'Individual Team Sales',
      description: 'View sales per team member.',
      icon: Icons.group_rounded,
      color: Color(0xFF9333EA),
      route: '/sales/reports/individual-team-sales',
    ),
    _ReportData(
      name: 'Sales by Customer',
      description: 'View sales grouped by customer.',
      icon: Icons.person_rounded,
      color: Color(0xFF0EA5E9),
      route: '/sales/reports/sales-by-customer',
    ),
    _ReportData(
      name: 'Sales by Staff',
      description: 'View sales grouped by staff member.',
      icon: Icons.badge_rounded,
      color: Color(0xFFD97706),
      route: '/sales/reports/sales-by-staff',
    ),
    _ReportData(
      name: 'Combined Sales by Staff',
      description: 'View combined sales for all staff.',
      icon: Icons.groups_rounded,
      color: Color(0xFF8B5CF6),
      route: '/sales/reports/combined-sales-by-staff',
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
            'Sales Reports',
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'View and export sales reports.',
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
