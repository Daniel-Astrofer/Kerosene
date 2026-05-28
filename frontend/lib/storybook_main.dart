import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'storybook/storybook_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(KeroseneStorybook(sharedPreferences: sharedPreferences));
}
