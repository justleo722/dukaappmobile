import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dukaapp/core/providers.dart';

class ReceiptWidget extends ConsumerWidget {
  final String title;
  final String receiptNumber;
  final String date;
  final String time;
  final String cashier;
  final String paymentMode;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double totalPaid;
  final double amountReceived;
  final double discount;
  final String? footerNote;
  final String? customerName;
  final VoidCallback? onClose;
  final VoidCallback? onPrint;

  const ReceiptWidget({
    super.key,
    required this.title,
    required this.receiptNumber,
    required this.date,
    required this.time,
    required this.cashier,
    required this.paymentMode,
    required this.items,
    required this.subtotal,
    required this.totalPaid,
    required this.amountReceived,
    this.discount = 0,
    this.footerNote,
    this.customerName,
    this.onClose,
    this.onPrint,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String receiptNumber,
    required String date,
    required String time,
    required String cashier,
    required String paymentMode,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double totalPaid,
    required double amountReceived,
    double discount = 0,
    String? footerNote,
    String? customerName,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        ),
        child: ReceiptWidget(
          title: title,
          receiptNumber: receiptNumber,
          date: date,
          time: time,
          cashier: cashier,
          paymentMode: paymentMode,
          items: items,
          subtotal: subtotal,
          totalPaid: totalPaid,
          amountReceived: amountReceived,
          discount: discount,
          footerNote: footerNote,
          customerName: customerName,
          onClose: () => Navigator.pop(context),
          onPrint: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Printing receipt...')),
            );
          },
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###');
    return 'Tsh ${formatter.format(amount)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopName = ref.read(authProvider).activeShop?.shopName ?? 'My Shop';
    final cfg = ref.watch(shopConfigProvider).valueOrNull;
    final shopAddress = cfg?.shopAddress ?? '';
    final shopPhone = cfg?.shopPhone ?? '';
    final shopTin = cfg?.shopTin ?? '';
    final shopMessage = footerNote ?? cfg?.receiptMessage ?? '';
    return Container(
      width: 320,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStoreHeader(shopName, shopAddress, shopPhone, shopTin),
                  const SizedBox(height: 16),
                  _buildDashedDivider(),
                  const SizedBox(height: 12),
                  _buildReceiptInfo(),
                  const SizedBox(height: 12),
                  _buildDashedDivider(),
                  const SizedBox(height: 12),
                  _buildCashierInfo(),
                  const SizedBox(height: 16),
                  _buildItemsSection(),
                  const SizedBox(height: 16),
                  _buildDashedDivider(),
                  const SizedBox(height: 12),
                  _buildTotalsSection(),
                  const SizedBox(height: 16),
                  _buildDashedDivider(),
                  const SizedBox(height: 12),
                  _buildFooter(shopMessage),
                ],
              ),
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStoreHeader(String shopName, String shopAddress, String shopPhone, String shopTin) {
    return Column(
      children: [
        Center(
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.store_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            shopName,
            style: AppTypography.h5.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              title,
              style: AppTypography.captionBold.copyWith(
                color: AppColors.primary,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (shopAddress.isNotEmpty)
        Center(
          child: Text(
            shopAddress,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (shopPhone.isNotEmpty || shopTin.isNotEmpty) ...[
          const SizedBox(height: 6),
          Center(
            child: Text(
              [
                if (shopPhone.isNotEmpty) 'Tel: $shopPhone',
                if (shopTin.isNotEmpty) 'TIN: $shopTin',
              ].join('\n'),
              style: AppTypography.caption.copyWith(
                color: AppColors.textHint,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDashedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashWidth = 6.0;
        final dashSpace = 4.0;
        final dashCount = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return Container(
              width: dashWidth,
              height: 1,
              color: AppColors.border,
            );
          }),
        );
      },
    );
  }

  Widget _buildReceiptInfo() {
    return Column(
      children: [
        _buildInfoRow('Receipt No:', receiptNumber),
        const SizedBox(height: 4),
        _buildInfoRow('Date:', date),
        const SizedBox(height: 4),
        _buildInfoRow('Time:', time),
      ],
    );
  }

  Widget _buildCashierInfo() {
    return Column(
      children: [
        if (customerName != null && customerName!.isNotEmpty) ...[
          _buildInfoRow('Customer:', customerName!),
          const SizedBox(height: 4),
        ],
        _buildInfoRow('Cashier:', cashier),
        const SizedBox(height: 4),
        _buildInfoRow('Payment:', paymentMode),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textHint,
          ),
        ),
        Text(
          value,
          style: AppTypography.captionBold.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ITEMS',
          style: AppTypography.captionBold.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        ...items.map((item) => _buildItemRow(item)),
      ],
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    final name = item['name'] as String? ?? '';
    final quantity = item['quantity'] as int? ?? 0;
    final price = (item['price'] as num?)?.toDouble() ?? 0;
    final total = price * quantity;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                '$quantity x ${_formatCurrency(price)}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textHint,
                ),
              ),
              const Spacer(),
              Text(
                _formatCurrency(total),
                style: AppTypography.captionBold.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 1,
            color: AppColors.borderLight,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsSection() {
    return Column(
      children: [
        _buildTotalRow('Subtotal:', _formatCurrency(subtotal)),
        if (discount > 0) ...[
          const SizedBox(height: 8),
          _buildTotalRow('Discount:', '- ${_formatCurrency(discount)}', color: AppColors.success),
        ],
        const SizedBox(height: 8),
        _buildTotalRow('Total Paid:', _formatCurrency(totalPaid)),
        const SizedBox(height: 8),
        _buildTotalRow(
          'Amount Received:',
          _formatCurrency(amountReceived),
          isBold: true,
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: color ?? AppColors.textPrimary,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(String message) {
    if (message.isEmpty) return const SizedBox.shrink();
    return Center(
      child: Text(
        message,
        style: AppTypography.caption.copyWith(
          color: AppColors.textHint,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onClose,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Close',
                style: AppTypography.buttonMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: onPrint,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Print Receipt',
                style: AppTypography.buttonMedium.copyWith(
                  color: AppColors.textWhite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
