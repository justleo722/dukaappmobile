import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/core/models/shop_config.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/features/dashboard/data/models/session_user_model.dart';
import 'package:dukaapp/features/dashboard/presentation/constants/dashboard_constants.dart';
import 'package:dukaapp/features/dashboard/presentation/widgets/dashboard_module_card.dart';

class DashboardGrid extends ConsumerWidget {
  const DashboardGrid({super.key, required this.sessionUser});

  final SessionUserModel sessionUser;

  void _handleModuleTap(BuildContext context, String key) {
    switch (key) {
      case 'add_product': context.push('/stock/manage'); break;
      case 'add_sale': context.push('/sales/manage'); break;
      case 'purchase': context.push('/sales/purchases'); break;
      case 'profit_expenses': context.push('/profit-expenses'); break;
      case 'accounts_cashflow': context.push('/accounts-cashflow'); break;
      case 'staff': context.push('/staff'); break;
      case 'manufacturing': context.push('/manufacturing'); break;
      case 'online_shop': context.push('/online-shop'); break;
      case 'shop_settings': context.push('/shop-settings'); break;
      case 'renew': context.push('/renew'); break;
    }
  }

  List<Map<String, dynamic>> _allModules(AppStrings s) => [
    {'key': 'add_product',      'title': s.addProductShortcut,       'description': 'Manage products and inventory.',      'icon': Icons.inventory_2_rounded,            'color': const Color(0xFF2563EB), 'bgColor': const Color(0xFFEBF2FF)},
    {'key': 'add_sale',         'title': s.addSaleShortcut,          'description': 'Create new sales and invoices.',      'icon': Icons.point_of_sale_rounded,          'color': const Color(0xFF22C55E), 'bgColor': const Color(0xFFE8FAF0)},
    {'key': 'purchase',         'title': s.purchase,                 'description': 'Manage purchases and stock.',         'icon': Icons.shopping_cart_rounded,          'color': const Color(0xFFFF7A00), 'bgColor': const Color(0xFFFFF0E0)},
    {'key': 'profit_expenses',  'title': s.profitAndExpenses,        'description': 'View profit and expenses.',           'icon': Icons.trending_up_rounded,            'color': const Color(0xFF9333EA), 'bgColor': const Color(0xFFF3E8FF)},
    {'key': 'accounts_cashflow','title': s.accountsAndCashflowShort, 'description': 'Manage cash movement.',               'icon': Icons.account_balance_wallet_rounded, 'color': const Color(0xFF0EA5E9), 'bgColor': const Color(0xFFE0F7FF)},
    {'key': 'staff',            'title': s.staff,                    'description': 'Manage users and permissions.',       'icon': Icons.people_rounded,                 'color': const Color(0xFFEC4899), 'bgColor': const Color(0xFFFCE8F3)},
    {'key': 'manufacturing',    'title': s.manufacturing,            'description': 'Manage recipes and production.',      'icon': Icons.factory_rounded,                'color': const Color(0xFF6366F1), 'bgColor': const Color(0xFFEEF2FF)},
    {'key': 'online_shop',      'title': s.onlineShopModule,         'description': 'Manage online products.',             'icon': Icons.storefront_rounded,             'color': const Color(0xFF14B8A6), 'bgColor': const Color(0xFFE0FFF9)},
    {'key': 'microfinance',     'title': s.microfinance,             'description': 'Loan and repayment management.',      'icon': Icons.payments_rounded,               'color': const Color(0xFF8B5CF6), 'bgColor': const Color(0xFFF1EEFF)},
    {'key': 'shop_settings',    'title': s.shopSettings,             'description': 'Configure your business.',           'icon': Icons.settings_rounded,               'color': const Color(0xFF64748B), 'bgColor': const Color(0xFFF1F5F9)},
    {'key': 'renew',            'title': s.renew,                    'description': 'Renew your subscription.',            'icon': Icons.workspace_premium_rounded,      'color': const Color(0xFFD97706), 'bgColor': const Color(0xFFFFF8E1)},
  ];

  List<Map<String, dynamic>> _visibleModules(ShopConfig cfg, List<Map<String, dynamic>> all) {
    final u = sessionUser;
    return all.where((m) {
      switch (m['key']) {
        case 'add_product':       return u.canSeeStock;
        case 'add_sale':          return u.canSeeSales;
        case 'purchase':          return u.canSeePurchases;
        case 'profit_expenses':   return u.canSeeProfitExpenses && cfg.enableFinancialReports;
        case 'accounts_cashflow': return u.canSeeCashflow;
        case 'staff':             return u.canSeeStaff;
        case 'manufacturing':     return u.canSeeManufacturing && cfg.enableManufacturing;
        case 'online_shop':       return u.canSeeOnlineShop && cfg.enableOnlineStore;
        case 'microfinance':      return u.isOwner;
        case 'shop_settings':     return u.canSeeSettings;
        case 'renew':             return u.isOwner;
        default:                  return u.isOwner;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(shopConfigProvider).valueOrNull ?? ShopConfig.defaults;
    final s = ref.watch(stringsProvider);
    final modules = _visibleModules(cfg, _allModules(s));
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: DashboardConstants.gridSpacing,
        vertical: 8,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 3 : 2,
        childAspectRatio: isTablet ? 1.2 : DashboardConstants.gridAspectRatio,
        crossAxisSpacing: DashboardConstants.gridSpacing,
        mainAxisSpacing: DashboardConstants.gridSpacing,
      ),
      itemCount: modules.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final module = modules[index];
        return DashboardModuleCard(
          title: module['title'],
          description: module['description'],
          icon: module['icon'],
          color: module['color'],
          bgColor: module['bgColor'],
          onTap: () => _handleModuleTap(context, module['key']),
        );
      },
    );
  }
}
