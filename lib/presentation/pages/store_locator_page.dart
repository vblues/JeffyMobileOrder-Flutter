import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/storage_keys.dart';
import '../../data/datasources/store_remote_datasource.dart';
import '../../data/repositories/store_repository_impl.dart';
import '../bloc/store_bloc.dart';
import '../bloc/store_event.dart';
import '../bloc/store_state.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';

class StoreLocatorPage extends StatelessWidget {
  final String storeId;

  const StoreLocatorPage({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Save entry URL on first visit
        final entryUrl = '/locate/$storeId';
        snapshot.data!.setString(StorageKeys.entryUrl, entryUrl);

        return BlocProvider(
          create: (context) => StoreBloc(
            storeRepository: StoreRepository(
              remoteDataSource: StoreRemoteDataSource(),
              sharedPreferences: snapshot.data!,
            ),
          )..add(FetchStoreData(storeId)),
          child: _StoreLocatorView(storeId: storeId, preferences: snapshot.data!),
        );
      },
    );
  }
}

class _StoreLocatorView extends StatefulWidget {
  final String storeId;
  final SharedPreferences preferences;

  const _StoreLocatorView({required this.storeId, required this.preferences});

  @override
  State<_StoreLocatorView> createState() => _StoreLocatorViewState();
}

class _StoreLocatorViewState extends State<_StoreLocatorView> {
  @override
  void initState() {
    super.initState();
    // Clear global cart on entry - fresh start for each store visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartBloc>().add(ClearCart());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoreBloc, StoreState>(
      builder: (context, state) {
        // Get store name and brand color for app bar
        String appBarTitle = 'Store Locator';
        Color appBarColor = Theme.of(context).colorScheme.primary;

        if (state is StoreLoaded && state.storeInfo != null) {
          appBarTitle = state.storeInfo!.storeNameEn;
          appBarColor = _parseColor(state.storeInfo!.brandColor);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(appBarTitle),
            backgroundColor: appBarColor,
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, StoreState state) {
          if (state is StoreLoading) {
            return Container(
              color: Colors.blue,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'STORE LOCATOR LOADING',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      'Store ID: ${widget.storeId}',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is StoreError) {
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
                      'Error Loading Store',
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
                        context.read<StoreBloc>().add(FetchStoreData(widget.storeId));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () {
                        final entryUrl = widget.preferences.getString(StorageKeys.entryUrl);
                        if (entryUrl != null) {
                          context.go(entryUrl);
                        } else {
                          context.go('/');
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text('Back to Home'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is StoreLoaded) {
            print('[StoreLocator] StoreLoaded state received');
            // Automatically navigate to menu page when store data is loaded
            // Add small delay to ensure SharedPreferences is persisted
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              print('[StoreLocator] Delaying for SharedPreferences persist');
              // Ensure preferences are committed before navigation
              await Future.delayed(const Duration(milliseconds: 100));
              print('[StoreLocator] Navigating to /menu');
              if (context.mounted) {
                context.go('/menu');
              }
            });

            // Show loading indicator while navigating
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return const Center(
            child: Text('Ready to load store data'),
          );
  }

  /// Parse hex color string to Flutter Color
  Color _parseColor(String hexColor) {
    try {
      // Remove # if present and parse
      final hex = hexColor.replaceFirst('#', '');
      return Color(int.parse(hex, radix: 16) + 0xFF000000);
    } catch (e) {
      // Fallback to default orange color
      return const Color(0xFF996600);
    }
  }
}
