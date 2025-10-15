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
import '../widgets/web_safe_image.dart';

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

class _StoreLocatorView extends StatelessWidget {
  final String storeId;
  final SharedPreferences preferences;

  const _StoreLocatorView({required this.storeId, required this.preferences});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Locator'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: BlocBuilder<StoreBloc, StoreState>(
        builder: (context, state) {
          if (state is StoreLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading store information...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
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
                        context.read<StoreBloc>().add(FetchStoreData(storeId));
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
                        final entryUrl = preferences.getString(StorageKeys.entryUrl);
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
            final storeInfo = state.storeInfo;

            if (storeInfo == null) {
              return const Center(
                child: Text('No store information available'),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store Logo and Landing Page Image
                  if (storeInfo.secureLogoUrl != null)
                    Center(
                      child: WebSafeImage(
                        imageUrl: storeInfo.secureLogoUrl!,
                        height: 80,
                        errorWidget: const Icon(Icons.store, size: 80),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Store Name Card
                  Card(
                    elevation: 4.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.store,
                              size: 32,
                              color: _parseColor(storeInfo.brandColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                storeInfo.storeNameEn,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.tag,
                          'Store ID',
                          storeInfo.storeId.toString(),
                        ),
                        _buildInfoRow(
                          Icons.qr_code,
                          'Store SN',
                          storeInfo.storeSn,
                        ),
                        if (storeInfo.street != null)
                          _buildInfoRow(
                            Icons.location_on,
                            'Location',
                            storeInfo.street!,
                          ),
                        if (storeInfo.contactPhone != null)
                          _buildInfoRow(
                            Icons.phone,
                            'Phone',
                            storeInfo.contactPhone!,
                          ),
                      ],
                    ),
                      ),
                  ),
                  const SizedBox(height: 16),

                  // Success Message
                  Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Store Data Loaded Successfully',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'API integration with MD5 signing is working correctly.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                      ),
                  ),
                  const SizedBox(height: 16),

                  // Debug Info
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Phase 2 Complete ✓',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('• Store locator API integration'),
                        const Text('• MD5 signature authentication'),
                        const Text('• BLoC state management'),
                        const Text('• Data models and repository'),
                        const Text('• Local storage caching'),
                      ],
                    ),
                      ),
                  ),
                  const SizedBox(height: 24),

                  // View Menu Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.go('/menu');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('View Menu'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Back Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        final entryUrl = preferences.getString(StorageKeys.entryUrl);
                        if (entryUrl != null) {
                          context.go(entryUrl);
                        } else {
                          context.go('/');
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Back to Home'),
                    ),
                  ),
                ],
              ),
            );
          }

          return const Center(
            child: Text('Ready to load store data'),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return const Color(0xFF996600);
    }
  }
}
