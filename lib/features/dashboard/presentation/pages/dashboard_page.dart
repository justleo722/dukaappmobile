import 'package:flutter/material.dart';
import 'package:dukaapp/features/dashboard/presentation/widgets/dashboard_appbar.dart';
import 'package:dukaapp/features/dashboard/presentation/widgets/summary_carousel.dart';
import 'package:dukaapp/features/dashboard/presentation/widgets/dashboard_grid.dart';
import 'package:dukaapp/features/dashboard/presentation/widgets/floating_action_bar.dart';
import 'package:dukaapp/features/navigation/presentation/widgets/app_drawer.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isRefreshing = false;

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: DashboardAppBar(onRefresh: _onRefresh, isRefreshing: _isRefreshing),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Expanded(
            child: _isRefreshing
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const SummaryCarousel(),
                        const SizedBox(height: 8),
                        const DashboardGrid(),
                        SizedBox(height: 100 + bottomPadding),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      bottomSheet: Container(
        color: const Color(0xFFF5F7FB),
        padding: EdgeInsets.only(
          bottom: bottomPadding + 12,
          top: 8,
        ),
        child: const FloatingActionBar(),
      ),
    );
  }
}
