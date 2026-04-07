import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart' show sharedPreferencesProvider;
import '../data/datasources/auth_local_datasource.dart';

export '../data/datasources/auth_local_datasource.dart';

/// @nodoc
/// Provider for the AuthLocalDataSource.
/// This is separated from auth_providers.dart to avoid circular dependencies
/// with api_client_provider.dart.
final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  final sharedPreferences = ref.watch(sharedPreferencesProvider);
  return AuthLocalDataSourceImpl(sharedPreferences);
});
