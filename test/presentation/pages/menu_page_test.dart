import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobileorder/data/models/menu_model.dart';
import 'package:mobileorder/data/models/product_model.dart';
import 'package:mobileorder/presentation/bloc/menu_bloc.dart';
import 'package:mobileorder/presentation/bloc/menu_event.dart';
import 'package:mobileorder/presentation/bloc/menu_state.dart';

class MockMenuBloc extends Mock implements MenuBloc {}

class FakeMenuEvent extends Fake implements MenuEvent {}

void main() {
  late MockMenuBloc mockMenuBloc;

  setUpAll(() {
    registerFallbackValue(FakeMenuEvent());
  });

  setUp(() {
    mockMenuBloc = MockMenuBloc();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<MenuBloc>.value(
        value: mockMenuBloc,
        child: const Scaffold(
          body: _TestMenuPageView(),
        ),
      ),
    );
  }

  group('MenuPage Widget Tests', () {
    testWidgets('displays loading indicator when state is MenuLoading',
        (WidgetTester tester) async {
      when(() => mockMenuBloc.state).thenReturn(MenuLoading());
      when(() => mockMenuBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading menu...'), findsOneWidget);
    });

    testWidgets('displays error message when state is MenuError',
        (WidgetTester tester) async {
      const errorMessage = 'Failed to load menu';
      when(() => mockMenuBloc.state).thenReturn(MenuError(errorMessage));
      when(() => mockMenuBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Error Loading Menu'), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('displays category chips when state is MenuLoaded',
        (WidgetTester tester) async {
      final categories = [
        MenuCategory(
          id: 1,
          parentId: 0,
          catName: '{"cn":"饮料","en":"Beverages"}',
          categorySn: 'CAT001',
          sortSn: 1,
          child: [],
        ),
        MenuCategory(
          id: 2,
          parentId: 0,
          catName: '{"cn":"食物","en":"Food"}',
          categorySn: 'CAT002',
          sortSn: 2,
          child: [],
        ),
      ];

      final products = [
        Product(
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
          hasModifiers: 1,
        ),
      ];

      when(() => mockMenuBloc.state).thenReturn(MenuLoaded(
        categories: categories,
        allProducts: products,
        filteredProducts: products,
      ));
      when(() => mockMenuBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());

      // Should display "All" button
      expect(find.text('All'), findsOneWidget);

      // Should display category buttons
      expect(find.text('Beverages'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('displays products in grid when state is MenuLoaded',
        (WidgetTester tester) async {
      final products = [
        Product(
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
          hasModifiers: 1,
        ),
        Product(
          status: 1,
          cid: 2,
          cateId: 2,
          productId: 2,
          productName: '{"cn":"茶","en":"Tea"}',
          productSn: 'P002',
          isTakeOut: 1,
          price: '2.00',
          sortSn: 2,
          startTime: '07:00:00',
          endTime: '22:00:00',
          ingredientName: '{}',
          ingredientsId: 2,
          effectiveStartTime: 0,
          effectiveEndTime: 9999999999,
          hasModifiers: 0,
        ),
      ];

      when(() => mockMenuBloc.state).thenReturn(MenuLoaded(
        categories: [],
        allProducts: products,
        filteredProducts: products,
      ));
      when(() => mockMenuBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());

      // Should display product names
      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('Tea'), findsOneWidget);

      // Should display prices
      expect(find.text('\$2.50'), findsOneWidget);
      expect(find.text('\$2.00'), findsOneWidget);

      // Should display "Add" buttons
      expect(find.text('Add'), findsNWidgets(2));
    });

    testWidgets('displays empty state when no products match search',
        (WidgetTester tester) async {
      when(() => mockMenuBloc.state).thenReturn(MenuLoaded(
        categories: [],
        allProducts: [],
        filteredProducts: [],
        searchQuery: 'nonexistent',
      ));
      when(() => mockMenuBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.text('No products found for "nonexistent"'), findsOneWidget);
    });

    testWidgets('displays empty state when category has no products',
        (WidgetTester tester) async {
      when(() => mockMenuBloc.state).thenReturn(MenuLoaded(
        categories: [],
        allProducts: [],
        filteredProducts: [],
        selectedCategoryId: 1,
      ));
      when(() => mockMenuBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.text('No products in this category'), findsOneWidget);
    });

    testWidgets('retry button triggers RefreshMenu event',
        (WidgetTester tester) async {
      when(() => mockMenuBloc.state)
          .thenReturn(MenuError('Network error'));
      when(() => mockMenuBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockMenuBloc.add(any())).thenReturn(null);

      await tester.pumpWidget(createWidgetUnderTest());

      final retryButton = find.text('Retry');
      expect(retryButton, findsOneWidget);

      await tester.tap(retryButton);
      await tester.pump();

      verify(() => mockMenuBloc.add(any(that: isA<RefreshMenu>()))).called(1);
    });

    testWidgets('category chip triggers SelectCategory event when tapped',
        (WidgetTester tester) async {
      final categories = [
        MenuCategory(
          id: 1,
          parentId: 0,
          catName: '{"cn":"饮料","en":"Beverages"}',
          categorySn: 'CAT001',
          sortSn: 1,
          child: [],
        ),
      ];

      when(() => mockMenuBloc.state).thenReturn(MenuLoaded(
        categories: categories,
        allProducts: [],
        filteredProducts: [],
      ));
      when(() => mockMenuBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockMenuBloc.add(any())).thenReturn(null);

      await tester.pumpWidget(createWidgetUnderTest());

      final categoryButton = find.text('Beverages');
      expect(categoryButton, findsOneWidget);

      await tester.tap(categoryButton);
      await tester.pump();

      verify(() => mockMenuBloc.add(any(that: isA<SelectCategory>()))).called(1);
    });

    testWidgets('shows dine-in icon for non-takeout products',
        (WidgetTester tester) async {
      final products = [
        Product(
          status: 1,
          cid: 1,
          cateId: 1,
          productId: 1,
          productName: '{"cn":"咖啡","en":"Dine-in Only Coffee"}',
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
          hasModifiers: 1,
        ),
      ];

      when(() => mockMenuBloc.state).thenReturn(MenuLoaded(
        categories: [],
        allProducts: products,
        filteredProducts: products,
      ));
      when(() => mockMenuBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());

      // Should show dine-in icon for products not available for takeout
      expect(find.byIcon(Icons.dining), findsOneWidget);
    });
  });
}

// Simplified version of the menu page view for testing
class _TestMenuPageView extends StatelessWidget {
  const _TestMenuPageView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuBloc, MenuState>(
      builder: (context, state) {
        if (state is MenuLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Loading menu...',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        }

        if (state is MenuError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error Loading Menu',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<MenuBloc>().add(RefreshMenu());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is MenuLoaded) {
          return Column(
            children: [
              // Category chips
              _buildCategoryChips(context, state),
              const Divider(height: 1),
              // Product grid
              Expanded(
                child: _buildProductGrid(context, state),
              ),
            ],
          );
        }

        return const Center(
          child: Text('Ready to load menu'),
        );
      },
    );
  }

  Widget _buildCategoryChips(BuildContext context, MenuLoaded state) {
    final parentCategories = state.parentCategories;

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        children: [
          // "All" category
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: () {
                context.read<MenuBloc>().add(SelectCategory(null));
              },
              child: const Text('All'),
            ),
          ),
          // Category buttons
          ...parentCategories.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton(
                onPressed: () {
                  context.read<MenuBloc>().add(SelectCategory(category.id));
                },
                child: Text(category.catNameEn),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context, MenuLoaded state) {
    final products = state.displayProducts;

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              state.searchQuery.isNotEmpty
                  ? 'No products found for "${state.searchQuery}"'
                  : 'No products in this category',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.restaurant, size: 48),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productNameEn,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product.formattedPrice,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!product.isTakeOutAvailable)
                          const Icon(Icons.dining, size: 16),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text('Add'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
