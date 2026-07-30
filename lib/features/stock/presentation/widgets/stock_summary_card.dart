import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';

class StockSummaryCard extends StatelessWidget {
  final String totalStockValue;
  final String profitEstimate;
  final int allProducts;

  const StockSummaryCard({
    super.key,
    required this.totalStockValue,
    required this.profitEstimate,
    required this.allProducts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              label: 'Total Stock Value',
              value: totalStockValue,
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: AppColors.divider,
          ),
          Expanded(
            child: _buildStatItem(
              label: 'Profit Estimate',
              value: profitEstimate,
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: AppColors.divider,
          ),
          Expanded(
            child: _buildStatItem(
              label: 'All Products',
              value: '$allProducts',
            ),
          ),
        ],
      ),
    );
  }

  double _getFontSize(String value) {
    final length = value.length;
    if (length <= 10) return 18;
    if (length <= 13) return 16;
    if (length <= 16) return 14;
    return 12;
  }

  Widget _buildStatItem({required String label, required String value}) {
    final fontSize = _getFontSize(value);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTypography.h5.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: fontSize.toDouble(),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
