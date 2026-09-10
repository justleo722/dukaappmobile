import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/features/dashboard/presentation/widgets/dashboard_appbar.dart';
import 'package:dukaapp/features/dashboard/presentation/widgets/summary_carousel.dart';
import 'package:dukaapp/features/dashboard/presentation/widgets/dashboard_grid.dart';
import 'package:dukaapp/features/dashboard/presentation/widgets/floating_action_bar.dart';
import 'package:dukaapp/features/navigation/presentation/widgets/app_drawer.dart';
import 'package:dukaapp/features/dashboard/presentation/providers/dashboard_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    Future<void> onRefresh() async {
      await ref.read(dashboardProvider.notifier).refresh();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: DashboardAppBar(
        onRefresh: onRefresh,
        isRefreshing: dashboardAsync.isLoading,
      ),
      drawer: AppDrawer(onRefresh: onRefresh),
      body: Column(
        children: [
          Expanded(
            child: dashboardAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorView(error: error, onRetry: onRefresh),
              data: (state) => RefreshIndicator(
                onRefresh: onRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      SummaryCarousel(
                        dashboard: state.dashboard,
                        sessionUser: state.sessionUser,
                      ),
                      const SizedBox(height: 8),
                      DashboardGrid(sessionUser: state.sessionUser),
                      SizedBox(height: 100 + bottomPadding),
                    ],
                  ),
                ),
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Imeshindwa kupakia data',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Jaribu tena'),
            ),
          ],
        ),
      ),
    );
  }
}
