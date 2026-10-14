import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';

/// Order ID from what the user typed or pasted: "#12", "ORD-0012", or a whole
/// tracking link (…/tracking?order_id=ORD-0012).
String parseOrderIdInput(String input) {
  final v = input.trim();
  final uri = Uri.tryParse(v);
  final fromLink = uri?.queryParameters['order_id'];
  if (fromLink != null && fromLink.trim().isNotEmpty) return fromLink.trim();
  return v.replaceFirst(RegExp(r'^#'), '');
}

/// Looks an order up in-app (Onlineshop::tracking, format=json) and shows the
/// result in the sheet. Without [shopId] the order is looked up across all shops.
class TrackOrderBottomSheet extends ConsumerStatefulWidget {
  final String? shopId;

  const TrackOrderBottomSheet({super.key, this.shopId});

  static void show({required BuildContext context, String? shopId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TrackOrderBottomSheet(shopId: shopId),
    );
  }

  @override
  ConsumerState<TrackOrderBottomSheet> createState() =>
      _TrackOrderBottomSheetState();
}

class _TrackOrderBottomSheetState extends ConsumerState<TrackOrderBottomSheet> {
  final TextEditingController _orderIdController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _errorText;
  bool _loading = false;
  Map<String, dynamic>? _tracking;

  @override
  void dispose() {
    _orderIdController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pasteOrderId() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty || !mounted) return;
    final id = parseOrderIdInput(text);
    _orderIdController.text = id;
    _orderIdController.selection = TextSelection.collapsed(offset: id.length);
    setState(() => _errorText = null);
  }

  Future<void> _handleTrackOrder() async {
    final orderId = parseOrderIdInput(_orderIdController.text);
    if (orderId.isEmpty) {
      setState(() => _errorText = 'Please enter an Order ID');
      _focusNode.requestFocus();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _errorText = null;
      _loading = true;
      _tracking = null;
    });
    try {
      final res = await ref
          .read(apiServiceProvider)
          .getOnlineshopTracking(orderId, shopId: widget.shopId);
      if (!mounted) return;
      final tracking = res['tracking'];
      setState(() {
        if (res['status']?.toString() == 'success' && tracking is Map) {
          _tracking = Map<String, dynamic>.from(tracking);
        } else {
          _errorText = (res['message']?.toString().isNotEmpty ?? false)
              ? res['message'].toString()
              : 'Order not found. Check the Order ID and try again.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorText =
            'Could not check the order. Check your connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildTrackingResult(Map<String, dynamic> t) {
    String v(String key) {
      final value = (t[key] ?? '').toString().trim();
      return value.isEmpty ? '-' : value;
    }

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order ${v('order_id')}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                ),
                child: Text(
                  v('status'),
                  style: AppTypography.captionBold.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          row('Placed on', v('placed_on')),
          row('Last update', v('step_time')),
          if (v('customer_name') != '-') row('Customer', v('customer_name')),
          row('Payment', v('payment_method')),
          row('Delivery', v('delivery_method')),
          row('Address', v('address')),
          row('Total', v('total')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomPadding = media.padding.bottom;
    // Lift the sheet above the keyboard and keep it inside the space left, so
    // its content scrolls instead of being hidden.
    final keyboard = media.viewInsets.bottom;
    final available = media.size.height - keyboard - media.padding.top - 16;
    final maxHeight = keyboard > 0 ? available : media.size.height * 0.65;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Track Your Order',
                        style: AppTypography.h5.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 24),
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: AppColors.textWhite,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter your Order ID to check the\ndelivery status.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Enter Order ID',
                    style: AppTypography.label.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _orderIdController,
                  focusNode: _focusNode,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. ORD-2026-001',
                    suffixIcon: IconButton(
                      tooltip: 'Paste',
                      onPressed: _pasteOrderId,
                      icon: const Icon(
                        Icons.content_paste_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textHint,
                    ),
                    errorText: _errorText,
                    errorStyle: AppTypography.caption.copyWith(
                      color: AppColors.danger,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusMD,
                      ),
                      borderSide: const BorderSide(
                        color: AppColors.inputBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusMD,
                      ),
                      borderSide: const BorderSide(
                        color: AppColors.inputBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusMD,
                      ),
                      borderSide: const BorderSide(
                        color: AppColors.inputFocusBorder,
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusMD,
                      ),
                      borderSide: const BorderSide(
                        color: AppColors.inputErrorBorder,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusMD,
                      ),
                      borderSide: const BorderSide(
                        color: AppColors.inputErrorBorder,
                        width: 1.5,
                      ),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleTrackOrder(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: AppConstants.buttonHeight,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _handleTrackOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.textWhite,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusMD,
                        ),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textWhite,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Track Order',
                                style: AppTypography.buttonLarge.copyWith(
                                  color: AppColors.textWhite,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "You'll receive this ID after placing an order.",
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
                if (_tracking != null) ...[
                  const SizedBox(height: 16),
                  _buildTrackingResult(_tracking!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
