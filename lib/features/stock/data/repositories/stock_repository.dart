import 'dart:convert';
import 'dart:io';
import 'package:dukaapp/core/database/database_service.dart';
import 'package:dukaapp/features/stock/data/datasources/stock_remote_datasource.dart';
import 'package:dukaapp/features/stock/data/models/stock_models.dart';

class StockRepository {
  final StockRemoteDatasource _remote;
  final DatabaseService _db;

  static const _col = 'stock';
  static const _keyState = 'state';

  StockRepository(this._remote, this._db);

  // ── READ ─────────────────────────────────────────────────────────────────

  Future<StockState> loadOfflineFirst({void Function(StockState)? onUpdate}) async {
    final cached = await _getCached();
    if (cached != null) {
      _fetchAndCache().then((fresh) => onUpdate?.call(fresh)).catchError((_) {});
      return cached;
    }
    return _fetchAndCache();
  }

  Future<StockState> refresh({String? from, String? to}) => _fetchAndCache(from: from, to: to);

  Future<List<StockProduct>> fetchProducts() => _remote.fetchProducts();
  Future<List<Map<String, dynamic>>> fetchProductsByShop(String shopId) =>
      _remote.fetchProductsByShop(shopId);
  Future<List<StockCategory>> fetchCategories() => _remote.fetchCategories();
  Future<List<StockProduct>> fetchLowStock() => _remote.fetchLowStock();
  Future<List<Map<String, dynamic>>> fetchReportRows(String method, {String? from, String? to}) =>
      _remote.fetchReportRows(method, from: from, to: to);
  Future<List<StockProduct>> fetchExpiredStock() => _remote.fetchExpiredStock();
  Future<List<StockProduct>> fetchAboutToExpireStock() => _remote.fetchAboutToExpireStock();

  // ── WRITE ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> body, {List<File>? photos}) =>
      _remote.createProduct(body, photos: photos);

  Future<Map<String, dynamic>> updateProduct(Map<String, dynamic> body, {List<File>? photos}) =>
      _remote.updateProduct(body, photos: photos);

  Future<Map<String, dynamic>> adjustStockBalance(Map<String, dynamic> body) =>
      _remote.adjustStockBalance(body);

  Future<List<Map<String, dynamic>>> fetchImportHistory() =>
      _remote.fetchImportHistory();

  Future<List<List<dynamic>>> parseSpreadsheet(List<int> bytes, String fileName) =>
      _remote.parseSpreadsheet(bytes, fileName);

  Future<Map<String, dynamic>> importProducts(List<Map<String, dynamic>> products, {String? categoryId}) =>
      _remote.importProducts(products, categoryId: categoryId);

  Future<Map<String, dynamic>> createRestock(Map<String, dynamic> body) =>
      _remote.createRestock(body);

  Future<Map<String, dynamic>> transferStock(Map<String, dynamic> body) =>
      _remote.transferStock(body);

  Future<Map<String, dynamic>> copyInProducts(Map<String, dynamic> body) =>
      _remote.copyInProducts(body);

  Future<Map<String, dynamic>> createCategory(String name) =>
      _remote.createCategory(name);

  Future<Map<String, dynamic>> bulkDeleteProducts(List<dynamic> ids) =>
      _remote.bulkDeleteProducts(ids);

  // ── CACHE ────────────────────────────────────────────────────────────────

  Future<StockState> _fetchAndCache({String? from, String? to}) async {
    final results = await Future.wait([
      _remote.fetchStock(from: from, to: to),
      _remote.fetchCategories(),
      _remote.fetchSummary(from: from, to: to),
    ]);
    // The backend can return the same category name more than once (it was
    // created twice). Dropdowns built from this list assert unique values,
    // so keep only the first entry of each name.
    final rawCategories = results[1] as List<StockCategory>;
    final seenCategoryNames = <String>{};
    final categories = rawCategories
        .where((c) => seenCategoryNames.add(c.name.trim().toLowerCase()))
        .toList();
    final state = StockState(
      products: results[0] as List<StockProduct>,
      categories: categories,
      summary: results[2] as StockValueSummary,
    );
    // Only cache if DB is open (guard against StateError on cold start)
    if (_db.isOpen) {
      try {
        await _db.put(_col, _keyState, jsonEncode(state.toJson()));
      } catch (_) {/* ignore cache write failures */}
    }
    return state;
  }

  Future<StockState?> _getCached() async {
    // Skip cache read entirely if DB is not open yet
    if (!_db.isOpen) return null;
    try {
      final raw = await _db.get(_col, _keyState);
      if (raw == null) return null;
      final json = raw is String ? jsonDecode(raw) : raw;
      return StockState.fromCache(json as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
