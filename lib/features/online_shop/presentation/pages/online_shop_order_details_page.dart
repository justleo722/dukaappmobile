import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';

class OnlineShopOrderDetailsPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const OnlineShopOrderDetailsPage({super.key, required this.order});

  @override
  State<OnlineShopOrderDetailsPage> createState() =>
      _OnlineShopOrderDetailsPageState();
}

class _OnlineShopOrderDetailsPageState
    extends State<OnlineShopOrderDetailsPage> {
  late String _currentStatus;
  final GlobalKey _invoiceKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order['status'] as String;
  }

  Future<void> _downloadInvoiceAsImage() async {
    try {
      final boundary = _invoiceKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final buffer = byteData.buffer.asUint8List();
      final directory = await getTemporaryDirectory();
      final orderId = widget.order['orderId'] as String;
      final filePath = '${directory.path}/$orderId.png';
      final file = File(filePath);
      await file.writeAsBytes(buffer);

      if (mounted) {
        await Share.shareXFiles(
          [XFile(filePath, mimeType: 'image/png')],
          subject: 'Invoice $orderId',
          text: 'Order Invoice for $orderId',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share invoice'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final order = widget.order;
    final products = order['products'] as List;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  RepaintBoundary(
                    key: _invoiceKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOrderMetadata(order),
                        const SizedBox(height: 16),
                        _buildInvoiceSection(order, products),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActionSection(),
                  SizedBox(height: 24 + bottomPadding),
                ],
              ),
            ),
          ),
        ],
      ),
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
            onPressed: () => context.go('/online-shop/manage-orders'),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
      ),
      leadingWidth: 56,
      title: Text(
        'Order Details',
        style: AppTypography.h6.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.divider),
      ),
    );
  }

  Widget _buildOrderMetadata(Map<String, dynamic> order) {
    final status = _currentStatus;
    final statusColor = _getStatusColor(status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.paddingMD),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order['orderId'] as String,
                    style: AppTypography.h5.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusFull),
                  ),
                  child: Text(
                    status,
                    style: AppTypography.labelSmall.copyWith(
                      color: statusColor,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetadataRow(Icons.person_rounded, 'Customer',
                order['customer'] as String),
            const SizedBox(height: 10),
            _buildMetadataRow(Icons.location_on_rounded, 'Address',
                order['address'] as String),
            const SizedBox(height: 10),
            _buildMetadataRow(
                Icons.calendar_today_rounded, 'Date', order['date'] as String),
            const SizedBox(height: 10),
            _buildMetadataRow(Icons.payment_rounded, 'Payment Method',
                order['payment'] as String),
            const SizedBox(height: 10),
            _buildMetadataRow(
                Icons.info_rounded, 'Status', _currentStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textHint),
        const SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: AppTypography.caption.copyWith(fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceSection(
      Map<String, dynamic> order, List products) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
      child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppConstants.paddingMD),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF14B8A6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Invoice',
                    style: AppTypography.h6.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInvoiceHeader(),
              const SizedBox(height: 8),
              ...products.map((p) => _buildInvoiceItem(p)),
              const Divider(height: 24, color: AppColors.divider),
              _buildSummaryRow('Subtotal', order['subtotal'] as String),
              const SizedBox(height: 8),
              _buildSummaryRow('Delivery Charge', order['delivery'] as String),
              const SizedBox(height: 8),
              _buildSummaryRow('Discount', order['discount'] as String),
              const Divider(height: 24, color: AppColors.divider),
              _buildSummaryRow(
                'Final Total',
                order['finalTotal'] as String,
                isBold: true,
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildInvoiceHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Product',
              style: AppTypography.labelSmall.copyWith(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Qty',
              style: AppTypography.labelSmall.copyWith(
                  fontSize: 11, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Unit Price',
              style: AppTypography.labelSmall.copyWith(
                  fontSize: 11, color: AppColors.textSecondary),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Total',
              style: AppTypography.labelSmall.copyWith(
                  fontSize: 11, color: AppColors.textSecondary),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceItem(Map<String, dynamic> product) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              product['name'] as String,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${product['qty']}',
              style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatCurrency(product['price'] as int),
              style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimary),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatCurrency(product['total'] as int),
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold
              ? AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )
              : AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
        ),
        Text(
          value,
          style: isBold
              ? AppTypography.h6.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )
              : AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
        ),
      ],
    );
  }

  Widget _buildActionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Actions',
                style: AppTypography.h6.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.paddingMD),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update Status',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStatusDropdown(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: AppConstants.buttonHeight,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Status updated to $_currentStatus'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusMD),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.update_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Update Status',
                          style: AppTypography.buttonLarge.copyWith(
                            color: AppColors.textWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: AppConstants.buttonHeight,
                  child: OutlinedButton(
                    onPressed: _downloadInvoiceAsImage,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusMD),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.download_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Download Invoice',
                          style: AppTypography.buttonLarge.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _currentStatus,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          style:
              AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          items: _statusOptions.map((String status) {
            return DropdownMenuItem<String>(
              value: status,
              child: Text(status),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() => _currentStatus = newValue!);
          },
        ),
      ),
    );
  }

  String _formatCurrency(int amount) {
    final formatted = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < formatted.length; i++) {
      if (i > 0 && (formatted.length - i) % 3 == 0) buffer.write(',');
      buffer.write(formatted[i]);
    }
    return 'Tsh ${buffer.toString()}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Delivered':
        return AppColors.success;
      case 'Delivering':
        return AppColors.secondary;
      case 'Received':
        return AppColors.primary;
      case 'Cancelled':
        return AppColors.danger;
      case 'Processing':
        return AppColors.warning;
      default:
        return AppColors.textHint;
    }
  }
}

const List<String> _statusOptions = [
  'Received',
  'Processing',
  'Delivering',
  'Delivered',
  'Cancelled',
];
