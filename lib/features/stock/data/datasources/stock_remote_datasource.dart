import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dukaapp/core/network/api_client.dart';
import 'package:dukaapp/core/services/api_endpoints.dart';
import 'package:dukaapp/features/stock/data/models/stock_models.dart';

class StockRemoteDatasource {
  final ApiClient _client;

  StockRemoteDatasource(this._client);

  /// Encode [map] as a URL-encoded string and POST it, with plain response
  /// type so PHP warnings before JSON don't crash the parser.
  Future<Map<String, dynamic>> _formPost(
    String path,
    Map<String, dynamic> map,
  ) async {
    final encoded = map.entries
        .where((e) => e.value != null)
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}='
            '${Uri.encodeQueryComponent(e.value.toString())}')
        .join('&');
    final res = await _client.post(
      path,
      data: encoded,
      options: Options(
        contentType: 'application/x-www-form-urlencoded',
        responseType: ResponseType.plain,
      ),
    );
    return _jsonFromPlain(res.data);
  }

  /// Encode Lists with PHP bracket notation: key[0]=v0&key[1]=v1
  String _encodeBracketForm(Map<String, dynamic> map) {
    final parts = <String>[];
    for (final entry in map.entries) {
      final v = entry.value;
      if (v is List) {
        for (int i = 0; i < v.length; i++) {
          parts.add(
            '${Uri.encodeQueryComponent('${entry.key}[$i]')}='
            '${Uri.encodeQueryComponent(v[i]?.toString() ?? '')}',
          );
        }
      } else {
        parts.add(
          '${Uri.encodeQueryComponent(entry.key)}='
          '${Uri.encodeQueryComponent(v?.toString() ?? '')}',
        );
      }
    }
    return parts.join('&');
  }

  Future<Map<String, dynamic>> _bracketFormPost(
    String path,
    Map<String, dynamic> map,
  ) async {
    final res = await _client.post(
      path,
      data: _encodeBracketForm(map),
      options: Options(
        contentType: 'application/x-www-form-urlencoded',
        responseType: ResponseType.plain,
      ),
    );
    return _jsonFromPlain(res.data);
  }

  Map<String, dynamic> _jsonFromPlain(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    final raw = data?.toString() ?? '';
    if (raw.isEmpty) return {};
    try {
      final start = raw.indexOf('{');
      final end = raw.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        final decoded = jsonDecode(raw.substring(start, end + 1));
        if (decoded is Map<String, dynamic>) return decoded;
      }
    } catch (_) {}
    return {};
  }

  // ── GET ──────────────────────────────────────────────────────────────────

  /// Full stock ledger (product + qty + costs)
  Future<List<StockProduct>> fetchStock({String? from, String? to}) async {
    final params = <String, dynamic>{};
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;
    final res = await _client.get(ApiEndpoints.getDataStock, queryParameters: params.isEmpty ? null : params);
    return _list(res.data).map(StockProduct.fromJson).toList();
  }

  /// Category list with product counts
  Future<List<StockCategory>> fetchCategories() async {
    final res = await _client.get(ApiEndpoints.getDataStockCategory);
    return _list(res.data).map(StockCategory.fromJson).toList();
  }

  /// Total stock value & item count (optionally filtered by date)
  Future<StockValueSummary> fetchSummary({String? from, String? to}) async {
    final params = <String, dynamic>{};
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;
    final res = await _client.get(ApiEndpoints.getDataStockValueSummary,
        queryParameters: params.isEmpty ? null : params);
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

  /// Products belonging to a specific (remote) shop — used by import-from-shop
  /// and transfer flows. Uses the mapped GET endpoint so the backend resolves
  /// the correct shop regardless of the caller's session shop.
  Future<List<Map<String, dynamic>>> fetchProductsByShop(String shopId) async {
    final res = await _client.get(ApiEndpoints.getMappedStockRemoteProducts(shopId));
    // stock_report() returns 'bp'/'sp'/'wp'; also accept long-form aliases.
    return _list(res.data).map((p) => {
      'name': p['product_name'] ?? p['name'] ?? '',
      'barcode': p['barcode'] ?? p['bar_code'] ?? '',
      'buyingPrice': double.tryParse((p['bp'] ?? p['buying_price'] ?? p['cost_price'] ?? '0').toString()) ?? 0.0,
      'sellingPrice': double.tryParse((p['sp'] ?? p['selling_price'] ?? p['price'] ?? '0').toString()) ?? 0.0,
      'wholesalePrice': double.tryParse((p['wp'] ?? p['wholesale_price'] ?? '0').toString()) ?? 0.0,
      'stock': int.tryParse((p['available'] ?? p['quantity'] ?? '0').toString()) ?? 0,
      'product_id': p['product_id'] ?? p['id'],
    }).toList();
  }

  /// Expired products
  Future<List<StockProduct>> fetchExpiredStock() async {
    final res = await _client.get(ApiEndpoints.getDataExpiredStock);
    return _list(res.data).map(StockProduct.fromJson).toList();
  }

  // ── POST ─────────────────────────────────────────────────────────────────

  static final _formOptions = Options(contentType: 'application/x-www-form-urlencoded');

  /// Create a new product (stock/register/create)
  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> body, {List<File>? photos}) async {
    final data = await _buildProductData(body, photos);
    final res = await _client.post(ApiEndpoints.postStockRegisterCreate, data: data,
        options: Options(responseType: ResponseType.plain));
    return _jsonFromPlain(res.data);
  }

  /// Update existing product details (stock/product/update)
  Future<Map<String, dynamic>> updateProduct(Map<String, dynamic> body, {List<File>? photos}) async {
    final data = await _buildProductData(body, photos);
    final res = await _client.post(ApiEndpoints.postStockProductUpdate, data: data,
        options: Options(responseType: ResponseType.plain));
    return _jsonFromPlain(res.data);
  }

  Future<dynamic> _buildProductData(Map<String, dynamic> body, List<File>? photos) async {
    if (photos == null || photos.isEmpty) {
      return body.entries.where((e) => e.value != null)
          .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value.toString())}')
          .join('&');
    }
    final form = FormData.fromMap(body.map((k, v) => MapEntry(k, v?.toString() ?? '')));
    for (final file in photos) {
      final name = file.path.split('/').last;
      form.files.add(MapEntry('photos[]', await MultipartFile.fromFile(file.path, filename: name)));
    }
    return form;
  }

  /// Adjust stock balance (stock/restock/balance).
  ///
  /// PHP reads flat fields: product_id, quantity, movement_type.
  /// Send one POST per adjustment item; return the last response (or first error).
  Future<Map<String, dynamic>> adjustStockBalance(Map<String, dynamic> body) async {
    final adjustments = (body['adjustments'] as List?) ?? [];
    if (adjustments.isEmpty) {
      return {'status': 'error', 'message': 'No adjustments provided'};
    }
    Map<String, dynamic> lastResult = {};
    for (final item in adjustments) {
      final m = item as Map<String, dynamic>;
      final type = (m['movement_type'] ?? m['type'])?.toString() ?? '';
      if (type == 'none' || type.isEmpty) continue;
      final flat = {
        'product_id': m['product_id']?.toString() ?? '',
        'stock_id': m['stock_id']?.toString() ?? '',
        'quantity': m['quantity']?.toString() ?? '0',
        'movement_type': type,
      };
      lastResult = await _formPost(ApiEndpoints.postStockRestockBalance, flat);
      if ((lastResult['status'] ?? '') == 'error') return lastResult;
    }
    return lastResult.isNotEmpty
        ? lastResult
        : {'status': 'success', 'message': 'No items to adjust'};
  }

  /// Create a purchase/restock record (stock/restock/create).
  ///
  /// Caller pre-encodes bracket keys (product_id[0], quantity[pid], bp[pid] …)
  /// so we just URL-encode each flat key/value pair here.
  Future<Map<String, dynamic>> createRestock(Map<String, dynamic> body) async {
    return _formPost(ApiEndpoints.postStockRestockCreate, body);
  }

  /// Transfer stock to another shop (stock/transfer).
  ///
  /// PHP mobile path reads `products` as a JSON string then json_decodes it.
  /// Must be manually URL-encoded so Dio doesn't corrupt the JSON value.
  Future<Map<String, dynamic>> transferStock(Map<String, dynamic> body) async {
    final toShop = body['to_shop_id']?.toString() ?? '';
    final products = (body['products'] as List?) ?? [];
    return _formPost(ApiEndpoints.postStockTransfer, {
      'to_shop_id': toShop,
      'toShop': toShop,
      'products': jsonEncode(products),
    });
  }

  /// Copy products from another shop (stock/copy-in-products).
  ///
  /// Accepts: { 'product_id': [id1, id2, ...] }
  ///
  /// Remaps to PHP bracket notation so the backend reads
  /// $this->input->post('product_id') as a proper array:
  ///   product_id[]=id1&product_id[]=id2
  Future<Map<String, dynamic>> copyInProducts(Map<String, dynamic> body) async {
    final ids = (body['product_id'] as List?) ?? [];
    if (ids.isEmpty) {
      return {'status': 'error', 'message': 'No products selected'};
    }

    // Build explicit bracket-notation form so PHP sees product_id as an array.
    final Map<String, dynamic> form = {};
    for (int i = 0; i < ids.length; i++) {
      form['product_id[$i]'] = ids[i]?.toString() ?? '';
    }

    final res = await _client.post(
      ApiEndpoints.postStockCopyInProducts,
      data: form,
      options: _formOptions,
    );
    return _json(res.data);
  }

  /// Create a product category (stock/category/create)
  Future<Map<String, dynamic>> createCategory(String name) async {
    final res = await _client.post(
      ApiEndpoints.postStockCategoryCreate,
      data: {'category': name},
      options: _formOptions,
    );
    return _json(res.data);
  }

  /// Bulk import products from parsed spreadsheet rows (stock/register/import).
  /// Backend reads 'products' as a JSON string from form post.
  Future<Map<String, dynamic>> importProducts(List<Map<String, dynamic>> products) async {
    // Map Flutter field names → backend field names
    final mapped = products.map((p) => {
      'name': p['name'],
      'bp': p['buyingPrice'] ?? 0,
      'sp': p['sellingPrice'] ?? 0,
      'wp': p['wholesalePrice'] ?? p['sellingPrice'] ?? 0,
      'quantity': p['quantity'] ?? 0,
      'reorder_level': p['reorderLevel'] ?? 0,
      if (p['barcode'] != null && (p['barcode'] as String).isNotEmpty) 'barcode': p['barcode'],
      if (p['expiryDate'] != null && (p['expiryDate'] as String).isNotEmpty) 'expiry_date': p['expiryDate'],
      if (p['unit'] != null) 'unit': p['unit'],
    }).toList();

    final res = await _client.post(
      ApiEndpoints.postStockRegisterImport,
      // Send products as a JSON-encoded string so backend json_decode() can read it
      data: {'products': jsonEncode(mapped)},
      options: _formOptions,
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
      options: _formOptions,
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
