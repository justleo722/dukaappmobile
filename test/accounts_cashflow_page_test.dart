// test/accounts_cashflow_page_test.dart
import 'package:dukaapp/features/accounts/presentation/pages/accounts_cashflow_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Accounts cashflow page renders without layout exceptions', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AccountsCashflowPage()));
    expect(find.text('Accounts and Cashflow'), findsOneWidget);
  });
}
