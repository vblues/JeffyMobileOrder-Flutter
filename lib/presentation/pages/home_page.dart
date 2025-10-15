import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GFAppBar(
        title: const Text('Mobile Order - Home'),
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
                      Icons.restaurant_menu,
                      size: 64,
                      color: Color(0xFF996600),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome to Mobile Order',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Flutter Web Application',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    GFButton(
                      onPressed: () {
                        // Navigate to test store
                        Navigator.pushNamed(
                          context,
                          '/locate/81898903-e31a-442a-9207-120e4a8f2a09',
                        );
                      },
                      text: 'Test Store Locator',
                      color: const Color(0xFF996600),
                      fullWidthButton: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Phase 1: Basic Setup Complete ✓',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
