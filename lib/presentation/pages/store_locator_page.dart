import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';

class StoreLocatorPage extends StatelessWidget {
  final String storeId;

  const StoreLocatorPage({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GFAppBar(
        title: const Text('Store Locator'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GFCard(
                boxFit: BoxFit.cover,
                elevation: 4.0,
                content: Column(
                  children: [
                    const Icon(
                      Icons.store,
                      size: 64,
                      color: Color(0xFF996600),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Store ID Detected',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        storeId,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'URL parameter extraction is working!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Next: Implement API call to fetch store data',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
        ),
      ),
    );
  }
}
