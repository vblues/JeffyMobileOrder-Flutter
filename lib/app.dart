import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/store_locator_page.dart';

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
