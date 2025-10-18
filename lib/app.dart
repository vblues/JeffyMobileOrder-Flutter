import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/store_locator_page.dart';
import 'presentation/pages/menu_page.dart';
import 'presentation/pages/cart_page.dart';
import 'presentation/pages/sales_type_page.dart';
import 'presentation/pages/payment_page.dart';

// Global RouteObserver for navigation tracking
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class MobileOrderApp extends StatelessWidget {
  const MobileOrderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mobile Order',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF996600), // Brand color from store config
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

final GoRouter _router = GoRouter(
  observers: [routeObserver],
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/locate/:storeId',
      builder: (context, state) {
        final storeId = state.pathParameters['storeId']!;
        return StoreLocatorPage(storeId: storeId);
      },
    ),
    GoRoute(
      path: '/menu',
      builder: (context, state) => const MenuPage(),
    ),
    GoRoute(
      path: '/cart',
      builder: (context, state) => const CartPage(),
    ),
    GoRoute(
      path: '/sales-type',
      builder: (context, state) => const SalesTypePage(),
    ),
    GoRoute(
      path: '/payment',
      builder: (context, state) => const PaymentPage(),
    ),
    // TODO: Add table service route in Phase 2
    // GoRoute(
    //   path: '/locate/:storeId/:sessionId',
    //   builder: (context, state) {
    //     final storeId = state.pathParameters['storeId']!;
    //     final sessionId = state.pathParameters['sessionId']!;
    //     return TableServicePage(storeId: storeId, sessionId: sessionId);
    //   },
    // ),
  ],
  errorBuilder: (context, state) => const Scaffold(
    body: Center(
      child: Text('Page not found'),
    ),
  ),
);
