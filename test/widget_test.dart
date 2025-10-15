// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:mobileorder/app.dart';

void main() {
  testWidgets('Mobile Order App loads QR code scan prompt', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MobileOrderApp());

    // Verify that the home page shows QR code scan prompt
    expect(find.text('Please Scan QR Code'), findsOneWidget);
    expect(find.text('To access the menu and place your order, please scan the QR code at your table or at the counter.'), findsOneWidget);
  });
}
