import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/features/online_shop/presentation/widgets/online_shop_sidebar.dart';

class OnlineShopPaymentMethodsPage extends StatefulWidget {
  const OnlineShopPaymentMethodsPage({super.key});

  @override
  State<OnlineShopPaymentMethodsPage> createState() =>
      _OnlineShopPaymentMethodsPageState();
}

class _OnlineShopPaymentMethodsPageState
    extends State<OnlineShopPaymentMethodsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final String _activeSidebarItem = 'Payments';

  final List<Map<String, dynamic>> _methods = [
    {
      'accountName': 'DukaApp Business Account',
      'category': 'MPESA',
      'accountType': 'Revenue',
      'status': 'Active',
    },
    {
      'accountName': 'Cash on Delivery',
      'category': 'Cash on Delivery',
      'accountType': 'Revenue',
      'status': 'Active',
    },
    {
      'accountName': 'Tigo Pesa Wallet',
      'category': 'Mobile Payment',
      'accountType': 'Revenue',
      'status': 'Inactive',
    },
  ];

  void _onSidebarItemTap(String label) {
    Navigator.of(context).pop();
    final currentLocation = GoRouterState.of(context).matchedLocation;

    if (label == 'Dashboard') {
      if (currentLocation != '/online-shop') {
        context.go('/online-shop');
      }
    } else if (label == 'Products') {
      if (currentLocation != '/online-shop/manage-products') {
        context.go('/online-shop/manage-products');
      }
    } else if (label == 'Orders') {
      if (currentLocation != '/online-shop/manage-orders') {
        context.go('/online-shop/manage-orders');
      }
    } else if (label == 'Coupons') {
      if (currentLocation != '/online-shop/coupons') {
        context.go('/online-shop/coupons');
      }
    } else if (label == 'Categories') {
      if (currentLocation != '/online-shop/categories') {
        context.go('/online-shop/categories');
      }
    } else if (label == 'Delivery') {
      if (currentLocation != '/online-shop/delivery') {
        context.go('/online-shop/delivery');
      }
    } else if (label == 'Reports') {
      if (currentLocation != '/online-shop/reports') {
        context.go('/online-shop/reports');
      }
    } else if (label == 'Settings') {
      if (currentLocation != '/online-shop/settings') {
        context.go('/online-shop/settings');
      }
    }
  }

  void _showDeleteDialog(int index) {
    final method = _methods[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Payment Method',
          style: AppTypography.h6.copyWith(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete "${method['accountName']}"?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _methods.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Payment method "${method['accountName']}" deleted',
                  ),
                  backgroundColor: AppColors.danger,
                ),
              );
            },
            child: Text(
              'Delete',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMethodDialog({Map<String, dynamic>? existingMethod}) {
    final isEditing = existingMethod != null;
    final categoryController = TextEditingController(
      text: existingMethod?['category']?.toString() ?? '',
    );
    final accountNameController = TextEditingController(
      text: existingMethod?['accountName']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        ),
        title: Text(
          isEditing ? 'Edit Payment Method' : 'Add Payment Method',
          style: AppTypography.h6.copyWith(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category Name',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: categoryController,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Enter category name',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSM),
                    borderSide: BorderSide(
                      color: AppColors.textHint.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSM),
                    borderSide: BorderSide(
                      color: AppColors.textHint.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSM),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Account Name',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: accountNameController,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Enter account name',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSM),
                    borderSide: BorderSide(
                      color: AppColors.textHint.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSM),
                    borderSide: BorderSide(
                      color: AppColors.textHint.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSM),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.textHint),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusSM),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final category = categoryController.text.trim();
                      final accountName = accountNameController.text.trim();
                      if (category.isEmpty || accountName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Please fill in all fields'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                        return;
                      }
                      setState(() {
                        if (isEditing) {
                          final index = _methods.indexWhere(
                            (m) =>
                                m['accountName'] ==
                                existingMethod['accountName'],
                          );
                          if (index != -1) {
                            _methods[index] = {
                              ..._methods[index],
                              'category': category,
                              'accountName': accountName,
                            };
                          }
                        } else {
                          _methods.add({
                            'accountName': accountName,
                            'category': category,
                            'accountType': 'Revenue',
                            'status': 'Active',
                          });
                        }
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing
                                ? 'Payment method updated'
                                : 'Payment method added',
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusSM),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      isEditing ? 'Update Method' : 'Save Method',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
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

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(context),
      drawer: OnlineShopSidebar(
        activeItem: _activeSidebarItem,
        onItemTap: _onSidebarItemTap,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildAddMethodButton(),
                  const SizedBox(height: 16),
                  _buildMethodsList(),
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
            onPressed: () => context.go('/online-shop'),
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
        'Payment Methods',
        style: AppTypography.h6.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 1.5),
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            ),
            child: IconButton(
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
              icon: const Icon(
                Icons.menu_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.divider),
      ),
    );
  }

  Widget _buildAddMethodButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
      child: SizedBox(
        width: double.infinity,
        height: AppConstants.buttonHeight,
        child: ElevatedButton(
          onPressed: () => _showAddMethodDialog(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, size: 20),
              const SizedBox(width: 8),
              Text(
                'Add Method',
                style: AppTypography.buttonLarge.copyWith(
                  color: AppColors.textWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodsList() {
    if (_methods.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
      child: Column(
        children: List.generate(_methods.length, (index) {
          final method = _methods[index];
          return _PaymentMethodCard(
            method: method,
            onEdit: () => _showAddMethodDialog(existingMethod: method),
            onDelete: () => _showDeleteDialog(index),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
      padding: const EdgeInsets.all(AppConstants.paddingXXL),
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
        children: [
          Icon(
            Icons.payments_rounded,
            size: 48,
            color: AppColors.textHint.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'No payment methods found',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add your first payment method to get started',
            style: AppTypography.caption.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final Map<String, dynamic> method;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PaymentMethodCard({
    required this.method,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = method['status'] as String;
    final statusColor =
        status == 'Active' ? AppColors.success : AppColors.textHint;
    final category = method['category'] as String;
    final accountType = method['accountType'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                ),
                child: const Icon(
                  Icons.payments_rounded,
                  size: 20,
                  color: Color(0xFF14B8A6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method['accountName'] as String,
                      style: AppTypography.h6.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category,
                      style: AppTypography.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                ),
                child: Text(
                  status,
                  style: AppTypography.labelSmall.copyWith(
                    color: statusColor,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoColumn('Category', category),
              const SizedBox(width: 16),
              _buildInfoColumn('Account Type', accountType),
              const Spacer(),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                  ),
                  child: const Icon(
                    Icons.delete_rounded,
                    size: 18,
                    color: AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
