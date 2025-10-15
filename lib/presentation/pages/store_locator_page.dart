import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getwidget/getwidget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/store_remote_datasource.dart';
import '../../data/repositories/store_repository_impl.dart';
import '../bloc/store_bloc.dart';
import '../bloc/store_event.dart';
import '../bloc/store_state.dart';

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

        return BlocProvider(
          create: (context) => StoreBloc(
            storeRepository: StoreRepository(
              remoteDataSource: StoreRemoteDataSource(),
              sharedPreferences: snapshot.data!,
            ),
          )..add(FetchStoreData(storeId)),
          child: _StoreLocatorView(storeId: storeId),
        );
      },
    );
  }
}

class _StoreLocatorView extends StatelessWidget {
  final String storeId;

  const _StoreLocatorView({required this.storeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GFAppBar(
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
                    GFButton(
                      onPressed: () {
                        context.read<StoreBloc>().add(FetchStoreData(storeId));
                      },
                      text: 'Retry',
                      color: GFColors.DANGER,
                    ),
                    const SizedBox(height: 8),
                    GFButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      text: 'Back to Home',
                      color: GFColors.SECONDARY,
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
                  if (storeInfo.logoUrl != null)
                    Center(
                      child: Image.network(
                        storeInfo.logoUrl!,
                        height: 80,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.store, size: 80),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Store Name Card
                  GFCard(
                    boxFit: BoxFit.cover,
                    elevation: 4.0,
                    content: Column(
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
                  const SizedBox(height: 16),

                  // Success Message
                  GFCard(
                    color: Colors.green[50],
                    content: Row(
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
                  const SizedBox(height: 16),

                  // Debug Info
                  GFCard(
                    color: Colors.blue[50],
                    content: Column(
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
                  const SizedBox(height: 24),

                  // Back Button
                  GFButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    text: 'Back to Home',
                    color: GFColors.SECONDARY,
                    fullWidthButton: true,
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
