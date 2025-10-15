import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobileorder/data/models/product_model.dart';
import 'package:mobileorder/presentation/pages/product_detail_page.dart';

void main() {
  group('ProductDetailPage Widget Tests', () {
    late Product testProduct;

    setUp(() {
      testProduct = Product(
        status: 1,
        cid: 1,
        cateId: 1,
        productPic: 'https://example.com/coffee.jpg',
        productId: 1,
        productName: '{"cn":"拿铁咖啡","en":"Latte Coffee"}',
        note: 'A delicious creamy latte with smooth espresso and steamed milk',
        productSn: 'P001',
        isTakeOut: 1,
        price: '4.50',
        sortSn: 1,
        startTime: '07:00:00',
        endTime: '22:00:00',
        ingredientName: '{"cn":"咖啡","en":"Coffee"}',
        ingredientsId: 1,
        effectiveStartTime: 0,
        effectiveEndTime: 9999999999,
        hasModifiers: 1,
      );
    });

    testWidgets('displays product name correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailPage(product: testProduct),
        ),
      );

      expect(find.text('Latte Coffee'), findsOneWidget);
    });

    testWidgets('displays product price correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailPage(product: testProduct),
        ),
      );

      expect(find.text('\$4.50'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays product description when available',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailPage(product: testProduct),
        ),
      );

      expect(find.text('Description'), findsOneWidget);
      expect(
        find.text(
            'A delicious creamy latte with smooth espresso and steamed milk'),
        findsOneWidget,
      );
    });

    testWidgets('does not display description section when note is null',
        (WidgetTester tester) async {
      final productWithoutNote = Product(
        status: 1,
        cid: 1,
        cateId: 1,
        productId: 1,
        productName: '{"cn":"咖啡","en":"Coffee"}',
        note: null,
        productSn: 'P001',
        isTakeOut: 1,
        price: '2.50',
        sortSn: 1,
        startTime: '07:00:00',
        endTime: '22:00:00',
        ingredientName: '{}',
        ingredientsId: 1,
        effectiveStartTime: 0,
        effectiveEndTime: 9999999999,
        hasModifiers: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailPage(product: productWithoutNote),
        ),
      );

      expect(find.text('Description'), findsNothing);
    });

    testWidgets('displays category information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailPage(product: testProduct),
        ),
      );

      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Coffee'), findsOneWidget);
    });

    testWidgets('displays service type as Takeaway when available',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailPage(product: testProduct),
        ),
      );

      expect(find.text('Service'), findsOneWidget);
      expect(find.text('Takeaway'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag), findsOneWidget);
    });

    testWidgets('displays service type as Dine-in only when not available for takeout',
        (WidgetTester tester) async {
      final dineInProduct = Product(
        status: 1,
        cid: 1,
        cateId: 1,
        productId: 1,
        productName: '{"cn":"咖啡","en":"Coffee"}',
        productSn: 'P001',
        isTakeOut: 0, // Not available for takeout
        price: '2.50',
        sortSn: 1,
        startTime: '07:00:00',
        endTime: '22:00:00',
        ingredientName: '{}',
        ingredientsId: 1,
        effectiveStartTime: 0,
        effectiveEndTime: 9999999999,
        hasModifiers: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailPage(product: dineInProduct),
        ),
      );

      expect(find.text('Dine-in only'), findsOneWidget);
      expect(find.byIcon(Icons.dining), findsOneWidget);
    });

    testWidgets('displays availability times', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailPage(product: testProduct),
        ),
      );

      expect(find.text('Available'), findsOneWidget);
      expect(find.text('07:00 - 22:00'), findsOneWidget);
    });

    testWidgets('displays modifiers info when product has modifiers',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailPage(product: testProduct),
        ),
      );

      expect(
        find.text('This product has customization options available.'),
        findsOneWidget,
      );
    });

    testWidgets('does not display modifiers info when product has no modifiers',
        (WidgetTester tester) async {
      final productWithoutModifiers = Product(
        status: 1,
        cid: 1,
        cateId: 1,
        productId: 1,
        productName: '{"cn":"咖啡","en":"Coffee"}',
        productSn: 'P001',
        isTakeOut: 1,
        price: '2.50',
        sortSn: 1,
        startTime: '07:00:00',
        endTime: '22:00:00',
        ingredientName: '{}',
        ingredientsId: 1,
        effectiveStartTime: 0,
        effectiveEndTime: 9999999999,
        hasModifiers: 0, // No modifiers
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailPage(product: productWithoutModifiers),
        ),
      );

      expect(
        find.text('This product has customization options available.'),
        findsNothing,
      );
    });

    testWidgets('initial quantity is 1', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailPage(product: testProduct),
        ),
      );

      expect(find.text('Quantity'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('has increment and decrement buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailPage(product: testProduct),
        ),
      );

      expect(find.byIcon(Icons.add_circle), findsOneWidget);
      expect(find.byIcon(Icons.remove_circle), findsOneWidget);
    });

    testWidgets('displays Add to Cart button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailPage(product: testProduct),
        ),
      );

      expect(find.text('Add to Cart'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
    });

    testWidgets('displays Total label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailPage(product: testProduct),
        ),
      );

      expect(find.text('Total'), findsOneWidget);
    });

    testWidgets('app bar has back button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailPage(product: testProduct),
        ),
      );

      // Verify back button exists in app bar
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('scrollable content works correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailPage(product: testProduct),
        ),
      );

      // Verify the page has scrollable content
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // Initially, Add to Cart button should be visible (at bottom)
      expect(find.text('Add to Cart'), findsOneWidget);
    });
  });
}
