import 'package:flutter/material.dart';
import 'package:url_strategy/url_strategy.dart';
import 'app.dart';

// Version info - update this when bumping version in pubspec.yaml
// Current: pubspec.yaml line 19
const kAppVersion = '1.0.0';
const kBuildNumber = '42'; // Build 42: Fix modifier button showing when no modifiers available

void main() {
  // Remove the # from URLs for clean routing
  setPathUrlStrategy();

  runApp(const MobileOrderApp());
}
