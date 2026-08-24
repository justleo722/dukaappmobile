import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/online_shop/presentation/widgets/track_order_bottom_sheet.dart';

class ShoppingCartPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  const ShoppingCartPage({super.key, required this.cartItems});

  @override
  State<ShoppingCartPage> createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends State<ShoppingCartPage> {
  late List<Map<String, dynamic>> _items;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _items = List<Map<String, dynamic>>.from(widget.cartItems);
  }

  String _formatPrice(int amount) {
    final str = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return 'TZS $buf';
  }

  int _parsePrice(String priceStr) {
    final cleaned = priceStr.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final currentQty = (_items[index]['qty'] as int?) ?? 1;
      final newQty = currentQty + delta;
      if (newQty <= 0) {
        _items.removeAt(index);
      } else {
        _items[index]['qty'] = newQty;
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _clearCart() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _items.clear();
              });
              Navigator.of(context).pop();
            },
            child: Text(
              'Clear',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  void _proceedToCheckout() {
    context.push('/checkout', extra: _items);
  }

  int get _totalItemCount => _items.fold(0, (sum, item) => sum + ((item['qty'] as int?) ?? 1));

  int get _totalCost => _items.fold(0, (sum, item) {
    final price = _parsePrice((item['price'] as String?) ?? '0');
    final qty = (item['qty'] as int?) ?? 1;
    return sum + (price * qty);
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          ),
        ),
        title: Text(
          'My Cart ($_totalItemCount)',
          style: AppTypography.h6,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/submark_logo.png',
                      width: 48,
                      height: 48,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DukaApp Shop', style: AppTypography.h6),
                          const SizedBox(height: 2),
                          Text(
                            'Quality products, trusted sellers',
                            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.divider),
              _DrawerItem(
                icon: Icons.home_outlined,
                label: 'Home',
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/');
                },
              ),
              _DrawerItem(
                icon: Icons.inventory_2_outlined,
                label: 'Products',
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/products');
                },
              ),
              _DrawerItem(
                icon: Icons.shopping_cart_outlined,
                label: 'My Cart',
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
              _DrawerItem(
                icon: Icons.local_shipping_outlined,
                label: 'Track Order',
                onTap: () {
                  Navigator.of(context).pop();
                  TrackOrderBottomSheet.show(
                    context: context,
                    onTrackOrder: (orderId) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Tracking order #$orderId...'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: _items.isEmpty ? _buildEmptyState() : _buildCartContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 120,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: AppTypography.h6.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Text(
            'Browse products and add items to your cart',
            style: AppTypography.caption.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            height: AppConstants.buttonHeight,
            child: ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                ),
              ),
              child: Text(
                'Start Shopping',
                style: AppTypography.buttonLarge.copyWith(color: AppColors.textWhite),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _items.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _items[index];
              final qty = (item['qty'] as int?) ?? 1;
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  border: Border.all(color: AppColors.border),
                ),
                child: Stack(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                          ),
                          child: Center(
                            child: item['icon'] != null
                                ? Icon(
                                    item['icon'] as IconData,
                                    size: 24,
                                    color: AppColors.primary,
                                  )
                                : const Text(
                                    '📦',
                                    style: TextStyle(fontSize: 24),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (item['name'] as String?) ?? 'Product',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                (item['seller'] as String?) ?? 'Seller',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (item['price'] as String?) ?? 'TZS 0',
                                style: AppTypography.captionBold.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _QuantityButton(
                                    icon: Icons.remove,
                                    onTap: () => _updateQuantity(index, -1),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      '$qty',
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  _QuantityButton(
                                    icon: Icons.add,
                                    onTap: () => _updateQuantity(index, 1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _removeItem(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        _buildCartSummary(),
      ],
    );
  }

  Widget _buildCartSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Items',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                Text(
                  '$_totalItemCount',
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Cost',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                Text(
                  _formatPrice(_totalCost),
                  style: AppTypography.h6.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: AppConstants.buttonHeight,
              child: ElevatedButton(
                onPressed: _proceedToCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  ),
                ),
                child: Text(
                  'Proceed to Checkout',
                  style: AppTypography.buttonLarge.copyWith(color: AppColors.textWhite),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: AppConstants.buttonHeight,
              child: OutlinedButton(
                onPressed: _clearCart,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  ),
                ),
                child: Text(
                  'Clear Cart',
                  style: AppTypography.buttonLarge.copyWith(color: AppColors.danger),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(label, style: AppTypography.bodyMedium),
      onTap: onTap,
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    );
  }
}
