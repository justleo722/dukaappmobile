import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/features/online_shop/presentation/widgets/track_order_bottom_sheet.dart';
import 'package:dukaapp/features/online_shop/presentation/widgets/shop_by_id_bottom_sheet.dart';

class StorefrontPage extends ConsumerStatefulWidget {
  const StorefrontPage({super.key});

  @override
  ConsumerState<StorefrontPage> createState() => _StorefrontPageState();
}

class _StorefrontPageState extends ConsumerState<StorefrontPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _productsKey = GlobalKey();
  final List<Map<String, dynamic>> _cart = [];
  String _selectedSort = 'Default';
  bool _isLoading = true;
  String? _shopName;
  String? _encodedShopId;

  // Populated from API; falls back to empty list when loading
  List<Map<String, dynamic>> _categories = const [];

  static const List<Map<String, dynamic>> _fallbackCategories = [
    {'icon': Icons.category_rounded, 'label': 'Uncategorized'},
    {'icon': Icons.local_drink_rounded, 'label': 'Drinks'},
    {'icon': Icons.bolt_rounded, 'label': 'Energy Drinks'},
    {'icon': Icons.sports_bar_rounded, 'label': 'Local Beer'},
    {'icon': Icons.checkroom_rounded, 'label': 'Clothing'},
    {'icon': Icons.laptop_mac_rounded, 'label': 'Electronics'},
    {'icon': Icons.kitchen_rounded, 'label': 'Home & Kitchen'},
    {'icon': Icons.spa_rounded, 'label': 'Beauty'},
  ];

  List<Map<String, dynamic>> _products = const [];

  // ── API helpers ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  /// Converts an API double/string price to a display string.
  static String _fmtPrice(dynamic raw, String currency) {
    if (raw == null) return '';
    final d = raw is double ? raw : double.tryParse(raw.toString()) ?? 0.0;
    return '$currency ${d.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  /// Returns a generic icon for a product category name.
  static IconData _iconForCategory(String? cat) {
    final c = (cat ?? '').toLowerCase();
    if (c.contains('phone') || c.contains('tech') || c.contains('electronic')) return Icons.phone_iphone_rounded;
    if (c.contains('drink') || c.contains('beverage') || c.contains('beer') || c.contains('soda')) return Icons.local_drink_rounded;
    if (c.contains('cloth') || c.contains('fashion') || c.contains('shoe') || c.contains('wear')) return Icons.checkroom_rounded;
    if (c.contains('food') || c.contains('grocery') || c.contains('kitchen')) return Icons.kitchen_rounded;
    if (c.contains('beauty') || c.contains('cosmetic') || c.contains('perfume')) return Icons.spa_rounded;
    if (c.contains('laptop') || c.contains('computer')) return Icons.laptop_mac_rounded;
    return Icons.inventory_2_rounded;
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      // Use admin data to get encoded shop_id + shop name; then fetch public data
      final adminRes = await api.getOnlineShopAdmin();
      final adminRaw = adminRes.data;
      Map<String, dynamic> admin = {};
      if (adminRaw is Map<String, dynamic>) {
        admin = adminRaw['data'] is Map ? adminRaw['data'] as Map<String, dynamic> : adminRaw;
      }
      final publicUrl = admin['public_url']?.toString() ?? '';
      // Extract encoded shop id from public_url (last path segment)
      final uri = Uri.tryParse(publicUrl);
      _encodedShopId = uri?.pathSegments.isNotEmpty == true ? uri!.pathSegments.last : null;

      // Now fetch public storefront data
      final pubRes = await api.getOnlineShopPublic();
      final pubRaw = pubRes.data;
      Map<String, dynamic> pub = {};
      if (pubRaw is Map<String, dynamic>) {
        pub = pubRaw['data'] is Map ? pubRaw['data'] as Map<String, dynamic> : pubRaw;
      } else if (pubRaw is List && pubRaw.isNotEmpty && pubRaw.first is Map) {
        pub = Map<String, dynamic>.from(pubRaw.first as Map);
      }

      final shop = pub['shop'];
      final currency = (shop is Map ? shop['currency']?.toString() : null) ?? 'TZS';
      _shopName = (shop is Map ? shop['shop_name']?.toString() : null) ?? 'DukaApp Online Shop';

      // Map products
      final rawProducts = pub['products'];
      final productList = rawProducts is List ? rawProducts : [];
      _products = productList.whereType<Map<String, dynamic>>().map((p) {
        final catName = p['category']?.toString() ?? '';
        final imagePath = p['image_path']?.toString() ?? p['image']?.toString();
        final imageUrl = (imagePath != null && imagePath.isNotEmpty)
            ? (imagePath.startsWith('http') ? imagePath : 'http://192.168.0.107/dukaapp/$imagePath')
            : null;
        return {
          'product_id': p['product_id']?.toString() ?? '',
          'name': p['product_name']?.toString() ?? p['name']?.toString() ?? '',
          'price': _fmtPrice(p['ecommerce_price'] ?? p['selling_price'], currency),
          'seller': p['shop_name']?.toString() ?? _shopName ?? '',
          'icon': _iconForCategory(catName),
          'collection': catName.isNotEmpty ? catName.toUpperCase() : 'GENERAL',
          'description': p['description']?.toString() ?? p['notes']?.toString() ?? '',
          'images': imageUrl != null ? [imageUrl] : <String>[],
          'quantity': p['quantity'] ?? p['qty'],
          'code': p['code']?.toString() ?? p['barcode']?.toString() ?? '',
          '_raw': p,
        };
      }).toList();

      // Map categories
      final rawCats = pub['categories'];
      final catList = rawCats is List ? rawCats : [];
      if (catList.isNotEmpty) {
        _categories = catList.whereType<Map<String, dynamic>>().map((c) {
          final name = c['category']?.toString() ?? '';
          return {
            'icon': _iconForCategory(name),
            'label': name,
            'count': c['products_count'],
          };
        }).toList();
      } else {
        _categories = _fallbackCategories;
      }
    } catch (_) {
      _categories = _fallbackCategories;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // ── Sort helper ───────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _displayProducts {
    final list = List<Map<String, dynamic>>.from(_products);
    switch (_selectedSort) {
      case 'A-Z': list.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String)); break;
      case 'Z-A': list.sort((a, b) => (b['name'] as String).compareTo(a['name'] as String)); break;
      default: break;
    }
    return list;
  }

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      final existing = _cart.indexWhere((item) => item['name'] == product['name']);
      if (existing >= 0) {
        _cart[existing]['qty'] = (_cart[existing]['qty'] ?? 1) + 1;
      } else {
        _cart.add({...product, 'qty': 1});
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} added to cart'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToProducts() {
    final ctx = _productsKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleTrackOrder(String orderId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tracking order #$orderId...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _handleBrowseShop(String shopId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Browsing shop #$shopId...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showFilterDropdown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sort By',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...['Default', 'Newest', 'Oldest', 'A-Z', 'Z-A',
                    'Price: Low-High', 'Price: High-Low']
                .map(
              (option) => ListTile(
                title: Text(
                  option,
                  style: AppTypography.bodyMedium.copyWith(
                    color: _selectedSort == option
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontWeight: _selectedSort == option
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
                trailing: _selectedSort == option
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _selectedSort = option);
                  Navigator.pop(ctx);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: _buildDrawer(context),
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
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/login');
                }
              },
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
          _shopName ?? 'DukaApp Online Shop',
          style: AppTypography.h6.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border, width: 1.5),
                    borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                  ),
                  child: IconButton(
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    icon: const Icon(
                      Icons.menu_rounded,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ),
              if (_cart.isNotEmpty)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_cart.length}',
                      style: AppTypography.captionBold.copyWith(
                        color: AppColors.textWhite,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            _buildHeroBanner(),
            _buildCategorySection(),
            _buildFeaturedProducts(),
            _buildRegisterBanner(),
            _buildFooter(),
            SizedBox(height: bottomPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.card,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: const Row(
              children: [
                Icon(Icons.search_rounded, color: AppColors.textHint, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Search products...',
                    style: TextStyle(color: AppColors.textHint),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSmallButton(Icons.filter_list_rounded, 'Filter', onTap: _showFilterDropdown),
              const SizedBox(width: 8),
              _buildSmallButton(Icons.store_rounded, 'Shop by ID', onTap: () {
                ShopByIdBottomSheet.show(
                  context: context,
                  onBrowseShop: _handleBrowseShop,
                );
              }),
              const SizedBox(width: 8),
              _buildSmallButton(Icons.shopping_cart_rounded, 'Cart (${_cart.length})', onTap: () => context.push('/shopping-cart', extra: _cart)),
              const SizedBox(width: 8),
              _buildSmallButton(Icons.local_shipping_rounded, 'Track Order', onTap: () {
                TrackOrderBottomSheet.show(
                  context: context,
                  onTrackOrder: _handleTrackOrder,
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallButton(IconData icon, String label, {VoidCallback? onTap}) {
    final content = Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    return Expanded(
      child: onTap != null
          ? GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: content)
          : content,
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFFFF7A00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shop Quality Products\nfrom Different Shops',
            style: AppTypography.h4.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discover thousands of products from\ntrusted sellers across Tanzania',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textWhite.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: AppConstants.buttonHeight,
            child: ElevatedButton(
              onPressed: _scrollToProducts,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textWhite,
                foregroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusSM),
                ),
              ),
              child: Text(
                'Start Shopping',
                style: AppTypography.buttonLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shop by Category',
            style: AppTypography.label.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return SizedBox(
                  width: 64,
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          cat['icon'],
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat['label'],
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedProducts() {
    return Padding(
      key: _productsKey,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Featured Products',
            style: AppTypography.label.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_displayProducts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.inventory_2_outlined, size: 56, color: AppColors.textHint.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                Text('No products available', style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint)),
              ])),
            )
          else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _displayProducts.map((product) {
              final cardWidth =
                  (MediaQuery.of(context).size.width - 44) / 2;
              return SizedBox(
                width: cardWidth,
                child: _ProductCard(
                  product: product,
                  onAddToCart: () => _addToCart(product),
                  onTap: () async {
                    final result = await context.push<Map<String, dynamic>>('/product-details', extra: product);
                    if (result != null) _addToCart(result);
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
      ),
      child: Column(
        children: [
          Text(
            'Register Your Shop on DukaApp',
            style: AppTypography.h6.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: AppConstants.buttonHeight,
            child: ElevatedButton(
              onPressed: () => context.push('/register'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textWhite,
                foregroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                ),
              ),
              child: Text(
                'Get Started',
                style: AppTypography.buttonLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1E3A5F),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFooterSection(
            'About DukaApp',
            "DukaApp is Tanzania's premier business management platform helping shop owners manage sales, stock, purchases and more.",
          ),
          const SizedBox(height: 12),
          _buildSocialIcons(),
          const SizedBox(height: 20),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildFooterLinks('Quick Links', [
                    'Home',
                    'Products',
                    'Categories',
                    'My Cart',
                    'Track Order',
                  ]),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildFooterSection('Contact', [
                    'Dar es Salaam, Tanzania',
                    '+255 755 644 282',
                    'support@dukaapp.co.tz',
                  ].join('\n')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildFooterDownloadButtons(),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '\u00a9 2026 DukaApp. All rights reserved.',
              style: AppTypography.caption.copyWith(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.label.copyWith(
            color: AppColors.textWhite,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: AppTypography.caption.copyWith(
            color: Colors.white70,
            fontSize: 11,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialIcons() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => launchUrl(Uri.parse('https://instagram.com/dukaapp_pos')),
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CustomPaint(
                size: const Size(18, 18),
                painter: _InstagramIconPainter(color: Colors.white),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildSocialButton(
          child: const Icon(Icons.facebook_rounded, color: Colors.white, size: 20),
          onTap: () => launchUrl(Uri.parse('https://facebook.com/dukaapppos')),
        ),
        const SizedBox(width: 10),
        _buildSocialButton(
          child: SvgPicture.asset(
            'assets/icons/whatsapp.svg',
            width: 18,
            height: 18,
          ),
          onTap: () => launchUrl(Uri.parse('https://wa.me/255769651495')),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Colors.white24,
          shape: BoxShape.circle,
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildFooterLinks(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.label.copyWith(
            color: AppColors.textWhite,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...links.map(
          (link) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              link,
              style: AppTypography.caption.copyWith(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterDownloadButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Download',
          style: AppTypography.label.copyWith(
            color: AppColors.textWhite,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildDownloadButton(Icons.android_rounded, 'Google Play'),
            const SizedBox(width: 8),
            _buildDownloadButton(Icons.apple_rounded, 'App Store'),
          ],
        ),
      ],
    );
  }

  Widget _buildDownloadButton(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.inventory_2_rounded, 'label': 'Products'},
      {'icon': Icons.shopping_cart_rounded, 'label': 'My Cart'},
      {'icon': Icons.local_shipping_rounded, 'label': 'Track Order'},
    ];

    return Drawer(
      backgroundColor: AppColors.card,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/images/submark_logo.png',
                    width: 48,
                    height: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'DukaApp Shop',
                    style: AppTypography.h6.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Quality products, trusted sellers',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: AppColors.divider, height: 1),
            ),
            const SizedBox(height: 8),
            ...items.map(
              (item) {
                final isCart = item['label'] == 'My Cart';
                return ListTile(
                  leading: Icon(
                    item['icon'] as IconData,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                  trailing: isCart && _cart.isNotEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_cart.length}',
                            style: AppTypography.captionBold.copyWith(
                              color: AppColors.textWhite,
                              fontSize: 11,
                            ),
                          ),
                        )
                      : null,
                  title: Text(
                    item['label'] as String,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  onTap: () {
                    Navigator.pop(context);
                    if (item['label'] == 'Home') {
                      context.go('/storefront');
                    } else if (item['label'] == 'Products') {
                      _scrollToProducts();
                    } else if (isCart) {
                      context.push('/shopping-cart', extra: _cart);
                    } else if (item['label'] == 'Track Order') {
                      TrackOrderBottomSheet.show(
                        context: context,
                        onTrackOrder: _handleTrackOrder,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Opening ${item['label']}'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onAddToCart;
  final VoidCallback? onTap;

  const _ProductCard({required this.product, required this.onAddToCart, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppConstants.radiusMD),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppConstants.radiusMD),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildProductImage(product),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF25D366),
                        shape: BoxShape.circle,
                      ),
                      child: SvgPicture.asset(
                        'assets/icons/whatsapp.svg',
                        width: 20,
                        height: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'],
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product['price'],
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product['seller'],
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textHint,
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.favorite_border_rounded,
                      size: 18,
                      color: AppColors.textHint,
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onAddToCart,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          size: 20,
                          color: AppColors.textWhite,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildProductImage(Map<String, dynamic> product) {
    final images = product['images'] as List<dynamic>?;
    if (images != null && images.isNotEmpty) {
      return Image.network(
        images[0] as String,
        width: double.infinity,
        height: 100,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: Icon(
              product['icon'],
              size: 40,
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(
              product['icon'],
              size: 40,
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          );
        },
      );
    }
    return Center(
      child: Icon(
        product['icon'],
        size: 40,
        color: AppColors.primary.withValues(alpha: 0.3),
      ),
    );
  }
}

class _InstagramIconPainter extends CustomPainter {
  final Color color;
  _InstagramIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final r = size.width * 0.28;
    final outerR = Radius.circular(size.width * 0.22);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawRRect(RRect.fromRectAndRadius(rect, outerR), paint);

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, r, paint);

    final dotCenter = Offset(size.width * 0.78, size.height * 0.22);
    canvas.drawCircle(dotCenter, size.width * 0.06, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _InstagramIconPainter oldDelegate) => oldDelegate.color != color;
}
