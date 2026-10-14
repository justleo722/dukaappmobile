import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';

/// Shop ID from what the user typed or pasted: a plain id, the encoded id, or a
/// whole shop link (…/onlineshop/<encoded id>/…, or ?shop_id=S0003).
String parseShopIdInput(String input) {
  final v = input.trim();
  final uri = Uri.tryParse(v);
  if (uri != null && uri.hasScheme) {
    final fromQuery = uri.queryParameters['shop_id'];
    if (fromQuery != null && fromQuery.trim().isNotEmpty)
      return fromQuery.trim();
    final segments = uri.pathSegments;
    final i = segments.indexOf('onlineshop');
    if (i >= 0 && i + 1 < segments.length) {
      final seg = segments[i + 1];
      const pages = {
        'all-products',
        'all_products',
        'product',
        'checkout',
        'track',
        'tracking',
        'place-order',
        'apply-coupon',
      };
      if (!pages.contains(seg)) return seg;
    }
  }
  return v;
}

class ShopByIdBottomSheet extends StatefulWidget {
  final ValueChanged<String> onBrowseShop;

  const ShopByIdBottomSheet({super.key, required this.onBrowseShop});

  static void show({
    required BuildContext context,
    required ValueChanged<String> onBrowseShop,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShopByIdBottomSheet(onBrowseShop: onBrowseShop),
    );
  }

  @override
  State<ShopByIdBottomSheet> createState() => _ShopByIdBottomSheetState();
}

class _ShopByIdBottomSheetState extends State<ShopByIdBottomSheet> {
  final TextEditingController _shopIdController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _errorText;

  @override
  void dispose() {
    _shopIdController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pasteShopId() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty || !mounted) return;
    final id = parseShopIdInput(text);
    _shopIdController.text = id;
    _shopIdController.selection = TextSelection.collapsed(offset: id.length);
    setState(() => _errorText = null);
  }

  void _handleBrowseShop() {
    final shopId = parseShopIdInput(_shopIdController.text);
    if (shopId.isEmpty) {
      setState(() => _errorText = 'Please enter a Shop ID');
      _focusNode.requestFocus();
      return;
    }
    setState(() => _errorText = null);
    Navigator.pop(context);
    widget.onBrowseShop(shopId);
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
                        'Find a Shop',
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
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.store_rounded,
                    color: AppColors.textWhite,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter the Shop ID to browse products\nfrom a specific store.',
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
                    'Enter Shop ID',
                    style: AppTypography.label.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _shopIdController,
                  focusNode: _focusNode,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. SHP-2026-0042',
                    suffixIcon: IconButton(
                      tooltip: 'Paste',
                      onPressed: _pasteShopId,
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
                  onSubmitted: (_) => _handleBrowseShop(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: AppConstants.buttonHeight,
                  child: ElevatedButton(
                    onPressed: _handleBrowseShop,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusMD,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Browse Shop',
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
                  "You'll get this ID from the shop owner.",
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
