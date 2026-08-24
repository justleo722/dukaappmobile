// test/online_shop_coupon_page_test.dart
import 'package:dukaapp/features/online_shop/presentation/pages/online_shop_add_coupon_page.dart';
import 'package:dukaapp/features/online_shop/presentation/pages/online_shop_coupon_codes_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('coupon codes page renders without crashing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OnlineShopCouponCodesPage(),
      ),
    );

    expect(find.text('Coupon Codes'), findsOneWidget);
    expect(find.text('Add Coupon'), findsOneWidget);
  });

  testWidgets('edit coupon page renders with existing coupon data', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnlineShopAddCouponPage(
          existingCoupon: {
            'id': 'CPN-001',
            'code': 'SAVE20',
            'discountType': 'Percentage',
            'discountValue': '20%',
            'minOrder': 'Tsh 50,000',
            'maxUses': '100',
            'usedCount': 45,
            'expiryDate': '2026-12-31',
            'status': 'Active',
          },
        ),
      ),
    );

    expect(find.text('Edit Coupon'), findsOneWidget);
    expect(find.text('SAVE20'), findsOneWidget);
  });
}
