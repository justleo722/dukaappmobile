import 'package:dukaapp/core/network/api_client.dart';
import 'package:dukaapp/core/services/api_endpoints.dart';
import 'package:dukaapp/features/stock/data/models/stock_models.dart';

class StockRemoteDatasource {
  final ApiClient _client;

  StockRemoteDatasource(this._client);

  // ── GET ──────────────────────────────────────────────────────────────────

  /// Full stock ledger (product + qty + costs)
  Future<List<StockProduct>> fetchStock() async {
    final res = await _client.get(ApiEndpoints.getDataStock);
    return _list(res.data).map(StockProduct.fromJson).toList();
  }

  /// Category list with product counts
  Future<List<StockCategory>> fetchCategories() async {
    final res = await _client.get(ApiEndpoints.getDataStockCategory);
    return _list(res.data).map(StockCategory.fromJson).toList();
  }

  /// Total stock value & item count
  Future<StockValueSummary> fetchSummary() async {
    final res = await _client.get(ApiEndpoints.getDataStockValueSummary);
    final raw = _list(res.data);
    if (raw.isNotEmpty) return StockValueSummary.fromJson(raw.first);
    return StockValueSummary.empty;
  }

  /// Simple products list (id, name, category — lighter than full stock)
  Future<List<StockProduct>> fetchProducts() async {
    final res = await _client.get(ApiEndpoints.getDataProducts);
    return _list(res.data).map(StockProduct.fromJson).toList();
  }

  /// Low-stock products
  Future<List<StockProduct>> fetchLowStock() async {
    final res = await _client.get(ApiEndpoints.getDataLowStock);
    return _list(res.data).map(StockProduct.fromJson).toList();
  }

  /// Products from a specific (source) shop — used for import-from-shop
  Future<List<Map<String, dynamic>>> fetchProductsByShop(String shopId) async {
    final res = await _client.get(
      ApiEndpoints.getDataProducts,
      queryParameters: {'shop_id': shopId},
    );
    return _list(res.data).map((p) => {
      'name': p['product_name'] ?? p['name'] ?? '',
      'barcode': p['barcode'] ?? p['bar_code'] ?? '',
      'buyingPrice': double.tryParse(p['buying_price']?.toString() ?? p['cost_price']?.toString() ?? '0') ?? 0.0,
      'sellingPrice': double.tryParse(p['selling_price']?.toString() ?? p['price']?.toString() ?? '0') ?? 0.0,
      'wholesalePrice': double.tryParse(p['wholesale_price']?.toString() ?? '0') ?? 0.0,
      'stock': int.tryParse(p['available']?.toString() ?? p['quantity']?.toString() ?? '0') ?? 0,
      'product_id': p['product_id'] ?? p['id'],
    }).toList();
  }

  /// Expired products
  Future<List<StockProduct>> fetchExpiredStock() async {
    final res = await _client.get(ApiEndpoints.getDataExpiredStock);
    return _list(res.data).map(StockProduct.fromJson).toList();
  }

  // ── POST ─────────────────────────────────────────────────────────────────

  /// Create a new product (stock/register/create)
  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> body) async {
    final res = await _client.post(ApiEndpoints.postStockRegisterCreate, data: body);
    return _json(res.data);
  }

  /// Update existing product details (stock/product/update)
  Future<Map<String, dynamic>> updateProduct(Map<String, dynamic> body) async {
    final res = await _client.post(ApiEndpoints.postStockProductUpdate, data: body);
    return _json(res.data);
  }

  /// Adjust stock balance (stock/restock/balance)
  Future<Map<String, dynamic>> adjustStockBalance(Map<String, dynamic> body) async {
    final res = await _client.post(ApiEndpoints.postStockRestockBalance, data: body);
    return _json(res.data);
  }

  /// Create a purchase/restock record (stock/restock/create)
  Future<Map<String, dynamic>> createRestock(Map<String, dynamic> body) async {
    final res = await _client.post(ApiEndpoints.postStockRestockCreate, data: body);
    return _json(res.data);
  }

  /// Transfer stock to another shop (stock/transfer)
  Future<Map<String, dynamic>> transferStock(Map<String, dynamic> body) async {
    final res = await _client.post(ApiEndpoints.postStockTransfer, data: body);
    return _json(res.data);
  }

  /// Copy products from another shop (stock/copy-in-products)
  Future<Map<String, dynamic>> copyInProducts(Map<String, dynamic> body) async {
    final res = await _client.post(ApiEndpoints.postStockCopyInProducts, data: body);
    return _json(res.data);
  }

  /// Create a product category (stock/category/create)
  Future<Map<String, dynamic>> createCategory(String name) async {
    final res = await _client.post(
      ApiEndpoints.postStockCategoryCreate,
      data: {'category': name},
    );
    return _json(res.data);
  }

  /// Bulk import products from parsed spreadsheet rows (stock/register/import)
  Future<Map<String, dynamic>> importProducts(List<Map<String, dynamic>> products) async {
    final res = await _client.post(
      ApiEndpoints.postStockRegisterImport,
      data: {'products': products},
    );
    return _json(res.data);
  }

  /// Import/purchase history records
  Future<List<Map<String, dynamic>>> fetchImportHistory() async {
    final res = await _client.get(ApiEndpoints.getDataPurchaseHistory);
    return _list(res.data);
  }

  /// Soft-delete products in bulk (stock/product/bulk-delete)
  Future<Map<String, dynamic>> bulkDeleteProducts(List<dynamic> productIds) async {
    final res = await _client.post(
      ApiEndpoints.postStockProductBulkDelete,
      data: {'product_id': productIds},
    );
    return _json(res.data);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _list(dynamic body) {
    if (body is List) {
      return body.whereType<Map<String, dynamic>>().toList();
    }
    if (body is Map<String, dynamic>) {
      final v = body['data'] ?? body['result'] ?? body['items'];
      if (v is List) return v.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  Map<String, dynamic> _json(dynamic body) {
    if (body is Map<String, dynamic>) return body;
    return {'status': 'error', 'message': body?.toString() ?? 'Unknown error'};
  }
}
