import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';

class SupplierPurchaseAccordionCard extends StatelessWidget {
  final String purchaseNumber;
  final String date;
  final String status;
  final double total;
  final double paid;
  final double balance;
  final List<Map<String, dynamic>> products;
  final bool isExpanded;
  final VoidCallback? onExpandToggle;
  final VoidCallback? onDownloadPdf;
  final VoidCallback? onClearCredit;

  const SupplierPurchaseAccordionCard({
    super.key,
    required this.purchaseNumber,
    required this.date,
    required this.status,
    required this.total,
    required this.paid,
    required this.balance,
    this.products = const [],
    this.isExpanded = false,
    this.onExpandToggle,
    this.onDownloadPdf,
    this.onClearCredit,
  });

  Color get _statusColor {
    switch (status) {
      case 'Paid':
        return AppColors.success;
      case 'Partial':
        return AppColors.warning;
      case 'Unpaid':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }

  Color get _leftBarColor {
    switch (status) {
      case 'Paid':
        return AppColors.success;
      case 'Partial':
        return AppColors.warning;
      case 'Unpaid':
        return AppColors.danger;
      default:
        return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onExpandToggle,
              borderRadius: BorderRadius.circular(14),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: _leftBarColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          bottomLeft: Radius.circular(14),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(child: _buildPurchaseInfo()),
                            const SizedBox(width: 10),
                            _buildTotalAndChevron(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildExpandedContent(),
        ],
      ),
    );
  }

  Widget _buildPurchaseInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          purchaseNumber,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              date,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status,
                style: AppTypography.caption.copyWith(
                  color: _statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalAndChevron() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Total',
              style: AppTypography.caption.copyWith(
                color: AppColors.textHint,
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'TZS ${total.toStringAsFixed(0)}',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(width: 6),
        AnimatedRotation(
          turns: isExpanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 250),
          child: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textHint,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: isExpanded
          ? Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 1,
                    color: AppColors.border,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow('Total', 'TZS ${total.toStringAsFixed(0)}', AppColors.textPrimary),
                  const SizedBox(height: 6),
                  _buildSummaryRow('Paid', 'TZS ${paid.toStringAsFixed(0)}', AppColors.success),
                  const SizedBox(height: 6),
                  _buildSummaryRow('Balance', 'TZS ${balance.toStringAsFixed(0)}', balance > 0 ? AppColors.danger : AppColors.success),
                  const SizedBox(height: 12),
                  if (products.isNotEmpty) ...[
                    Text(
                      'Purchased Products',
                      style: AppTypography.captionBold.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildProductListHeader(),
                    ...products.map((product) => _buildProductRow(product)),
                    const SizedBox(height: 4),
                    _buildProductListFooter(),
                  ],
                  const SizedBox(height: 12),
                  _buildActionButtons(),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildProductListHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Product',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Qty',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Unit Cost',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Amount',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(Map<String, dynamic> product) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              product['name'] ?? '',
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${product['quantity'] ?? 0}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'TZS ${(product['unitCost'] ?? 0).toStringAsFixed(0)}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontSize: 11,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'TZS ${(product['amount'] ?? 0).toStringAsFixed(0)}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductListFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total (${products.length} items)',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            'TZS ${total.toStringAsFixed(0)}',
            style: AppTypography.captionBold.copyWith(
              fontSize: 11,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (onDownloadPdf != null)
          Expanded(
            child: _buildActionButton(
              icon: Icons.picture_as_pdf_rounded,
              label: 'Download Supplier PDF',
              color: AppColors.danger,
              onTap: onDownloadPdf!,
            ),
          ),
        if (onDownloadPdf != null && onClearCredit != null)
          const SizedBox(width: 8),
        if (onClearCredit != null)
          Expanded(
            child: _buildActionButton(
              icon: Icons.clear_all_rounded,
              label: 'Clear Credit Balance',
              color: AppColors.success,
              onTap: onClearCredit!,
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppConstants.radiusSM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
