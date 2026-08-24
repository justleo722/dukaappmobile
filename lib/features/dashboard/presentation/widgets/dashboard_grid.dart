import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/features/dashboard/presentation/constants/dashboard_constants.dart';
import 'package:dukaapp/features/dashboard/presentation/widgets/dashboard_module_card.dart';

class DashboardGrid extends StatelessWidget {
  const DashboardGrid({super.key});

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
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final modules = DashboardConstants.moduleCards;
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
