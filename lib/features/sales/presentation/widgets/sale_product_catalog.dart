import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';

/// Every product listed inline with an editable price, `- qty +` and a
/// per-item discount, as on Add Sale. Used by Create Invoice and Add Order.
///
/// [products] are catalog entries (product_id, stock_id, name, sellingPrice,
/// wholesalePrice, stock, type, unit, barcode). [items] is the page's cart and
/// is changed in place; [onChanged] runs after every change so the page can
/// rebuild its totals. Cart entries use the keys the pages already save:
/// product_id, stock_id, name, sellingPrice, wholesalePrice, quantity, stock,
/// discount, type.
class SaleProductCatalog extends StatefulWidget {
  const SaleProductCatalog({
    super.key,
    required this.products,
    required this.items,
    required this.onChanged,
    this.isWholesale = false,
    this.limitToStock = true,
    this.emptyMessage = 'No products match your search',
  });

  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> items;
  final VoidCallback onChanged;
  final bool isWholesale;

  /// False for invoices: they don't deduct stock, so quantity isn't capped.
  final bool limitToStock;
  final String emptyMessage;

  @override
  State<SaleProductCatalog> createState() => _SaleProductCatalogState();
}

class _SaleProductCatalogState extends State<SaleProductCatalog> {
  final Map<String, TextEditingController> _priceControllers = {};
  final Map<String, TextEditingController> _qtyControllers = {};

  static const int _noLimit = 1 << 30;

  @override
  void didUpdateWidget(covariant SaleProductCatalog oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Prices are kept per mode, so re-point the price fields when it flips.
    if (oldWidget.isWholesale != widget.isWholesale) _syncPriceControllers();
    // The cart may have been changed by the page (barcode scan, edit prefill).
    for (final id in _qtyControllers.keys) {
      _syncQty(id);
    }
  }

  @override
  void dispose() {
    for (final c in _priceControllers.values) {
      c.dispose();
    }
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _id(Map<String, dynamic> m) => (m['product_id'] ?? '').toString();

  String _money(double v) => NumberFormat('#,###').format(v);

  double _num(dynamic v) => (v as num?)?.toDouble() ?? 0;

  int _cartIndex(String id) => widget.items.indexWhere((it) => _id(it) == id);

  int _maxQty(Map<String, dynamic> product) {
    if (!widget.limitToStock || product['type'] == 'service') return _noLimit;
    return (product['stock'] as num?)?.toInt() ?? 0;
  }

  double _itemPrice(Map<String, dynamic> item) {
    if (widget.isWholesale) {
      return (item['wholesalePrice'] as num?)?.toDouble() ?? _num(item['sellingPrice']);
    }
    return _num(item['sellingPrice']);
  }

  double _lineTotal(Map<String, dynamic> item) =>
      _itemPrice(item) * (((item['quantity'] as num?) ?? 1).toInt());

  double _lineDiscount(Map<String, dynamic> item) {
    final d = _num(item['discount']);
    final total = _lineTotal(item);
    return d < 0 ? 0 : (d > total ? total : d);
  }

  double? _displayPrice(Map<String, dynamic> product) {
    final idx = _cartIndex(_id(product));
    if (idx >= 0) return _itemPrice(widget.items[idx]);
    if (widget.isWholesale) {
      return (product['wholesalePrice'] as num?)?.toDouble() ??
          (product['sellingPrice'] as num?)?.toDouble();
    }
    return (product['sellingPrice'] as num?)?.toDouble();
  }

  TextEditingController _priceController(Map<String, dynamic> product) =>
      _priceControllers.putIfAbsent(
        _id(product),
        () => TextEditingController(text: _displayPrice(product)?.toStringAsFixed(0) ?? '0'),
      );

  TextEditingController _qtyController(Map<String, dynamic> product) {
    final id = _id(product);
    return _qtyControllers.putIfAbsent(id, () {
      final idx = _cartIndex(id);
      return TextEditingController(text: idx >= 0 ? '${widget.items[idx]['quantity']}' : '0');
    });
  }

  void _syncQty(String id) {
    final c = _qtyControllers[id];
    if (c == null) return;
    final idx = _cartIndex(id);
    final text = idx >= 0 ? '${widget.items[idx]['quantity']}' : '0';
    if (c.text != text) c.text = text;
  }

  void _syncPriceControllers() {
    for (final entry in _priceControllers.entries) {
      Map<String, dynamic>? product;
      for (final p in widget.products) {
        if (_id(p) == entry.key) {
          product = p;
          break;
        }
      }
      final idx = _cartIndex(entry.key);
      final price = idx >= 0
          ? _itemPrice(widget.items[idx])
          : (product == null ? null : _displayPrice(product));
      if (price != null) {
        final text = price.toStringAsFixed(0);
        if (entry.value.text != text) entry.value.text = text;
      }
    }
  }

  void _changed() {
    setState(() {});
    widget.onChanged();
  }

  void _clampDiscount(int idx) {
    widget.items[idx]['discount'] = _lineDiscount(widget.items[idx]);
  }

  void _add(Map<String, dynamic> product) {
    final id = _id(product);
    final idx = _cartIndex(id);
    if (idx >= 0) {
      final qty = (widget.items[idx]['quantity'] as num?)?.toInt() ?? 0;
      if (qty < _maxQty(product)) {
        widget.items[idx]['quantity'] = qty + 1;
        _clampDiscount(idx);
      }
    } else {
      if (_maxQty(product) <= 0) return;
      final selling = _num(product['sellingPrice']);
      widget.items.add({
        'product_id': product['product_id'],
        'stock_id': product['stock_id'],
        'name': product['name'],
        'sellingPrice': selling,
        'wholesalePrice': (product['wholesalePrice'] as num?)?.toDouble() ?? selling,
        'quantity': 1,
        'stock': _maxQty(product),
        'discount': 0.0,
        'type': product['type'] ?? 'product',
      });
    }
    _syncQty(id);
    _changed();
  }

  void _remove(Map<String, dynamic> product) {
    final id = _id(product);
    final idx = _cartIndex(id);
    if (idx < 0) return;
    final qty = (widget.items[idx]['quantity'] as num?)?.toInt() ?? 1;
    if (qty <= 1) {
      widget.items.removeAt(idx);
    } else {
      widget.items[idx]['quantity'] = qty - 1;
      _clampDiscount(idx);
    }
    _syncQty(id);
    _changed();
  }

  void _setQty(Map<String, dynamic> product, String value) {
    final id = _id(product);
    final parsed = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    var idx = _cartIndex(id);
    if (parsed == null || parsed <= 0) {
      // Cleared / zero → take it out of the cart.
      if (idx >= 0) widget.items.removeAt(idx);
    } else {
      final max = _maxQty(product);
      final q = parsed > max ? max : parsed;
      if (idx < 0) {
        _add(product);
        idx = _cartIndex(id);
      }
      if (idx >= 0) {
        widget.items[idx]['quantity'] = q;
        _clampDiscount(idx);
      }
    }
    _syncQty(id);
    _changed();
  }

  void _setPrice(Map<String, dynamic> product, String value) {
    final parsed = double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (parsed == null) return;
    var idx = _cartIndex(_id(product));
    if (idx < 0) {
      _add(product);
      idx = _cartIndex(_id(product));
    }
    if (idx < 0) return;
    widget.items[idx][widget.isWholesale ? 'wholesalePrice' : 'sellingPrice'] = parsed;
    _clampDiscount(idx);
    _changed();
  }

  Future<void> _editDiscount(Map<String, dynamic> product) async {
    // Discounting implies selling: add to the cart first if needed.
    var idx = _cartIndex(_id(product));
    if (idx < 0) {
      _add(product);
      idx = _cartIndex(_id(product));
    }
    if (idx < 0) return;
    final item = widget.items[idx];
    final lineTotal = _lineTotal(item);
    final current = _lineDiscount(item);
    final controller = TextEditingController(text: current > 0 ? current.toStringAsFixed(0) : '');
    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMD)),
        title: Text('Discount: ${item['name'] ?? ''}', style: AppTypography.h6),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixText: 'Tsh ',
            helperText: 'Max: Tsh ${_money(lineTotal)}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              double.tryParse(controller.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0,
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || !mounted) return;
    final i = _cartIndex(_id(product));
    if (i < 0) return;
    widget.items[i]['discount'] = result;
    _clampDiscount(i);
    _changed();
  }

  Widget _stockBadge(Map<String, dynamic> product) {
    final isService = product['type'] == 'service';
    final stock = (product['stock'] as num?)?.toInt() ?? 0;
    final unit = product['unit']?.toString() ?? '';
    Color color;
    String text;
    if (isService) {
      color = AppColors.primary;
      text = 'Service';
    } else if (stock <= 0) {
      color = widget.limitToStock ? AppColors.danger : AppColors.warning;
      text = 'Out of stock';
    } else {
      color = AppColors.success;
      text = 'Qty: $stock${unit.isNotEmpty ? ' $unit' : ''}';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(text, style: AppTypography.captionBold.copyWith(fontSize: 10, color: color)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.products;
    if (products.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 32, color: AppColors.textHint),
            const SizedBox(height: 8),
            Text(widget.emptyMessage,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (final product in products) _row(product),
      ],
    );
  }

  Widget _row(Map<String, dynamic> product) {
    final idx = _cartIndex(_id(product));
    final item = idx >= 0 ? widget.items[idx] : null;
    final qty = item == null ? 0 : ((item['quantity'] as num?)?.toInt() ?? 0);
    final canAdd = item == null ? _maxQty(product) > 0 : qty < _maxQty(product);
    final discount = item == null ? 0.0 : _lineDiscount(item);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          border: Border.all(color: qty > 0 ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(product['name']?.toString() ?? '',
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                _stockBadge(product),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  widget.isWholesale ? 'WP: ' : 'SP: ',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 9),
                ),
                SizedBox(
                  width: 90,
                  height: 24,
                  child: TextField(
                    controller: _priceController(product),
                    keyboardType: TextInputType.number,
                    style: AppTypography.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => _setPrice(product, v),
                  ),
                ),
                const SizedBox(width: 8),
                if (item != null)
                  Text(
                    'Tsh ${_money(_lineTotal(item) - discount)}',
                    style: AppTypography.captionBold.copyWith(fontSize: 10, color: AppColors.textPrimary),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: qty > 0 ? () => _remove(product) : null,
                ),
                SizedBox(
                  width: 48,
                  height: 32,
                  child: TextField(
                    controller: _qtyController(product),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: AppTypography.bodyMedium,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => _setQty(product, v),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                  onPressed: canAdd ? () => _add(product) : null,
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _editDiscount(product),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: discount > 0 ? AppColors.dangerLight.withValues(alpha: 0.5) : AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: discount > 0 ? AppColors.danger.withValues(alpha: 0.3) : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.discount_rounded,
                            size: 12, color: discount > 0 ? AppColors.danger : AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          discount > 0 ? _money(discount) : 'Discount',
                          style: AppTypography.caption.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: discount > 0 ? AppColors.danger : AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
