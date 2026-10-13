import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/core/providers.dart';

class PaymentAccount {
  final String id;
  final String name;
  const PaymentAccount(this.id, this.name);
}

/// The shop's real payment accounts (Settings_model::payment_mode — the same list
/// the web uses). Receiving a payment needs a real account, so 'Credit' (11) is
/// left out unless [includeCredit] is set.
Future<List<PaymentAccount>> loadPaymentAccounts(WidgetRef ref, {bool includeCredit = false}) async {
  try {
    final res = await ref.read(apiServiceProvider).getPaymentMode();
    final body = res.data;
    final list = body is List ? body : (body is Map ? (body['data'] ?? []) : []);
    final out = <PaymentAccount>[];
    final seen = <String>{};
    for (final e in (list as List).whereType<Map>()) {
      final id = (e['account_id'] ?? '').toString();
      final name = (e['name'] ?? e['account_name'] ?? '').toString();
      if (id.isEmpty || name.isEmpty || !seen.add(id)) continue;
      if (!includeCredit && (id == '11' || name.toLowerCase() == 'credit')) continue;
      out.add(PaymentAccount(id, name));
    }
    return out;
  } catch (_) {
    return const [];
  }
}

/// Default selection: the "Cash" account, else the first one.
String? defaultPaymentAccountId(List<PaymentAccount> accounts) {
  if (accounts.isEmpty) return null;
  return accounts
      .firstWhere((a) => a.name.toLowerCase() == 'cash', orElse: () => accounts.first)
      .id;
}
