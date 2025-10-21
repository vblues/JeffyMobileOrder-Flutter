import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_strategy/url_strategy.dart';
import 'app.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Remove the # from URLs for clean routing
  setPathUrlStrategy();

  // Initialize SharedPreferences before app starts
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(MobileOrderApp(sharedPreferences: sharedPreferences));
}
