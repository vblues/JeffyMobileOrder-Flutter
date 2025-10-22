import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/store_locator_page.dart';
import 'presentation/pages/menu_page.dart';
import 'presentation/pages/cart_page.dart';
import 'presentation/pages/sales_type_page.dart';
import 'presentation/pages/payment_page.dart';
import 'presentation/pages/order_history_page.dart';
import 'presentation/bloc/cart_bloc.dart';
import 'presentation/bloc/menu_bloc.dart';
import 'presentation/bloc/menu_event.dart';
import 'data/repositories/cart_repository_impl.dart';
import 'data/repositories/menu_repository_impl.dart';
import 'data/datasources/menu_remote_datasource.dart';
import 'data/models/store_credentials_model.dart';
import 'core/constants/storage_keys.dart';

// Global RouteObserver for navigation tracking
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class MobileOrderApp extends StatelessWidget {
  final SharedPreferences sharedPreferences;

  const MobileOrderApp({super.key, required this.sharedPreferences});

  MenuBloc? _createMenuBlocIfCredentialsExist() {
    try {
      final credentialsJson = sharedPreferences.getString(StorageKeys.storeCredentials);
      final storeInfoJson = sharedPreferences.getString(StorageKeys.storeInfo);

      if (credentialsJson == null || storeInfoJson == null) {
        return null;
      }

      final credentials = StoreCredentialsModel.fromJsonString(credentialsJson);
      final storeInfoData = json.decode(storeInfoJson) as Map<String, dynamic>;
      final storeId = storeInfoData['store_id'] as int? ?? 0;

      return MenuBloc(
        menuRepository: MenuRepository(
          remoteDataSource: MenuRemoteDataSource(),
          sharedPreferences: sharedPreferences,
        ),
        credentials: credentials,
        storeId: storeId,
      )..add(LoadMenu());
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuBloc = _createMenuBlocIfCredentialsExist();

    return MultiBlocProvider(
      providers: [
        // Global CartBloc shared across all pages
        BlocProvider<CartBloc>(
          create: (context) => CartBloc(CartRepository(sharedPreferences)),
        ),
        // Global MenuBloc - available if credentials exist
        if (menuBloc != null)
          BlocProvider<MenuBloc>.value(
            value: menuBloc,
          ),
      ],
      child: MaterialApp.router(
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
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  observers: [routeObserver],
  initialLocation: '/',
  debugLogDiagnostics: true,
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
    GoRoute(
      path: '/order-history',
      builder: (context, state) => const OrderHistoryPage(),
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
  errorBuilder: (context, state) {
    // Check if this is a locate URL that failed to match
    if (state.uri.path.startsWith('/locate/')) {
      final storeId = state.uri.path.split('/').last;
      return StoreLocatorPage(storeId: storeId);
    }
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Page not found'),
            Text('Path: ${state.uri.path}'),
          ],
        ),
      ),
    );
  },
);
