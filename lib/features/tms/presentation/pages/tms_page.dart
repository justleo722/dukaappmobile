import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/features/tms/data/models/tms_models.dart';

class TmsPage extends ConsumerStatefulWidget {
  const TmsPage({super.key});

  @override
  ConsumerState<TmsPage> createState() => _TmsPageState();
}

class _TmsPageState extends ConsumerState<TmsPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isLoading = true;
  bool _isApplying = false;
  List<TmsApplication> _applications = [];
  String? _applyError;
  String? _applySuccess;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getStock();
      final raw = res.data;
      List<dynamic> list = [];
      if (raw is List) {
        list = raw;
      } else if (raw is Map<String, dynamic>) {
        final d = raw['data'];
        if (d is List) list = d;
      }
      final apps = list.whereType<Map<String, dynamic>>().map(TmsApplication.fromJson).toList();
      if (mounted) setState(() { _applications = apps; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _applyForLoan() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Apply for TMS Loan', style: AppTypography.h6.copyWith(fontWeight: FontWeight.w700)),
        content: Text(
          'This will analyse your business data (sales, cashflow, stock) and submit a loan eligibility application. Continue?',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: Text('Apply', style: AppTypography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() { _isApplying = true; _applyError = null; _applySuccess = null; });
    try {
      final api = ref.read(apiServiceProvider);
      final Map<String, dynamic> res = {};
      if (!mounted) return;
      final status = res['status']?.toString() ?? '';
      if (status == 'success' || status == '1' || res['application_id'] != null) {
        _applySuccess = res['message']?.toString() ?? 'Application submitted successfully!';
        await _loadData();
      } else {
        _applyError = res['message']?.toString() ?? 'Application failed. Try again later.';
      }
      setState(() {});
    } catch (e) {
      if (mounted) setState(() => _applyError = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.card, elevation: 0,
        leading: Padding(padding: const EdgeInsets.all(8.0), child: Container(
          decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
          child: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20)),
        )),
        leadingWidth: 56,
        title: Text('TMS Loans', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary)),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(children: [
            Container(height: 1, color: AppColors.divider),
            TabBar(
              controller: _tabController,
              labelStyle: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
              unselectedLabelStyle: AppTypography.bodySmall,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [Tab(text: 'Applications'), Tab(text: 'Loan Insights'), Tab(text: 'About')],
            ),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isApplying ? null : _applyForLoan,
        backgroundColor: AppColors.primary,
        icon: _isApplying
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(_isApplying ? 'Applying…' : 'New Application', style: AppTypography.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(controller: _tabController, children: [
            _buildApplicationsTab(),
            _buildInsightsTab(),
            _buildAboutTab(),
          ]),
    );
  }

  Widget _buildApplicationsTab() {
    return Column(children: [
      if (_applySuccess != null) _banner(AppColors.success, Icons.check_circle_rounded, _applySuccess!),
      if (_applyError   != null) _banner(AppColors.danger, Icons.error_rounded, _applyError!),
      Expanded(child: _applications.isEmpty
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.description_outlined, size: 56, color: AppColors.textHint.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('No applications yet', style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint)),
            const SizedBox(height: 6),
            Text('Tap "New Application" to apply.', style: AppTypography.bodySmall.copyWith(color: AppColors.textHint)),
          ]))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _applications.length,
            itemBuilder: (ctx, i) => _buildAppCard(_applications[i]),
          )),
    ]);
  }

  Widget _banner(Color color, IconData icon, String text) => Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.2))),
    child: Row(children: [
      Icon(icon, color: color, size: 18), const SizedBox(width: 8),
      Expanded(child: Text(text, style: AppTypography.bodySmall.copyWith(color: color))),
    ]),
  );

  Widget _buildAppCard(TmsApplication app) {
    final eligible = app.loanEligibility;
    final statusColor = eligible ? AppColors.success : AppColors.warning;
    final fmt = (double v) => 'TZS ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(app.businessName ?? 'Loan Application', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
            if (app.dateCreated != null)
              Text(app.dateCreated!, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
            child: Text(eligible ? 'Eligible' : 'Not Eligible', style: AppTypography.caption.copyWith(color: statusColor, fontWeight: FontWeight.w700, fontSize: 11)),
          ),
        ]),
        const Divider(height: 20),
        _row('Requested', fmt(app.requestedLoanAmount)),
        _row('Recommended', fmt(app.recommendedLoanAmount), bold: true, color: AppColors.primary),
        _row('Max Limit', fmt(app.maxLoanLimit)),
        _row('Score', '${app.loanScore.toStringAsFixed(1)} / 100'),
        if (app.eligibilityStatus.isNotEmpty) _row('Status', app.eligibilityStatus),
      ]),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Text('$label:', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
      const Spacer(),
      Text(value, style: AppTypography.bodySmall.copyWith(
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        color: color ?? AppColors.textPrimary)),
    ]),
  );

  Widget _buildInsightsTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Loan Portfolio Insights', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Aggregate reports for approved loans, disbursements, and repayments will appear here once available.',
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
      const SizedBox(height: 20),
      ...[
        (Icons.trending_up_rounded, AppColors.primary, 'Monitor eligibility trends and approval rates.'),
        (Icons.gps_fixed_rounded, AppColors.success, 'Track repayment performance and outstanding balances.'),
        (Icons.show_chart_rounded, AppColors.warning, 'Evaluate loan limits against business performance.'),
      ].map((item) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
        Icon(item.$1, color: item.$2, size: 18), const SizedBox(width: 10),
        Expanded(child: Text(item.$3, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary))),
      ]))),
    ]),
  );

  Widget _buildAboutTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('About TMS', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('TMS (Traders Microfinance Suite) analyses your sales, stock movement and repayment history to determine loan eligibility and recommended credit limits.',
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5)),
      const SizedBox(height: 20),
      ...[
        (Icons.speed_rounded, AppColors.primary, 'Eligibility Score', 'Data-driven scoring combines sales velocity, repayment behaviour and stock turnover.'),
        (Icons.layers_rounded, AppColors.success, 'Loan Offers', 'Eligible businesses receive dynamic loan offers tailored to their current performance.'),
        (Icons.sync_rounded, AppColors.warning, 'Continuous Updates', 'Your score improves as your business performs better over time.'),
      ].map((item) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: item.$2.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(item.$1, color: item.$2, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.$3, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(item.$4, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          ])),
        ]))),
    ]),
  );
}
