// Kerosene — Storybook Entry Point
//
// A lightweight main() that boots the visual Storybook catalog
// instead of the production app. Run with:
//
//   flutter run -t lib/storybook_main.dart -d linux
//
// This file intentionally skips Tor bootstrap, background services,
// and notification init to provide instant startup for visual QA.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storybook/storybook_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Minimal bootstrap for Storybook
  final sharedPreferences = await SharedPreferences.getInstance();
  
  runApp(KeroseneStorybook(sharedPreferences: sharedPreferences));
}
