import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/sales/presentation/widgets/sale_product_tile.dart';
import 'package:dukaapp/features/sales/presentation/widgets/payment_summary_card.dart';
import 'package:dukaapp/features/sales/presentation/widgets/sales_bottom_actions.dart';

class SaleAccordionCard extends StatelessWidget {
  final String date;
  final String paymentStatus;
  final String soldBy;
  final String total;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectionChanged;
  final bool isExpanded;
  final VoidCallback? onExpandToggle;
  final List<Map<String, dynamic>> products;
  final String paymentMethod;
  final double paid;
  final double discount;
  final double balance;
  final VoidCallback? onDownload;
  final VoidCallback? onBackdate;
  final VoidCallback? onPrint;
  final VoidCallback? onPreview;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  /// Pay callback — supply for credit/unpaid sales to show the Pay button.
  final VoidCallback? onPay;

  const SaleAccordionCard({
    super.key,
    required this.date,
    required this.paymentStatus,
    required this.soldBy,
    required this.total,
    this.isSelected = false,
    this.onSelectionChanged,
    this.isExpanded = false,
    this.onExpandToggle,
    this.products = const [],
    this.paymentMethod = 'Cash',
    this.paid = 0,
    this.discount = 0,
    this.balance = 0,
    this.onDownload,
    this.onBackdate,
    this.onPrint,
    this.onPreview,
    this.onEdit,
    this.onDelete,
    this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLG,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.04)
            : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
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
                        color: AppColors.success,
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
                            _buildCheckbox(),
                            const SizedBox(width: 10),
                            Expanded(child: _buildSaleInfo()),
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

  Widget _buildCheckbox() {
    return SizedBox(
      width: 22,
      height: 22,
      child: Checkbox(
        value: isSelected,
        onChanged: onSelectionChanged,
        activeColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildSaleInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          date,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                paymentStatus,
                style: AppTypography.caption.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Sold By: $soldBy',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
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
              total,
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
                  Text(
                    'Purchased Products',
                    style: AppTypography.captionBold.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...products.map(
                    (product) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SaleProductTile(
                        productName: product['name'] ?? '',
                        quantity: product['quantity'] ?? 0,
                        price: (product['price'] ?? 0).toDouble(),
                        total: (product['total'] ?? 0).toDouble(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  PaymentSummaryCard(
                    paymentMethod: paymentMethod,
                    paid: paid,
                    discount: discount,
                    balance: balance,
                  ),
                  const SizedBox(height: 12),
                  SalesBottomActions(
                    onDownload: onDownload,
                    onBackdate: onBackdate,
                    onPrint: onPrint,
                    onPreview: onPreview,
                    onEdit: onEdit,
                    onDelete: onDelete,
                    onPay: onPay,
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
