import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global date-range filter used across the entire app.
///
/// Every page that fetches time-scoped data (sales, stock, expenses, …)
/// watches this provider and reloads when the user changes the filter.
///
/// Usage in a ConsumerStatefulWidget:
///
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   ref.listen(filterProvider, (_, __) => _loadData());
///   // …
/// }
/// ```
///
/// Usage in a ConsumerWidget:
///
/// ```dart
/// final filter = ref.watch(filterProvider);
/// // pass filter.from / filter.to to your API call
/// ```

// ── Filter state ─────────────────────────────────────────────────────────────

class FilterState {
  final String key;   // 'today' | 'yesterday' | 'this_week' | … | 'custom'
  final String from;  // 'yyyy-MM-dd'
  final String to;    // 'yyyy-MM-dd'
  final String label; // Human-readable: 'Today', 'This Week', …
  /// Custom range time of day ('HH:mm'), empty = whole day. Sales use it.
  final String fromTime;
  final String toTime;

  /// Times of the active filter, read by the API client (no ref there) to add
  /// from_time / to_time to requests that carry this filter's from/to.
  static String activeFrom = '', activeTo = '', activeFromTime = '', activeToTime = '';

  const FilterState({
    required this.key,
    required this.from,
    required this.to,
    required this.label,
    this.fromTime = '',
    this.toTime = '',
  });

  /// Default: Today
  static FilterState get defaultFilter {
    final today = _fmt(DateTime.now());
    return FilterState(key: 'today', from: today, to: today, label: 'Today');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterState &&
          key == other.key &&
          from == other.from &&
          to == other.to &&
          fromTime == other.fromTime &&
          toTime == other.toTime;

  @override
  int get hashCode => Object.hash(key, from, to, fromTime, toTime);
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class FilterNotifier extends Notifier<FilterState> {
  @override
  FilterState build() => FilterState.defaultFilter;

  @override
  set state(FilterState value) {
    super.state = value;
    FilterState.activeFrom = value.from;
    FilterState.activeTo = value.to;
    FilterState.activeFromTime = value.fromTime;
    FilterState.activeToTime = value.toTime;
  }

  /// Apply a named preset filter key.
  void applyPreset(String key) {
    state = _fromKey(key);
  }

  /// Apply a custom date range.
  /// [fromTime]/[toTime] are 'HH:mm' or empty for the whole day.
  void applyCustom(DateTime from, DateTime to, {String fromTime = '', String toTime = ''}) {
    String part(String d, String t) => t.isEmpty ? d : '$d $t';
    state = FilterState(
      key: 'custom',
      from: _fmt(from),
      to: _fmt(to),
      fromTime: fromTime,
      toTime: toTime,
      label: '${part(_fmt(from), fromTime)} → ${part(_fmt(to), toTime)}',
    );
  }

  /// Reset to Today.
  void reset() {
    state = FilterState.defaultFilter;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static FilterState _fromKey(String key) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (key) {
      case 'today':
        final s = _fmt(today);
        return FilterState(key: key, from: s, to: s, label: 'Today');

      case 'yesterday':
        final d = today.subtract(const Duration(days: 1));
        final s = _fmt(d);
        return FilterState(key: key, from: s, to: s, label: 'Yesterday');

      case 'this_week':
      case 'thisweek':
        final monday = today.subtract(Duration(days: today.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return FilterState(
          key: key,
          from: _fmt(monday),
          to: _fmt(sunday.isAfter(today) ? today : sunday),
          label: 'This Week',
        );

      case 'last_week':
        final lastMonday = today.subtract(Duration(days: today.weekday + 6));
        final lastSunday = lastMonday.add(const Duration(days: 6));
        return FilterState(
          key: key,
          from: _fmt(lastMonday),
          to: _fmt(lastSunday),
          label: 'Last Week',
        );

      case 'this_month':
      case 'thismonth':
        final first = DateTime(today.year, today.month, 1);
        return FilterState(
          key: key,
          from: _fmt(first),
          to: _fmt(today),
          label: 'This Month',
        );

      case 'last_month':
        final first = DateTime(today.year, today.month - 1, 1);
        final last = DateTime(today.year, today.month, 0);
        return FilterState(
          key: key,
          from: _fmt(first),
          to: _fmt(last),
          label: 'Last Month',
        );

      case 'last_3_months':
      case 'last_three_months':
        final from = DateTime(today.year, today.month - 2, 1);
        return FilterState(
          key: key,
          from: _fmt(from),
          to: _fmt(today),
          label: 'Last 3 Months',
        );

      case 'this_year':
      case 'thisyear':
        final first = DateTime(today.year, 1, 1);
        return FilterState(
          key: key,
          from: _fmt(first),
          to: _fmt(today),
          label: 'This Year',
        );

      case 'all_time':
        return FilterState(
          key: key,
          from: '1990-01-01',
          to: _fmt(today),
          label: 'All Time',
        );

      default:
        final s = _fmt(today);
        return FilterState(key: 'today', from: s, to: s, label: 'Today');
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final filterProvider = NotifierProvider<FilterNotifier, FilterState>(
  FilterNotifier.new,
);

// ── Utility ───────────────────────────────────────────────────────────────────

String _fmt(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
