import 'package:flutter/material.dart';
import 'package:url_strategy/url_strategy.dart';
import 'app.dart';

void main() {
  // Remove the # from URLs for clean routing
  setPathUrlStrategy();

  runApp(const MobileOrderApp());
}
