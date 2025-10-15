import 'package:flutter/material.dart';
import 'package:url_strategy/url_strategy.dart';
import 'app.dart';

// Version info - update this when bumping version in pubspec.yaml
// Current: pubspec.yaml line 19
const kAppVersion = '1.0.0';
const kBuildNumber = '36'; // Build 36: Fix cache isolation - use store-specific cache keys

void main() {
  // Log version information for debugging
  print('='.padRight(60, '='));
  print('Mobile Order App Starting');
  print('Version: $kAppVersion+$kBuildNumber');
  print('Build: ${DateTime.now().toString()}');
  print('='.padRight(60, '='));

  // Remove the # from URLs for clean routing
  setPathUrlStrategy();

  runApp(const MobileOrderApp());
}
