import 'dart:convert';
import 'package:dukaapp/core/config/api_config.dart';

/// Product row returned by GET getdata/stock
class StockProduct {
  final dynamic productId;
  final dynamic stockId;    // latest stock batch id (null for services)
  final String name;
  final String? category;
  final dynamic categoryId;
  final String? type;       // 'product' | 'service'
  final double buyingPrice;
  final double sellingPrice;
  final double wholesalePrice;
  final double available;   // current stock qty
  final double reorderLevel;
  final String? unit;
  final String? barcode;
  final String? expiryDate;
  final String? status;     // 'active' | 'deleted'
  final String? imageUrl;

  // Movement/report fields (populated when fetched with date range)
  final double sold;
  final double bad;
  final double lost;
  final double stolen;
  final double totalIn;
  final double totalRevenue;
  final double totalCost;
  final double profitEstimate;
  final double stockValue;
  final double loss;

  const StockProduct({
    required this.productId,
    this.stockId,
    required this.name,
    this.category,
    this.categoryId,
    this.type,
    this.buyingPrice = 0,
    this.sellingPrice = 0,
    this.wholesalePrice = 0,
    this.available = 0,
    this.reorderLevel = 0,
    this.unit,
    this.barcode,
    this.expiryDate,
    this.status,
    this.imageUrl,
    this.sold = 0,
    this.bad = 0,
    this.lost = 0,
    this.stolen = 0,
    this.totalIn = 0,
    this.totalRevenue = 0,
    this.totalCost = 0,
    this.profitEstimate = 0,
    this.stockValue = 0,
    this.loss = 0,
  });

  bool get isService => type?.toLowerCase() == 'service';

  bool get isLowStock =>
      !isService && reorderLevel > 0 && available <= reorderLevel;

  bool get isOutOfStock => !isService && available <= 0;

  factory StockProduct.fromJson(Map<String, dynamic> j) {
    return StockProduct(
      productId: j['product_id'] ?? j['id'],
      stockId: j['stock_id'],
      name: (j['product_name'] ?? j['name'] ?? '').toString(),
      category: j['category']?.toString(),
      categoryId: j['category_id'],
      type: j['type']?.toString(),
      // API returns 'bp'/'sp'/'wp' from stock_report(); also accept the
      // long-form aliases used in some other endpoints.
      buyingPrice: _d(j['bp'] ?? j['buying_price'] ?? j['cost_price']),
      sellingPrice: _d(j['sp'] ?? j['selling_price'] ?? j['price']),
      wholesalePrice: _d(j['wp'] ?? j['wholesale_price']),
      available: _d(j['available'] ?? j['quantity'] ?? j['qty']),
      reorderLevel: _d(j['reorder_level']),
      unit: j['unit']?.toString(),
      barcode: j['barcode']?.toString(),
      expiryDate: j['expiry_date']?.toString(),
      status: j['record_status']?.toString(),
      imageUrl: _resolveImageUrl(
          _firstPhoto(j['photo']?.toString(), shopId: j['shop_id']?.toString()) ??
          j['image']?.toString() ??
          j['image_url']?.toString()),
      sold: _d(j['sold']),
      bad: _d(j['bad']),
      lost: _d(j['lost']),
      stolen: _d(j['stolen']),
      totalIn: _d(j['total_in']),
      totalRevenue: _d(j['total_revenue']),
      totalCost: _d(j['total_cost']),
      profitEstimate: _d(j['profit_estimate']),
      stockValue: _d(j['stock_value']),
      loss: _d(j['loss']),
    );
  }

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'stock_id': stockId,
        'product_name': name,
        'category': category,
        'category_id': categoryId,
        'type': type,
        'buying_price': buyingPrice,
        'selling_price': sellingPrice,
        'wholesale_price': wholesalePrice,
        'available': available,
        'reorder_level': reorderLevel,
        'unit': unit,
        'barcode': barcode,
        'expiry_date': expiryDate,
        'record_status': status,
        'image': imageUrl,
      };

  static double _d(dynamic v) {
    if (v == null) return 0;
    return double.tryParse(v.toString()) ?? 0;
  }

  /// Photo column is stored as a JSON array of filenames — extract the first one
  /// and build the relative path using shopId when available.
  static String? _firstPhoto(String? raw, {String? shopId}) {
    if (raw == null || raw.trim().isEmpty) return null;
    final trimmed = raw.trim();
    String? filename;
    if (trimmed.startsWith('[')) {
      try {
        final list = jsonDecode(trimmed) as List;
        filename = list.isNotEmpty ? list.first?.toString() : null;
      } catch (_) {}
    } else {
      filename = trimmed;
    }
    if (filename == null || filename.isEmpty) return null;
    // If already a full path (contains '/'), return as-is
    if (filename.contains('/')) return filename;
    // Build full path using shopId
    if (shopId != null && shopId.isNotEmpty) {
      return 'uploads/shops/$shopId/products/$filename';
    }
    return filename;
  }

  /// Convert a relative image path from the API to a full URL.
  /// The API returns paths like "uploads/shops/1/products/image.jpg".
  static String? _resolveImageUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final path = raw.trim();
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final baseUrl = ApiConfig.baseUrl;
    return '$baseUrl/${path.replaceFirst(RegExp(r'^/+'), '')}';
  }
}

/// Category row from GET getdata/stock_category
class StockCategory {
  final dynamic categoryId;
  final String name;
  final int productCount;

  const StockCategory({
    required this.categoryId,
    required this.name,
    this.productCount = 0,
  });

  factory StockCategory.fromJson(Map<String, dynamic> j) {
    return StockCategory(
      categoryId: j['category_id'] ?? j['id'],
      name: (j['category'] ?? j['name'] ?? '').toString(),
      productCount: int.tryParse((j['products'] ?? j['product_count'] ?? 0).toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'category_id': categoryId,
        'category': name,
        'products': productCount,
      };
}

/// Summary from GET getdata/stock_value_summary
class StockValueSummary {
  final String currency;
  final int itemsCount;
  final double available;
  final double stockValue;

  const StockValueSummary({
    this.currency = 'Tsh',
    this.itemsCount = 0,
    this.available = 0,
    this.stockValue = 0,
  });

  factory StockValueSummary.fromJson(Map<String, dynamic> j) {
    return StockValueSummary(
      currency: (j['currency'] ?? 'Tsh').toString(),
      itemsCount: int.tryParse((j['items_count'] ?? 0).toString()) ?? 0,
      available: double.tryParse((j['available'] ?? 0).toString()) ?? 0,
      stockValue: double.tryParse((j['stock_value'] ?? 0).toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'currency': currency,
        'items_count': itemsCount,
        'available': available,
        'stock_value': stockValue,
      };

  /// Estimated profit = (selling_value - buying_value). Backend only returns
  /// stock_value (buying). We expose stockValue for display; profit comes from
  /// individual product margins computed on the client if needed.
  static const StockValueSummary empty = StockValueSummary();
}

/// Full stock state exposed to the UI
class StockState {
  final List<StockProduct> products;
  final List<StockCategory> categories;
  final StockValueSummary summary;

  const StockState({
    this.products = const [],
    this.categories = const [],
    this.summary = StockValueSummary.empty,
  });

  Map<String, dynamic> toJson() => {
        'products': products.map((p) => p.toJson()).toList(),
        'categories': categories.map((c) => c.toJson()).toList(),
        'summary': summary.toJson(),
      };

  factory StockState.fromCache(Map<String, dynamic> j) {
    final p = (j['products'] as List? ?? [])
        .map((e) => StockProduct.fromJson(e as Map<String, dynamic>))
        .toList();
    final c = (j['categories'] as List? ?? [])
        .map((e) => StockCategory.fromJson(e as Map<String, dynamic>))
        .toList();
    final s = j['summary'] is Map<String, dynamic>
        ? StockValueSummary.fromJson(j['summary'] as Map<String, dynamic>)
        : StockValueSummary.empty;
    return StockState(products: p, categories: c, summary: s);
  }
}
