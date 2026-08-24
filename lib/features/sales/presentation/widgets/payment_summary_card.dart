import 'package:flutter/material.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';

class PaymentSummaryCard extends StatelessWidget {
  final String paymentMethod;
  final double paid;
  final double discount;
  final double balance;

  const PaymentSummaryCard({
    super.key,
    required this.paymentMethod,
    required this.paid,
    required this.discount,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payment_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Payment Summary',
                style: AppTypography.captionBold.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildRow('Payment Method', paymentMethod),
          const SizedBox(height: 6),
          _buildRow('Paid', _formatCurrency(paid)),
          const SizedBox(height: 6),
          _buildRow('Discount', _formatCurrency(discount)),
          const SizedBox(height: 6),
          _buildRow('Balance', _formatCurrency(balance)),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: AppTypography.captionBold.copyWith(
            color: AppColors.textPrimary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < formatted.length; i++) {
      if (i > 0 && (formatted.length - i) % 3 == 0) buffer.write(',');
      buffer.write(formatted[i]);
    }
    return 'Tsh ${buffer.toString()}';
  }
}
