import 'dart:convert';
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

  Future<StockState> refresh() => _fetchAndCache();

  Future<List<StockProduct>> fetchProducts() => _remote.fetchProducts();
  Future<List<Map<String, dynamic>>> fetchProductsByShop(String shopId) =>
      _remote.fetchProductsByShop(shopId);
  Future<List<StockCategory>> fetchCategories() => _remote.fetchCategories();
  Future<List<StockProduct>> fetchLowStock() => _remote.fetchLowStock();
  Future<List<StockProduct>> fetchExpiredStock() => _remote.fetchExpiredStock();

  // ── WRITE ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> body) =>
      _remote.createProduct(body);

  Future<Map<String, dynamic>> updateProduct(Map<String, dynamic> body) =>
      _remote.updateProduct(body);

  Future<Map<String, dynamic>> adjustStockBalance(Map<String, dynamic> body) =>
      _remote.adjustStockBalance(body);

  Future<List<Map<String, dynamic>>> fetchImportHistory() =>
      _remote.fetchImportHistory();

  Future<Map<String, dynamic>> importProducts(List<Map<String, dynamic>> products) =>
      _remote.importProducts(products);

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

  Future<StockState> _fetchAndCache() async {
    final results = await Future.wait([
      _remote.fetchStock(),
      _remote.fetchCategories(),
      _remote.fetchSummary(),
    ]);
    final state = StockState(
      products: results[0] as List<StockProduct>,
      categories: results[1] as List<StockCategory>,
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
