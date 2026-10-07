import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/core/models/shop_config.dart';
import 'package:dukaapp/core/providers.dart';
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
    final cfg = ref.watch(shopConfigProvider).valueOrNull ?? ShopConfig.defaults;
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
              data: (state) {
                // Only enforce on fresh API data — never on cached data.
                final isExpired = !state.fromCache && !state.sessionUser.isActive;

                final dashboardContent = RefreshIndicator(
                  onRefresh: onRefresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        if (cfg.enableHomepageLiveSummary)
                          SummaryCarousel(
                            dashboard: state.dashboard,
                            sessionUser: state.sessionUser,
                          ),
                        if (cfg.enableHomepageLiveSummary) const SizedBox(height: 8),
                        DashboardGrid(sessionUser: state.sessionUser),
                        SizedBox(height: 100 + bottomPadding),
                      ],
                    ),
                  ),
                );

                if (!isExpired) return dashboardContent;

                // Expired: show dashboard faint + renewal overlay
                return Stack(
                  children: [
                    // Faint, non-interactive dashboard behind overlay
                    IgnorePointer(
                      child: Opacity(
                        opacity: 0.25,
                        child: dashboardContent,
                      ),
                    ),
                    // Renewal overlay
                    _SubscriptionExpiredView(
                      remainingDays: state.sessionUser.remainingDays,
                      onRefresh: onRefresh,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomSheet: cfg.enableQuickActions ? Container(
        color: const Color(0xFFF5F7FB),
        padding: EdgeInsets.only(
          bottom: bottomPadding + 12,
          top: 8,
        ),
        child: const FloatingActionBar(),
      ) : null,
    );
  }
}

class _SubscriptionExpiredView extends StatelessWidget {
  const _SubscriptionExpiredView({required this.remainingDays, required this.onRefresh});

  final int remainingDays;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_rounded, size: 48, color: AppColors.danger),
              ),
              const SizedBox(height: 16),
              Text(
                'Usajili Umekwisha',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Usajili wa duka lako umekwisha.\nFanya malipo ili kuendelea kutumia mfumo.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.push('/renew'),
                icon: const Icon(Icons.payment_rounded),
                label: const Text('Fanya Malipo'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Angalia Tena'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
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
