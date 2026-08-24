// test/online_shop_drawer_route_test.dart
import 'package:dukaapp/app/app.dart';
import 'package:dukaapp/app/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opening coupons via online shop drawer does not hang', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DukaApp(),
      ),
    );

    final router = ProviderScope.containerOf(
      tester.element(find.byType(DukaApp)),
      listen: false,
    ).read(appRouterProvider);

    router.go('/online-shop');
    await tester.pumpAndSettle();

    expect(find.text('Online Shop Dashboard'), findsOneWidget);

    final drawerButton = find.byIcon(Icons.menu_rounded);
    expect(drawerButton, findsWidgets);
    await tester.tap(drawerButton.first);
    await tester.pumpAndSettle();

    final couponsItem = find.text('Coupons');
    expect(couponsItem, findsOneWidget);
    await tester.tap(couponsItem);
    await tester.pumpAndSettle();

    expect(find.text('Coupon Codes'), findsOneWidget);
  });
}
