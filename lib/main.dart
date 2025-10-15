import 'package:flutter/material.dart';
import 'package:url_strategy/url_strategy.dart';
import 'app.dart';

// Version info - update this when bumping version in pubspec.yaml
// Current: pubspec.yaml line 19
const kAppVersion = '1.0.0';
const kBuildNumber = '41'; // Build 41: Add combo product modifiers and radio button deselection

void main() {
  // Remove the # from URLs for clean routing
  setPathUrlStrategy();

  runApp(const MobileOrderApp());
}
