import 'package:flutter/material.dart';

class DashboardConstants {
  DashboardConstants._();

  // Summary Card Dimensions
  static const double summaryCardWidth = 170.0;
  static const double summaryCardHeight = 120.0;
  static const double summaryCardSpacing = 12.0;

  // Icon Containers
  static const double moduleIconSize = 44.0;
  static const double summaryIconSize = 36.0;
  static const double moduleIconRadius = 12.0;
  static const double summaryIconRadius = 10.0;

  // Floating Action Bar
  static const double fabHeight = 60.0;
  static const double fabRadius = 30.0;
  static const double fabButtonWidth = 100.0;
  static const double fabBottomPadding = 20.0;

  // Grid
  static const double gridSpacing = 14.0;
  static const double gridAspectRatio = 1.1;

  // Shadows
  static final BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.06),
    blurRadius: 12,
    offset: const Offset(0, 4),
  );

  static final BoxShadow fabShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.12),
    blurRadius: 20,
    offset: const Offset(0, 6),
  );

  // Summary Cards Data
  static const List<Map<String, dynamic>> summaryCards = [
    {
      'title': 'Today Sales',
      'value': 'Tsh 0',
      'description': 'No sales today',
      'icon': Icons.point_of_sale_rounded,
      'color': Color(0xFF2563EB),
      'bgColor': Color(0xFFEBF2FF),
    },
    {
      'title': 'Today Profit',
      'value': 'Tsh 0',
      'description': 'No profit recorded',
      'icon': Icons.trending_up_rounded,
      'color': Color(0xFF22C55E),
      'bgColor': Color(0xFFE8FAF0),
    },
    {
      'title': 'Today Expense',
      'value': 'Tsh 0',
      'description': 'No expenses today',
      'icon': Icons.receipt_long_rounded,
      'color': Color(0xFFEF4444),
      'bgColor': Color(0xFFFEE8E8),
    },
    {
      'title': 'Today Stock In',
      'value': '0 Items',
      'description': 'No stock added',
      'icon': Icons.inventory_2_rounded,
      'color': Color(0xFFFF7A00),
      'bgColor': Color(0xFFFFF0E0),
    },
    {
      'title': 'To Receive',
      'value': '0 Orders',
      'description': 'No pending receives',
      'icon': Icons.download_rounded,
      'color': Color(0xFF9333EA),
      'bgColor': Color(0xFFF3E8FF),
    },
    {
      'title': 'To Pay',
      'value': 'Tsh 0',
      'description': 'No pending payments',
      'icon': Icons.upload_rounded,
      'color': Color(0xFFF59E0B),
      'bgColor': Color(0xFFFFF8E1),
    },
    {
      'title': 'Today Orders',
      'value': '0 Orders',
      'description': 'No orders today',
      'icon': Icons.shopping_bag_rounded,
      'color': Color(0xFF3B82F6),
      'bgColor': Color(0xFFEBF5FF),
    },
  ];

  // Module Cards Data
  static const List<Map<String, dynamic>> moduleCards = [
    {
      'title': 'Add Product',
      'description': 'Manage products and inventory.',
      'icon': Icons.inventory_2_rounded,
      'color': Color(0xFF2563EB),
      'bgColor': Color(0xFFEBF2FF),
    },
    {
      'title': 'Add Sale',
      'description': 'Create new sales and invoices.',
      'icon': Icons.point_of_sale_rounded,
      'color': Color(0xFF22C55E),
      'bgColor': Color(0xFFE8FAF0),
    },
    {
      'title': 'Purchase',
      'description': 'Manage purchases and stock.',
      'icon': Icons.shopping_cart_rounded,
      'color': Color(0xFFFF7A00),
      'bgColor': Color(0xFFFFF0E0),
    },
    {
      'title': 'Profit & Expenses',
      'description': 'View profit and expenses.',
      'icon': Icons.trending_up_rounded,
      'color': Color(0xFF9333EA),
      'bgColor': Color(0xFFF3E8FF),
    },
    {
      'title': 'Accounts & Cashflow',
      'description': 'Manage cash movement.',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Color(0xFF0EA5E9),
      'bgColor': Color(0xFFE0F7FF),
    },
    {
      'title': 'Staff',
      'description': 'Manage users and permissions.',
      'icon': Icons.people_rounded,
      'color': Color(0xFFEC4899),
      'bgColor': Color(0xFFFCE8F3),
    },
    {
      'title': 'Manufacturing',
      'description': 'Manage recipes and production.',
      'icon': Icons.factory_rounded,
      'color': Color(0xFF6366F1),
      'bgColor': Color(0xFFEEF2FF),
    },
    {
      'title': 'Online Shop',
      'description': 'Manage online products.',
      'icon': Icons.storefront_rounded,
      'color': Color(0xFF14B8A6),
      'bgColor': Color(0xFFE0FFF9),
    },
    {
      'title': 'TMS Loans',
      'description': 'Loan eligibility services.',
      'icon': Icons.request_quote_rounded,
      'color': Color(0xFFF97316),
      'bgColor': Color(0xFFFFF4E6),
    },
    {
      'title': 'Microfinance',
      'description': 'Loan and repayment management.',
      'icon': Icons.payments_rounded,
      'color': Color(0xFF8B5CF6),
      'bgColor': Color(0xFFF1EEFF),
    },
    {
      'title': 'Shop Settings',
      'description': 'Configure your business.',
      'icon': Icons.settings_rounded,
      'color': Color(0xFF64748B),
      'bgColor': Color(0xFFF1F5F9),
    },
    {
      'title': 'Renew',
      'description': 'Renew your subscription.',
      'icon': Icons.workspace_premium_rounded,
      'color': Color(0xFFD97706),
      'bgColor': Color(0xFFFFF8E1),
    },
  ];
}
