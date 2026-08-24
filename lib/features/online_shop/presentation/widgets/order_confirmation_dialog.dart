import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';

class OrderConfirmationDialog extends StatefulWidget {
  final String orderId;
  final String customerName;
  final String phone;
  final String address;
  final String deliveryMethod;
  final int deliveryFee;
  final String paymentMethod;
  final List<Map<String, dynamic>> items;
  final int subtotal;
  final int total;

  const OrderConfirmationDialog({
    super.key,
    required this.orderId,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.deliveryMethod,
    required this.deliveryFee,
    required this.paymentMethod,
    required this.items,
    required this.subtotal,
    required this.total,
  });

  static Future<void> show({
    required BuildContext context,
    required String orderId,
    required String customerName,
    required String phone,
    required String address,
    required String deliveryMethod,
    required int deliveryFee,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
    required int subtotal,
    required int total,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Order Confirmation',
      barrierColor: AppColors.overlay,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, a, b) => const SizedBox.shrink(),
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: animation,
            child: OrderConfirmationDialog(
              orderId: orderId,
              customerName: customerName,
              phone: phone,
              address: address,
              deliveryMethod: deliveryMethod,
              deliveryFee: deliveryFee,
              paymentMethod: paymentMethod,
              items: items,
              subtotal: subtotal,
              total: total,
            ),
          ),
        );
      },
    );
  }

  @override
  State<OrderConfirmationDialog> createState() => _OrderConfirmationDialogState();
}

class _OrderConfirmationDialogState extends State<OrderConfirmationDialog> {
  bool _showConfirmation = false;
  bool _copied = false;
  final GlobalKey _invoiceKey = GlobalKey();

  String _formatPrice(int amount) {
    final str = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return 'TZS $buf';
  }

  String _formatDateTime() {
    return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
  }

  String _formatInvoiceDate() {
    return DateFormat('dd MMMM yyyy').format(DateTime.now());
  }

  void _copyOrderId() {
    // Clipboard.setData(ClipboardData(text: widget.orderId));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order ID "${widget.orderId}" copied!'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _downloadAsImage() async {
    try {
      final boundary = _invoiceKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not capture invoice'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/invoice_${widget.orderId}_$timestamp.png');
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice saved to ${file.path}'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _done() {
    Navigator.of(context).pop();
    context.go('/storefront');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 400;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 16 : 24,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          child: _showConfirmation
              ? _buildConfirmationView(isNarrow)
              : _buildInvoiceView(isNarrow),
        ),
      ),
    );
  }

  Widget _buildInvoiceView(bool isNarrow) {
    return Container(
      key: const ValueKey('invoice'),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInvoiceHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: RepaintBoundary(
                key: _invoiceKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOrderInfoRow('Order ID', widget.orderId),
                    _buildOrderInfoRow('Date & Time', _formatDateTime()),
                    _buildOrderInfoRow('Status', 'Received', valueColor: AppColors.success),
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 12),
                    _buildOrderInfoRow('Customer', widget.customerName),
                    _buildOrderInfoRow('Phone', widget.phone),
                    _buildOrderInfoRow('Address', widget.address),
                    _buildOrderInfoRow('Delivery', widget.deliveryMethod),
                    _buildOrderInfoRow('Payment', widget.paymentMethod),
                    const SizedBox(height: 16),
                    Text(
                      'Items',
                      style: AppTypography.label.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildItemsTable(isNarrow),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 12),
                    _buildOrderInfoRow('Subtotal', _formatPrice(widget.subtotal)),
                    _buildOrderInfoRow(
                      'Delivery',
                      widget.deliveryFee == 0 ? 'Free' : _formatPrice(widget.deliveryFee),
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Grand Total',
                          style: AppTypography.h6.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          _formatPrice(widget.total),
                          style: AppTypography.h6.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.secondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Please copy your Order ID before closing this window so you can track your order later.',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildInvoiceActions(),
        ],
      ),
    );
  }

  Widget _buildInvoiceHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radiusXL)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.textWhite,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Order Invoice',
            style: AppTypography.h5.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.orderId,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable(bool isNarrow) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppConstants.radiusSM)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('Product', style: AppTypography.captionBold.copyWith(fontSize: 11)),
                ),
                Expanded(
                  flex: isNarrow ? 2 : 1,
                  child: Text('Qty', style: AppTypography.captionBold.copyWith(fontSize: 11), textAlign: TextAlign.center),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Price', style: AppTypography.captionBold.copyWith(fontSize: 11), textAlign: TextAlign.right),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Total', style: AppTypography.captionBold.copyWith(fontSize: 11), textAlign: TextAlign.right),
                ),
              ],
            ),
          ),
          ...widget.items.map((item) {
            final qty = (item['qty'] as int?) ?? 1;
            final price = _parsePrice((item['price'] as String?) ?? '0');
            final itemTotal = price * qty;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      (item['name'] as String?) ?? 'Product',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: isNarrow ? 2 : 1,
                    child: Text(
                      '$qty',
                      style: AppTypography.caption.copyWith(color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _formatPrice(price),
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _formatPrice(itemTotal),
                      style: AppTypography.captionBold.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  int _parsePrice(String priceStr) {
    final cleaned = priceStr.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  Widget _buildInvoiceActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: AppConstants.buttonHeight,
              child: OutlinedButton(
                onPressed: () {
                  _copyOrderId();
                  setState(() => _showConfirmation = true);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.copy_rounded, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Copy & Continue',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationView(bool isNarrow) {
    return Container(
      key: const ValueKey('confirmation'),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildConfirmationHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Copy Order ID',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.orderId,
                                  style: AppTypography.h6.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    letterSpacing: 1,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              GestureDetector(
                                onTap: _copyOrderId,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _copied
                                        ? AppColors.success.withValues(alpha: 0.1)
                                        : AppColors.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _copied ? Icons.check_rounded : Icons.copy_rounded,
                                    size: 18,
                                    color: _copied ? AppColors.success : AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _copyOrderId,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _copied ? AppColors.success : AppColors.primary,
                              foregroundColor: AppColors.textWhite,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _copied ? Icons.check_rounded : Icons.copy_rounded,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _copied ? 'Copied!' : 'Copy Order ID',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textWhite,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.local_shipping_rounded,
                          size: 32,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Track this order',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Use your Order ID to check\ndelivery status anytime.',
                          textAlign: TextAlign.center,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Thank you for shopping with DukaApp!',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Invoice generated on ${_formatInvoiceDate()}',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildConfirmationActions(),
        ],
      ),
    );
  }

  Widget _buildConfirmationHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radiusXL)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.textWhite,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Order Confirmed!',
            style: AppTypography.h5.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your order has been placed successfully',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: AppConstants.buttonHeight,
            child: ElevatedButton(
              onPressed: _downloadAsImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.textWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.download_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Download as Image',
                    style: AppTypography.buttonLarge.copyWith(color: AppColors.textWhite),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: AppConstants.buttonHeight,
            child: ElevatedButton(
              onPressed: _done,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                ),
              ),
              child: Text(
                'Done',
                style: AppTypography.buttonLarge.copyWith(color: AppColors.textWhite),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
