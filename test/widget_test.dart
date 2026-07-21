import 'package:flutter_test/flutter_test.dart';
import 'package:dukaapp/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DukaApp());
    expect(find.text('Welcome Back!'), findsOneWidget);
  });
}
