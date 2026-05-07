export 'core/providers/shared_preferences_provider.dart'
    show sharedPreferencesProvider;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bootstrap/mobile_bootstrap.dart'
    if (dart.library.html) 'bootstrap/web_bootstrap.dart' as bootstrap;
import 'core/logging/app_log.dart';
import 'core/providers/shared_preferences_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureAppLogging();

  final sharedPreferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
    ],
  );

  await bootstrap.initializeApp(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: bootstrap.buildApp(),
    ),
  );
}
