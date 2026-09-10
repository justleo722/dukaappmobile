import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/features/dashboard/presentation/constants/dashboard_constants.dart';
import 'package:dukaapp/features/dashboard/presentation/widgets/summary_card.dart';

class SummaryCarousel extends StatefulWidget {
  const SummaryCarousel({super.key});

  @override
  State<SummaryCarousel> createState() => _SummaryCarouselState();
}

class _SummaryCarouselState extends State<SummaryCarousel> {
  late final PageController _pageController;
  late final List<Map<String, dynamic>> _cards;
  Timer? _autoScrollTimer;

  static const int _infiniteMultiplier = 10000;

  @override
  void initState() {
    super.initState();
    _cards = DashboardConstants.summaryCards;
    final initialPage = (_cards.length * (_infiniteMultiplier ~/ 2));
    _pageController = PageController(viewportFraction: 0.48, initialPage: initialPage);
    _startAutoScroll();
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
