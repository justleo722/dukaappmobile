import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';

class CustomFeaturesPage extends StatefulWidget {
  const CustomFeaturesPage({super.key});

  @override
  State<CustomFeaturesPage> createState() => _CustomFeaturesPageState();
}

class _CustomFeaturesPageState extends State<CustomFeaturesPage> {
  // Dashboard features
  bool _liveSummary = true;
  bool _cashInhand = true;
  bool _toPay = true;
  bool _toReceive = true;
  bool _todaySales = true;
  bool _todayStockIn = true;
  bool _todayProfit = true;
  bool _expenses = true;
  bool _orders = true;

  // Sales & Receipts features
  bool _enableVat = false;
  bool _enableEfdReceipt = false;
  bool _enableCustomReceipt = false;
  bool _enableReceiptPrinter = false;
  bool _showPrintedBy = false;
  bool _showServiceProvider = false;

  // Sales & Receipts fields
  final _vatRateController = TextEditingController(text: '18');
  final _traClientIdController = TextEditingController();
  final _traClientPasswordController = TextEditingController();
  String _vatPolicy = 'Inclusive';
  bool _isVerified = false;

  // Product features
  bool _showLogoOnReceipt = true;
  bool _useWholesalePrice = false;
  bool _sellByFifo = false;
  bool _autoCalcSellingPrice = true;
  bool _printOnSave = false;
  bool _addProductByImage = true;
  bool _enableBarcodeScanner = true;
  final _customerMessageController = TextEditingController();
  final _defaultDiscountController = TextEditingController(text: '0');

  // Module features
  bool _enableManufacturing = true;
  bool _enableTms = false;
  bool _enableMicrofinance = false;
  bool _enableOnlineShop = true;

  // Notification features
  bool _alertStock = true;
  bool _alertAttendantEdit = true;
  bool _alertAnySale = true;
  bool _dailySummary = true;
  bool _notifyOnlineVisit = true;
  bool _notifyNewOrders = true;
  String _dailySummaryTime = '5:00 PM';

  // Others features
  bool _defaultTodayFilter = true;
  bool _emailReceipts = true;
  bool _enableDashboardActions = true;
  bool _enableBarRestaurant = false;
  bool _enableFinancialReports = true;

  @override
  void dispose() {
    _vatRateController.dispose();
    _traClientIdController.dispose();
    _traClientPasswordController.dispose();
    _customerMessageController.dispose();
    _defaultDiscountController.dispose();
    super.dispose();
  }

  void _verifyTra() {
    if (_traClientIdController.text.isEmpty ||
        _traClientPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter TRA Client ID and Password'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    setState(() => _isVerified = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('TRA authentication verified successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _saveChanges() {
    final features = {
      'liveSummary': _liveSummary,
      'cashInhand': _cashInhand,
      'toPay': _toPay,
      'toReceive': _toReceive,
      'todaySales': _todaySales,
      'todayStockIn': _todayStockIn,
      'todayProfit': _todayProfit,
      'expenses': _expenses,
      'orders': _orders,
      'enableVat': _enableVat,
      'enableEfdReceipt': _enableEfdReceipt,
      'vatRate': _vatRateController.text,
      'vatPolicy': _vatPolicy,
      'traClientId': _traClientIdController.text,
      'enableCustomReceipt': _enableCustomReceipt,
      'enableReceiptPrinter': _enableReceiptPrinter,
      'showPrintedBy': _showPrintedBy,
      'showServiceProvider': _showServiceProvider,
      'showLogoOnReceipt': _showLogoOnReceipt,
      'customerMessage': _customerMessageController.text,
      'useWholesalePrice': _useWholesalePrice,
      'sellByFifo': _sellByFifo,
      'defaultDiscount': _defaultDiscountController.text,
      'autoCalcSellingPrice': _autoCalcSellingPrice,
      'printOnSave': _printOnSave,
      'addProductByImage': _addProductByImage,
      'enableBarcodeScanner': _enableBarcodeScanner,
      'enableManufacturing': _enableManufacturing,
      'enableTms': _enableTms,
      'enableMicrofinance': _enableMicrofinance,
      'enableOnlineShop': _enableOnlineShop,
      'alertStock': _alertStock,
      'alertAttendantEdit': _alertAttendantEdit,
      'alertAnySale': _alertAnySale,
      'dailySummary': _dailySummary,
      'dailySummaryTime': _dailySummaryTime,
      'notifyOnlineVisit': _notifyOnlineVisit,
      'notifyNewOrders': _notifyNewOrders,
      'defaultTodayFilter': _defaultTodayFilter,
      'emailReceipts': _emailReceipts,
      'enableDashboardActions': _enableDashboardActions,
      'enableBarRestaurant': _enableBarRestaurant,
      'enableFinancialReports': _enableFinancialReports,
    };
    debugPrint('Features saved: $features');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Custom features saved successfully'),
        backgroundColor: AppColors.success,
      ),
    );
    context.go('/shop-settings');
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 1.5),
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            ),
            child: IconButton(
              onPressed: () => context.go('/shop-settings'),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
        ),
        leadingWidth: 56,
        title: Text(
          'Custom Features',
          style: AppTypography.h6.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    icon: Icons.tune_rounded,
                    color: const Color(0xFF14B8A6),
                    title: 'Dashboard Features',
                    description: 'Toggle features on or off for your dashboard',
                  ),
                  const SizedBox(height: 12),
                  _buildDashboardToggles(),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    icon: Icons.receipt_long_rounded,
                    color: const Color(0xFF2563EB),
                    title: 'Sales & Receipts',
                    description: 'Configure VAT, TRA, and receipt settings',
                  ),
                  const SizedBox(height: 12),
                  _buildSalesReceiptsSection(),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    icon: Icons.inventory_2_rounded,
                    color: const Color(0xFFF59E0B),
                    title: 'Product',
                    description: 'Configure product and receipt settings',
                  ),
                  const SizedBox(height: 12),
                  _buildProductSection(),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    icon: Icons.apps_rounded,
                    color: const Color(0xFF9333EA),
                    title: 'Module',
                    description: 'Enable or disable business modules',
                  ),
                  const SizedBox(height: 12),
                  _buildModuleSection(),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    icon: Icons.notifications_rounded,
                    color: const Color(0xFFEF4444),
                    title: 'Notification',
                    description: 'Configure alerts and notification settings',
                  ),
                  const SizedBox(height: 12),
                  _buildNotificationSection(),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    icon: Icons.more_horiz_rounded,
                    color: const Color(0xFF64748B),
                    title: 'Others',
                    description: 'Additional feature settings',
                  ),
                  const SizedBox(height: 12),
                  _buildOthersSection(),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                  SizedBox(height: 24 + bottomPadding),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTypography.caption.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardToggles() {
    final features = [
      {'title': 'Enable Homescreen Live Summary', 'value': _liveSummary, 'onChanged': (val) => setState(() => _liveSummary = val)},
      {'title': 'Show Cash Inhand', 'value': _cashInhand, 'onChanged': (val) => setState(() => _cashInhand = val)},
      {'title': 'Show To Pay', 'value': _toPay, 'onChanged': (val) => setState(() => _toPay = val)},
      {'title': 'Show To Receive', 'value': _toReceive, 'onChanged': (val) => setState(() => _toReceive = val)},
      {'title': 'Show Today Sales', 'value': _todaySales, 'onChanged': (val) => setState(() => _todaySales = val)},
      {'title': "Show Today's Stock In", 'value': _todayStockIn, 'onChanged': (val) => setState(() => _todayStockIn = val)},
      {'title': "Show Today's Profit", 'value': _todayProfit, 'onChanged': (val) => setState(() => _todayProfit = val)},
      {'title': 'Show Expenses', 'value': _expenses, 'onChanged': (val) => setState(() => _expenses = val)},
      {'title': 'Show Orders', 'value': _orders, 'onChanged': (val) => setState(() => _orders = val)},
    ];

    return _buildCard(
      children: List.generate(features.length, (index) {
        final f = features[index];
        return _FeatureToggle(
          title: f['title'] as String,
          value: f['value'] as bool,
          onChanged: f['onChanged'] as ValueChanged<bool>,
          showDivider: index < features.length - 1,
        );
      }),
    );
  }

  Widget _buildSalesReceiptsSection() {
    return _buildCard(
      children: [
        _FeatureToggle(
          title: 'Enable VAT',
          value: _enableVat,
          onChanged: (val) => setState(() => _enableVat = val),
        ),
        _FeatureToggle(
          title: 'Enable EFD Receipt (TRA)',
          value: _enableEfdReceipt,
          onChanged: (val) => setState(() => _enableEfdReceipt = val),
        ),
        if (_enableVat) ...[
          const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
          _buildFieldRow(
            title: 'VAT Rate (%)',
            child: _buildCompactTextField(
              controller: _vatRateController,
              hintText: '18',
              keyboardType: TextInputType.number,
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
          _buildFieldRow(
            title: 'VAT Policy',
            child: _buildCompactDropdown<String>(
              value: _vatPolicy,
              items: ['Inclusive', 'Exclusive'],
              onChanged: (val) => setState(() => _vatPolicy = val!),
            ),
          ),
        ],
        if (_enableEfdReceipt) ...[
          const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
          _buildFieldRow(
            title: 'TRA Client ID',
            child: _buildCompactTextField(
              controller: _traClientIdController,
              hintText: 'Enter TRA Client ID',
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
          _buildFieldRow(
            title: 'TRA Client Password',
            child: _buildCompactTextField(
              controller: _traClientPasswordController,
              hintText: 'Enter password',
              obscure: true,
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: OutlinedButton(
                    onPressed: _verifyTra,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _isVerified ? AppColors.success : AppColors.primary,
                      side: BorderSide(color: _isVerified ? AppColors.success : AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isVerified ? Icons.verified_rounded : Icons.verified_outlined,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isVerified ? 'Verified' : 'Verify TRA Authentication',
                          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Save credentials only after verification succeeds',
                  style: AppTypography.caption.copyWith(
                    fontSize: 10,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
        const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
        _FeatureToggle(
          title: 'Enable Custom Receipt View',
          value: _enableCustomReceipt,
          onChanged: (val) => setState(() => _enableCustomReceipt = val),
          showDivider: false,
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
        _FeatureToggle(
          title: 'Enable Receipt Printer',
          value: _enableReceiptPrinter,
          onChanged: (val) => setState(() => _enableReceiptPrinter = val),
          showDivider: false,
        ),
        if (_enableReceiptPrinter) ...[
          const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Printer Settings',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pair or connect a printer from the browser permission prompt. No manual fields required.',
                  style: AppTypography.caption.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPrinterButtons(),
              ],
            ),
          ),
        ],
        const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
        _FeatureToggle(
          title: "Show 'Printed By' in Receipt",
          value: _showPrintedBy,
          onChanged: (val) => setState(() => _showPrintedBy = val),
          showDivider: false,
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
        _FeatureToggle(
          title: "Show 'Service Provider' in Receipt",
          value: _showServiceProvider,
          onChanged: (val) => setState(() => _showServiceProvider = val),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
        _FeatureToggle(
          title: 'Show Logo on Receipt',
          value: _showLogoOnReceipt,
          onChanged: (val) => setState(() => _showLogoOnReceipt = val),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
        _buildFieldRow(
          title: 'Customer Message',
          child: _buildCompactTextField(
            controller: _customerMessageController,
            hintText: 'Enter message',
          ),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
        _FeatureToggle(
          title: 'Use Wholesale Price',
          value: _useWholesalePrice,
          onChanged: (val) => setState(() => _useWholesalePrice = val),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
        _FeatureToggle(
          title: 'Sell by First In First Out (FIFO)',
          value: _sellByFifo,
          onChanged: (val) => setState(() => _sellByFifo = val),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
        _buildFieldRow(
          title: 'Default Item Discount %',
          child: _buildCompactTextField(
            controller: _defaultDiscountController,
            hintText: '0',
            keyboardType: TextInputType.number,
          ),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
        _FeatureToggle(
          title: 'Auto-Calculate Selling Price',
          value: _autoCalcSellingPrice,
          onChanged: (val) => setState(() => _autoCalcSellingPrice = val),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
        _FeatureToggle(
          title: 'Print on Save',
          value: _printOnSave,
          onChanged: (val) => setState(() => _printOnSave = val),
          showDivider: false,
        ),
        if (_printOnSave)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'Open print window automatically after saving sale',
              style: AppTypography.caption.copyWith(
                fontSize: 10,
                color: AppColors.textHint,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPrinterButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildPrinterButton('Browser Printer', Icons.language_rounded),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPrinterButton('Wireless Printer', Icons.wifi_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildPrinterButton('Connect Wired/USB', Icons.usb_rounded),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPrinterButton('Connect Bluetooth', Icons.bluetooth_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Printing test page...'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            icon: const Icon(Icons.print_rounded, size: 16),
            label: Text(
              'Print Test Page',
              style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrinterButton(String label, IconData icon) {
    return SizedBox(
      height: 36,
      child: OutlinedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connecting to $label...'),
              backgroundColor: AppColors.success,
            ),
          );
        },
        icon: Icon(icon, size: 14),
        label: Text(
          label,
          style: AppTypography.caption.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }

  Widget _buildProductSection() {
    return _buildCard(
      children: [
        _FeatureToggle(
          title: 'Add Product by Image',
          value: _addProductByImage,
          onChanged: (val) => setState(() => _addProductByImage = val),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
        _FeatureToggle(
          title: 'Enable Barcode Scanner',
          value: _enableBarcodeScanner,
          onChanged: (val) => setState(() => _enableBarcodeScanner = val),
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildModuleSection() {
    return _buildCard(
      children: [
        _FeatureToggle(
          title: 'Enable Manufacturing Module',
          value: _enableManufacturing,
          onChanged: (val) => setState(() => _enableManufacturing = val),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
        _FeatureToggle(
          title: 'Enable TMS Module',
          value: _enableTms,
          onChanged: (val) => setState(() => _enableTms = val),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
        _FeatureToggle(
          title: 'Enable Microfinance Module',
          value: _enableMicrofinance,
          onChanged: (val) => setState(() => _enableMicrofinance = val),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
        _FeatureToggle(
          title: 'Enable Online Shop Module',
          value: _enableOnlineShop,
          onChanged: (val) => setState(() => _enableOnlineShop = val),
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildNotificationSection() {
    return _buildCard(
      children: [
        _FeatureToggle(
          title: 'Alert me what\'s going on with my stock immediately',
          value: _alertStock,
          onChanged: (val) => setState(() => _alertStock = val),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
        _FeatureToggle(
          title: 'Alert me if attendant deletes or edits a sale',
          value: _alertAttendantEdit,
          onChanged: (val) => setState(() => _alertAttendantEdit = val),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
        _FeatureToggle(
          title: 'Alert me on any sale made',
          value: _alertAnySale,
          onChanged: (val) => setState(() => _alertAnySale = val),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
        _FeatureToggle(
          title: 'Send me short daily summary',
          value: _dailySummary,
          onChanged: (val) => setState(() => _dailySummary = val),
        ),
        if (_dailySummary)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Text(
                  'Time: ',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final parts = _dailySummaryTime.split(':');
                    final hour = int.parse(parts[0]);
                    final minParts = parts[1].split(' ');
                    final minute = int.parse(minParts[0]);
                    final isPm = minParts[1] == 'PM';
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: isPm ? (hour == 12 ? 12 : hour + 12) : (hour == 12 ? 0 : hour),
                        minute: minute,
                      ),
                    );
                    if (picked != null) {
                      final h = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
                      final m = picked.minute.toString().padLeft(2, '0');
                      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
                      setState(() => _dailySummaryTime = '$h:$m $period');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          _dailySummaryTime,
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
        _FeatureToggle(
          title: 'Notify me when anyone visits my online store',
          value: _notifyOnlineVisit,
          onChanged: (val) => setState(() => _notifyOnlineVisit = val),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
        _FeatureToggle(
          title: 'On new orders',
          value: _notifyNewOrders,
          onChanged: (val) => setState(() => _notifyNewOrders = val),
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildOthersSection() {
    return _buildCard(
      children: [
        _FeatureToggle(
          title: 'Make "Today" the default data filter',
          value: _defaultTodayFilter,
          onChanged: (val) => setState(() => _defaultTodayFilter = val),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
        _FeatureToggle(
          title: 'Email receipts and invoices on save',
          value: _emailReceipts,
          onChanged: (val) => setState(() => _emailReceipts = val),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
        _FeatureToggle(
          title: 'Enable dashboard action buttons',
          value: _enableDashboardActions,
          onChanged: (val) => setState(() => _enableDashboardActions = val),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
        _FeatureToggle(
          title: 'Enable bar & restaurant feature',
          value: _enableBarRestaurant,
          onChanged: (val) => setState(() => _enableBarRestaurant = val),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
        _FeatureToggle(
          title: 'Enable financial reports',
          value: _enableFinancialReports,
          onChanged: (val) => setState(() => _enableFinancialReports = val),
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildFieldRow({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(width: 140, child: child),
        ],
      ),
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    bool obscure = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textHint),
        filled: true,
        fillColor: const Color(0xFFF5F7FB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          borderSide: BorderSide(color: AppColors.textHint.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          borderSide: BorderSide(color: AppColors.textHint.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildCompactDropdown<T>({
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
        border: Border.all(color: AppColors.textHint.withValues(alpha: 0.3)),
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        isDense: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textHint),
        style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(item.toString(), style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: AppConstants.buttonHeight,
            child: OutlinedButton(
              onPressed: () => context.go('/shop-settings'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.textHint),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                ),
              ),
              child: Text(
                'Cancel',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: AppConstants.buttonHeight,
            child: ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                ),
                elevation: 0,
              ),
              child: Text(
                'Save Changes',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureToggle extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  const _FeatureToggle({
    required this.title,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primary,
                inactiveTrackColor: AppColors.border,
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return Colors.white;
                }),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
      ],
    );
  }
}
