/// LocalDatabase
///
/// Manages SQLite databases with two modes:
///
///   1. **Authenticated** (after login):
///        db_{roleId}_{shopId}.db
///      One DB per (role, shop) pair — a user with 3 shops gets 3 separate DBs.
///      Switching shops closes the current DB and opens the right one.
///
///   2. **Public** (no login — online shop / browse mode):
///        db_public_{shopId}.db
///      Shared for any guest browsing that shop's online catalogue.
///      Safe to read without a token; never holds sensitive data.
///
/// Schema: single generic `cache` table.
/// ┌─────────────┬────────┬──────────────┬──────────────┬─────────────────┐
/// │  collection │  key   │    value     │  updated_at  │  expires_at     │
/// │  TEXT       │  TEXT  │  TEXT(JSON)  │  INTEGER(ms) │  INTEGER(ms)?   │
/// └─────────────┴────────┴──────────────┴──────────────┴─────────────────┘

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
// sqflite on Android/iOS initialises automatically — no databaseFactory setup needed.

class LocalDatabase {
  LocalDatabase._();

  static LocalDatabase? _instance;

  Database? _db;
  String? _currentRoleId; // null when in public mode
  String? _currentShopId;
  bool    _isPublic = false;

  // ── Singleton ─────────────────────────────────────────────────────────────

  static LocalDatabase get instance {
    _instance ??= LocalDatabase._();
    return _instance!;
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Open (or switch to) the authenticated database for [roleId] + [shopId].
  /// Safe to call multiple times — a no-op if already open for the same pair.
  Future<void> open(String roleId, String shopId) async {
    if (_db != null &&
        !_isPublic &&
        _currentRoleId == roleId &&
        _currentShopId == shopId) {
      return; // already open for this session
    }

    await close(); // close previous DB if any

    final dir  = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'db_${roleId}_$shopId.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    _currentRoleId = roleId;
    _currentShopId = shopId;
    _isPublic      = false;

    _log('Opened auth DB: db_${roleId}_$shopId.db');
  }

  /// Open (or switch to) the **public** database for [shopId].
  ///
  /// Used for the online-shop / browse mode when no user is logged in.
  /// File: db_public_{shopId}.db
  /// Never holds private user data.
  Future<void> openPublic(String shopId) async {
    if (_db != null && _isPublic && _currentShopId == shopId) {
      return; // already open
    }

    await close();

    final dir  = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'db_public_$shopId.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    _currentRoleId = null;
    _currentShopId = shopId;
    _isPublic      = true;

    _log('Opened public DB: db_public_$shopId.db');
  }

  /// Close the current database connection.
  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _log('Closed DB: $currentDbName');
    }
    _db            = null;
    _currentRoleId = null;
    _currentShopId = null;
    _isPublic      = false;
  }

  bool get isOpen    => _db != null && (_db?.isOpen ?? false);
  bool get isPublic  => _isPublic;
  bool get isPrivate => isOpen && !_isPublic;

  String? get currentShopId => _currentShopId;
  String? get currentRoleId => _currentRoleId;

  /// Filename of the currently open DB (for debugging).
  String? get currentDbName {
    if (!isOpen) return null;
    if (_isPublic) return 'db_public_$_currentShopId.db';
    return 'db_${_currentRoleId}_$_currentShopId.db';
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Get a single row. Returns null if not found or expired.
  Future<dynamic> get(String collection, String key) async {
    _assertOpen();
    final rows = await _db!.query(
      'cache',
      columns: ['value', 'expires_at'],
      where: 'collection = ? AND key = ?',
      whereArgs: [collection, key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;

    final expiresAt = row['expires_at'] as int?;
    if (expiresAt != null &&
        expiresAt < DateTime.now().millisecondsSinceEpoch) {
      await delete(collection, key); // prune expired
      return null;
    }

    return json.decode(row['value'] as String);
  }

  /// Get all rows in a collection as a list. Expired rows are skipped.
  Future<List<dynamic>> getAll(String collection) async {
    _assertOpen();
    final now  = DateTime.now().millisecondsSinceEpoch;
    final rows = await _db!.query(
      'cache',
      columns: ['value', 'expires_at'],
      where: 'collection = ? AND (expires_at IS NULL OR expires_at > ?)',
      whereArgs: [collection, now],
      orderBy: 'updated_at DESC',
    );
    return rows.map((r) => json.decode(r['value'] as String)).toList();
  }

  /// Get the stored-at timestamp for a collection+key (ms since epoch).
  /// Returns null if not in cache.
  Future<int?> updatedAt(String collection, String key) async {
    _assertOpen();
    final rows = await _db!.query(
      'cache',
      columns: ['updated_at'],
      where: 'collection = ? AND key = ?',
      whereArgs: [collection, key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['updated_at'] as int?;
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Save a value. [ttlSeconds] is optional; null means never expires.
  Future<void> put(
    String collection,
    String key,
    dynamic value, {
    int? ttlSeconds,
  }) async {
    _assertOpen();
    final now     = DateTime.now().millisecondsSinceEpoch;
    final expires = ttlSeconds != null ? now + ttlSeconds * 1000 : null;

    await _db!.insert(
      'cache',
      {
        'collection': collection,
        'key'       : key,
        'value'     : json.encode(value),
        'updated_at': now,
        'expires_at': expires,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Delete a single row.
  Future<void> delete(String collection, String key) async {
    _assertOpen();
    await _db!.delete(
      'cache',
      where: 'collection = ? AND key = ?',
      whereArgs: [collection, key],
    );
  }

  /// Delete all rows in a collection.
  Future<void> deleteCollection(String collection) async {
    _assertOpen();
    await _db!.delete(
      'cache',
      where: 'collection = ?',
      whereArgs: [collection],
    );
  }

  /// Delete all expired rows across all collections.
  Future<void> pruneExpired() async {
    _assertOpen();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db!.delete(
      'cache',
      where: 'expires_at IS NOT NULL AND expires_at < ?',
      whereArgs: [now],
    );
  }

  /// Wipe every row in the database (e.g. on logout or shop switch).
  Future<void> clearAll() async {
    _assertOpen();
    await _db!.delete('cache');
  }

  // ── Schema ────────────────────────────────────────────────────────────────

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cache (
        collection  TEXT    NOT NULL,
        key         TEXT    NOT NULL,
        value       TEXT    NOT NULL,
        updated_at  INTEGER NOT NULL,
        expires_at  INTEGER,
        PRIMARY KEY (collection, key)
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_cache_collection ON cache (collection)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_cache_expires ON cache (expires_at)',
    );
    _log('Schema created (v$version)');
  }

  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    // Add migration steps here as the schema evolves.
    _log('Schema upgraded $oldV → $newV');
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _assertOpen() {
    if (_db == null || !_db!.isOpen) {
      throw StateError(
        'LocalDatabase is not open. '
        'Call LocalDatabase.instance.open(roleId, shopId) after login.',
      );
    }
  }

  void _log(String msg) {
    if (kDebugMode) debugPrint('[LocalDB] $msg');
  }
}
