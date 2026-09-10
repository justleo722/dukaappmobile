import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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
  Uint8List? _invoiceImageBytes;

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

  Future<void> _captureInvoiceImage() async {
    try {
      final boundary = _invoiceKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      _invoiceImageBytes = byteData.buffer.asUint8List();
    } catch (_) {}
  }

  Future<void> _downloadAsImage() async {
    try {
      if (_invoiceImageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not capture invoice'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }

      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/invoice_${widget.orderId}.png';
      final file = File(filePath);
      await file.writeAsBytes(_invoiceImageBytes!);

      if (mounted) {
        await Share.shareXFiles(
          [XFile(filePath, mimeType: 'image/png')],
          subject: 'Invoice ${widget.orderId}',
          text: 'Order Invoice for ${widget.orderId}',
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
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Invoice Header ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: Colors.white24,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'DukaApp',
                              style: AppTypography.h5.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                              ),
                              child: Text(
                                'INVOICE',
                                style: AppTypography.captionBold.copyWith(
                                  color: Colors.white,
                                  letterSpacing: 2,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // --- Order Status Bar ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        color: AppColors.success.withValues(alpha: 0.1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ORDER RECEIVED',
                              style: AppTypography.captionBold.copyWith(
                                color: AppColors.success,
                                letterSpacing: 1.5,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // --- Invoice Body ---
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Order Info
                            _buildInvoiceInfoSection('Order Details', [
                              _buildInvoiceRow('Order ID', widget.orderId),
                              _buildInvoiceRow('Date', _formatDateTime()),
                            ]),
                            const SizedBox(height: 16),

                            // Customer Info
                            _buildInvoiceInfoSection('Customer Information', [
                              _buildInvoiceRow('Name', widget.customerName),
                              _buildInvoiceRow('Phone', widget.phone),
                              _buildInvoiceRow('Address', widget.address),
                            ]),
                            const SizedBox(height: 16),

                            // Delivery & Payment
                            _buildInvoiceInfoSection('Delivery & Payment', [
                              _buildInvoiceRow('Delivery', widget.deliveryMethod),
                              _buildInvoiceRow('Payment', widget.paymentMethod),
                            ]),
                            const SizedBox(height: 20),

                            // Items Header
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                              ),
                              child: Text(
                                'ORDER ITEMS',
                                style: AppTypography.captionBold.copyWith(
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                  fontSize: 11,
                                ),
                              ),
                            ),

                            // Items Table
                            Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  left: BorderSide(color: AppColors.border, width: 0.5),
                                  right: BorderSide(color: AppColors.border, width: 0.5),
                                  bottom: BorderSide(color: AppColors.border, width: 0.5),
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Table header
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    color: AppColors.background,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 4,
                                          child: Text('ITEM', style: AppTypography.captionBold.copyWith(fontSize: 10, color: AppColors.textSecondary)),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text('QTY', style: AppTypography.captionBold.copyWith(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text('PRICE', style: AppTypography.captionBold.copyWith(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.right),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text('TOTAL', style: AppTypography.captionBold.copyWith(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.right),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Items
                                  ...widget.items.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final item = entry.value;
                                    final qty = (item['qty'] as int?) ?? 1;
                                    final price = _parsePrice((item['price'] as String?) ?? '0');
                                    final itemTotal = price * qty;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      color: idx.isEven ? Colors.white : AppColors.background.withValues(alpha: 0.5),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 4,
                                            child: Text(
                                              (item['name'] as String?) ?? 'Product',
                                              style: AppTypography.bodySmall.copyWith(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              '$qty',
                                              style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              _formatPrice(price),
                                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              _formatPrice(itemTotal),
                                              style: AppTypography.bodySmall.copyWith(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w700,
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
                            ),
                            const SizedBox(height: 20),

                            // Totals
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                              ),
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                children: [
                                  _buildTotalRow('Subtotal', _formatPrice(widget.subtotal)),
                                  const SizedBox(height: 6),
                                  _buildTotalRow(
                                    'Delivery',
                                    widget.deliveryFee == 0 ? 'Free' : _formatPrice(widget.deliveryFee),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Divider(color: AppColors.divider, height: 1),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'GRAND TOTAL',
                                        style: AppTypography.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        _formatPrice(widget.total),
                                        style: AppTypography.h6.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Footer
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.storefront_rounded,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Thank you for shopping with DukaApp!',
                                    style: AppTypography.bodySmall.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Keep this invoice for your records.',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
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

  int _parsePrice(String priceStr) {
    final cleaned = priceStr.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  Widget _buildInvoiceInfoSection(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppConstants.radiusSM),
            ),
          ),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.captionBold.copyWith(
              color: AppColors.primary,
              letterSpacing: 1.5,
              fontSize: 10,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(AppConstants.radiusSM),
            ),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }

  Widget _buildInvoiceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
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
                onPressed: () async {
                  _copyOrderId();
                  await _captureInvoiceImage();
                  if (mounted) setState(() => _showConfirmation = true);
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
