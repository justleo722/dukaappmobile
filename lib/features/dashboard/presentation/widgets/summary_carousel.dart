import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dukaapp/features/dashboard/presentation/constants/dashboard_constants.dart';
import 'package:dukaapp/features/dashboard/presentation/widgets/summary_card.dart';

class SummaryCarousel extends StatefulWidget {
  const SummaryCarousel({super.key});

  @override
  State<SummaryCarousel> createState() => _SummaryCarouselState();
}

class _SummaryCarouselState extends State<SummaryCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  late final List<Map<String, dynamic>> _cards;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _cards = DashboardConstants.summaryCards;
    _pageController = PageController(viewportFraction: 0.48, initialPage: 0);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % _cards.length;
      _pageController.animateToPage(
        nextPage,
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
        itemCount: _cards.length,
        onPageChanged: (index) => _currentPage = index,
        itemBuilder: (context, index) {
          final card = _cards[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: SummaryCard(
              title: card['title'],
              value: card['value'],
              description: card['description'],
              icon: card['icon'],
              color: card['color'],
              bgColor: card['bgColor'],
            ),
          );
        },
      ),
    );
  }
}
