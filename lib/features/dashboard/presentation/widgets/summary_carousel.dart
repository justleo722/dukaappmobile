import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/features/dashboard/data/models/dashboard_model.dart';
import 'package:dukaapp/features/dashboard/data/models/session_user_model.dart';
import 'package:dukaapp/features/dashboard/presentation/constants/dashboard_constants.dart';
import 'package:dukaapp/features/dashboard/presentation/widgets/summary_card.dart';

class SummaryCarousel extends StatefulWidget {
  const SummaryCarousel({
    super.key,
    required this.dashboard,
    required this.sessionUser,
  });

  final DashboardModel dashboard;
  final SessionUserModel sessionUser;

  @override
  State<SummaryCarousel> createState() => _SummaryCarouselState();
}

class _SummaryCarouselState extends State<SummaryCarousel> {
  late final PageController _pageController;
  late List<Map<String, dynamic>> _cards;
  Timer? _autoScrollTimer;

  static const int _infiniteMultiplier = 10000;

  @override
  void initState() {
    super.initState();
    _cards = _buildCards();
    final initialPage = (_cards.length * (_infiniteMultiplier ~/ 2));
    _pageController = PageController(viewportFraction: 0.48, initialPage: initialPage);
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(SummaryCarousel old) {
    super.didUpdateWidget(old);
    if (old.dashboard != widget.dashboard || old.sessionUser != widget.sessionUser) {
      setState(() => _cards = _buildCards());
    }
  }

  /// Build summary card list from real API data.
  /// Only include cards relevant to the user's permissions.
  List<Map<String, dynamic>> _buildCards() {
    final d = widget.dashboard;
    final u = widget.sessionUser;
    final cur = d.currency;

    String money(double v) =>
        '$cur ${v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}K' : v.toStringAsFixed(0)}';
    String qty(double v) => '${v.toStringAsFixed(0)} Items';
    String orders(double v) => '${v.toStringAsFixed(0)} Orders';

    final cards = <Map<String, dynamic>>[];

    if (u.canSeeSales) {
      cards.add({
        'title': 'Today Sales',
        'value': money(d.todaySales),
        'description': d.todaySales > 0 ? 'This month: ${money(d.thisMonthSales)}' : 'No sales today',
        'icon': Icons.point_of_sale_rounded,
        'color': const Color(0xFF2563EB),
        'bgColor': const Color(0xFFEBF2FF),
        'route': '/sales/manage',
      });
    }

    if (u.canSeeProfitExpenses) {
      if (u.can('can_view_profit')) {
        cards.add({
          'title': 'Today Profit',
          'value': money(d.todayProfit),
          'description': d.todayProfit > 0 ? 'This month: ${money(d.thisMonthProfit)}' : 'No profit recorded',
          'icon': Icons.trending_up_rounded,
          'color': const Color(0xFF22C55E),
          'bgColor': const Color(0xFFE8FAF0),
          'route': '/profit-expenses',
        });
      }
      if (u.can('can_add_expense') || u.isOwner) {
        cards.add({
          'title': 'Today Expense',
          'value': money(d.todayExpense),
          'description': d.todayExpense > 0 ? 'This month: ${money(d.thisMonthExpense)}' : 'No expenses today',
          'icon': Icons.receipt_long_rounded,
          'color': const Color(0xFFEF4444),
          'bgColor': const Color(0xFFFEE8E8),
          'route': '/profit-expenses',
        });
      }
    }

    if (u.canSeeStock) {
      cards.add({
        'title': 'Today Stock In',
        'value': qty(d.todayStockin),
        'description': d.todayStockin > 0 ? 'This month: ${qty(d.thisMonthStockin)}' : 'No stock added',
        'icon': Icons.inventory_2_rounded,
        'color': const Color(0xFFFF7A00),
        'bgColor': const Color(0xFFFFF0E0),
        'route': '/stock/manage',
      });
    }

    if (u.canSeePurchases) {
      cards.add({
        'title': 'To Receive',
        'value': money(d.todayCredit),
        'description': d.todayCredit > 0 ? 'Pending deliveries' : 'No pending receives',
        'icon': Icons.download_rounded,
        'color': const Color(0xFF9333EA),
        'bgColor': const Color(0xFFF3E8FF),
        'route': '/purchases/orders',
      });
      cards.add({
        'title': 'To Pay',
        'value': money(d.todayTopay),
        'description': d.todayTopay > 0 ? 'Pending payments' : 'No pending payments',
        'icon': Icons.upload_rounded,
        'color': const Color(0xFFF59E0B),
        'bgColor': const Color(0xFFFFF8E1),
        'route': '/purchases/orders',
      });
    }

    if (u.canSeeSales) {
      cards.add({
        'title': 'Today Orders',
        'value': orders(d.todayOrders),
        'description': d.todayOrders > 0 ? 'Active orders today' : 'No orders today',
        'icon': Icons.shopping_bag_rounded,
        'color': const Color(0xFF3B82F6),
        'bgColor': const Color(0xFFEBF5FF),
        'route': '/sales/orders',
      });
    }

    // Fallback: show at least one card if user has no matching permissions.
    if (cards.isEmpty) {
      cards.addAll(DashboardConstants.summaryCards);
    }

    return cards;
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final currentPage = _pageController.page?.round() ?? 0;
      _pageController.animateToPage(
        currentPage + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: DashboardConstants.summaryCardHeight + 20,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _cards.length * _infiniteMultiplier,
        itemBuilder: (context, index) {
          final card = _cards[index % _cards.length];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: SummaryCard(
              title: card['title'],
              value: card['value'],
              description: card['description'],
              icon: card['icon'],
              color: card['color'],
              bgColor: card['bgColor'],
              onTap: () {
                final route = card['route'] as String?;
                if (route != null && context.mounted) {
                  context.push(route);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
