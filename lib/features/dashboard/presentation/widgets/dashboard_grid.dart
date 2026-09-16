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

  void _handleModuleTap(BuildContext context, String title) {
    switch (title) {
      case 'Add Product':
        context.push('/stock/manage');
        break;
      case 'Add Sale':
        context.push('/sales/manage');
        break;
      case 'Purchase':
        context.push('/sales/purchases');
        break;
      case 'Profit & Expenses':
        context.push('/profit-expenses');
        break;
      case 'Accounts & Cashflow':
        context.push('/accounts-cashflow');
        break;
      case 'Staff':
        context.push('/staff');
        break;
      case 'Manufacturing':
        context.push('/manufacturing');
        break;
      case 'Online Shop':
        context.push('/online-shop');
        break;
      case 'Shop Settings':
        context.push('/shop-settings');
        break;
      case 'Renew':
        context.push('/renew');
        break;
      case 'TMS Loans':
        context.push('/tms');
        break;
      default:
        break;
    }
  }

  /// Returns only the modules the current user is allowed to see,
  /// also respecting shop feature flags from [ShopConfig].
  List<Map<String, dynamic>> _visibleModules(ShopConfig cfg) {
    final u = sessionUser;
    final all = DashboardConstants.moduleCards;
    return all.where((module) {
      switch (module['title']) {
        case 'Add Product':
          return u.canSeeStock;
        case 'Add Sale':
          return u.canSeeSales;
        case 'Purchase':
          return u.canSeePurchases;
        case 'Profit & Expenses':
          return u.canSeeProfitExpenses;
        case 'Accounts & Cashflow':
          return u.canSeeCashflow;
        case 'Staff':
          return u.canSeeStaff;
        case 'Manufacturing':
          return u.canSeeManufacturing && cfg.enableManufacturing;
        case 'Online Shop':
          return u.canSeeOnlineShop && cfg.enableOnlineStore;
        case 'Shop Settings':
          return u.canSeeSettings;
        case 'Renew':
          return u.isOwner;
        case 'TMS Loans':
        case 'Microfinance':
          return (u.isOwner || u.isManager) && cfg.enableTms;
        default:
          return u.isOwner;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(shopConfigProvider).valueOrNull ?? ShopConfig.defaults;
    final modules = _visibleModules(cfg);
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
          onTap: () => _handleModuleTap(context, module['title']),
        );
      },
    );
  }
}
