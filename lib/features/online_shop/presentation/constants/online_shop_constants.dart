import 'package:flutter/material.dart';

class OnlineShopConstants {
  OnlineShopConstants._();

  // Sidebar menu items
  static const List<Map<String, dynamic>> sidebarMenuItems = [
    {'icon': Icons.dashboard_rounded, 'label': 'Dashboard'},
    {'icon': Icons.inventory_2_rounded, 'label': 'Products'},
    {'icon': Icons.shopping_bag_rounded, 'label': 'Orders'},
    {'icon': Icons.local_offer_rounded, 'label': 'Coupons'},
    {'icon': Icons.category_rounded, 'label': 'Categories'},
    {'icon': Icons.delivery_dining_rounded, 'label': 'Delivery'},
    {'icon': Icons.payments_rounded, 'label': 'Payments'},
    {'icon': Icons.assessment_rounded, 'label': 'Reports'},
    {'icon': Icons.settings_rounded, 'label': 'Settings'},
  ];

  // Summary cards data
  static const List<Map<String, dynamic>> summaryCards = [
    {
      'title': 'Online Shop Revenue',
      'value': 'Tsh 0',
      'icon': Icons.attach_money_rounded,
      'color': Color(0xFF22C55E),
      'bgColor': Color(0xFFE8FAF0),
    },
    {
      'title': 'Online Shop Products',
      'value': '0',
      'icon': Icons.inventory_2_rounded,
      'color': Color(0xFF14B8A6),
      'bgColor': Color(0xFFE0FFF9),
    },
    {
      'title': 'Online Orders',
      'value': '0',
      'icon': Icons.shopping_bag_rounded,
      'color': Color(0xFFFF7A00),
      'bgColor': Color(0xFFFFF0E0),
    },
    {
      'title': 'Online Customers',
      'value': '0',
      'icon': Icons.people_rounded,
      'color': Color(0xFF9333EA),
      'bgColor': Color(0xFFF3E8FF),
    },
  ];

  // Mock recent orders
  static const List<Map<String, dynamic>> recentOrders = [
    {
      'orderId': 'ORD-1001',
      'customer': 'Juma Juma',
      'amount': 'Tsh 132,000',
      'status': 'Delivered',
    },
    {
      'orderId': 'ORD-1002',
      'customer': 'Amina Hassan',
      'amount': 'Tsh 36,000',
      'status': 'Delivering',
    },
    {
      'orderId': 'ORD-1003',
      'customer': 'Hassan Ali',
      'amount': 'Tsh 48,000',
      'status': 'Received',
    },
    {
      'orderId': 'ORD-1004',
      'customer': 'Fatima Osman',
      'amount': 'Tsh 25,000',
      'status': 'Pending',
    },
    {
      'orderId': 'ORD-1005',
      'customer': 'Salum Bakari',
      'amount': 'Tsh 85,000',
      'status': 'Delivered',
    },
  ];

  // Mock top products
  static const List<Map<String, dynamic>> topProducts = [
    {
      'product': 'Beauty Cream',
      'price': 'Tsh 18,000',
      'sales': 48,
      'stock': 'In Stock',
    },
    {
      'product': 'Face Mask',
      'price': 'Tsh 9,000',
      'sales': 35,
      'stock': 'In Stock',
    },
    {
      'product': 'Air Freshener',
      'price': 'Tsh 7,000',
      'sales': 22,
      'stock': 'Low Stock',
    },
    {
      'product': 'Dish Soap',
      'price': 'Tsh 3,500',
      'sales': 60,
      'stock': 'In Stock',
    },
    {
      'product': 'Charger Cable',
      'price': 'Tsh 6,000',
      'sales': 18,
      'stock': 'Low Stock',
    },
  ];
}
