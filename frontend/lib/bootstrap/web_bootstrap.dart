import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:kerosene/core/config/app_config.dart';
import 'package:kerosene/core/navigation/deferred_page.dart';
import 'package:kerosene/core/navigation/app_page_transitions.dart';
import 'package:kerosene/core/performance/kerosene_performance_boundary.dart';
import 'package:kerosene/core/providers/tor_providers.dart';
import 'package:kerosene/core/responsive/kerosene_responsive.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';
import 'package:kerosene/features/web_admin/theme/admin_theme.dart';
import 'package:kerosene/features/auth/presentation/screens/server_unavailable_screen.dart'
    deferred as server_unavailable;
import 'package:kerosene/features/landing/presentation/kerosene_landing_page.dart'
    deferred as landing;
import 'package:kerosene/features/web_admin/navigation/admin_content_router.dart'
    deferred as admin_content_router;
import 'package:kerosene/features/web_admin/screens/login/admin_login_screen.dart'
    deferred as admin_login;
import 'package:kerosene/features/web_admin/shell/admin_shell.dart'
    deferred as admin_shell;

/// Resolves the API URL for the web admin.
///
/// Priority order:
/// 1. `WEB_API_URL` compile-time env → e.g. `http://xyz.onion` via an onion gateway
/// 2. `WEB_ONION_GATEWAY` compile-time env → an HTTP gateway that proxies to .onion
/// 3. If the browser is already on a .onion domain (via Tor Browser), use the origin
/// 4. Fallback to `Uri.base.origin` (same-origin for clearnet deployments)
String _resolveApiUrl() {
  // 1. Explicit API URL override (highest priority)
  const configuredApiUrl = String.fromEnvironment('WEB_API_URL');
  if (configuredApiUrl.trim().isNotEmpty) {
    return _normalizeApiOrigin(configuredApiUrl, 'WEB_API_URL');
  }

  // 2. Onion gateway proxy URL (e.g. onion2web, tor2web, or local Nginx)
  const onionGateway = String.fromEnvironment('WEB_ONION_GATEWAY');
  if (onionGateway.trim().isNotEmpty) {
    return _normalizeApiOrigin(onionGateway, 'WEB_ONION_GATEWAY');
  }

  // 3. Detect if already running inside Tor Browser on a .onion domain
  try {
    final origin = Uri.base.origin;
    final host = Uri.base.host;
    if (host.endsWith('.onion')) {
      debugPrint('🧅 Detected .onion origin: $origin');
      return origin;
    }
  } catch (_) {}

  // 4. Same-origin fallback (web app served by the backend itself)
  return Uri.base.origin;
}

String _normalizeApiOrigin(String raw, String envName) {
  final trimmed = raw.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme || uri.host.trim().isEmpty) {
    throw ArgumentError(
      '$envName must be an absolute URL, for example http://example.onion',
    );
  }

  if (uri.scheme != 'http' && uri.scheme != 'https') {
    throw ArgumentError('$envName must use http or https.');
  }

  return trimmed.endsWith('/')
      ? trimmed.substring(0, trimmed.length - 1)
      : trimmed;
}

bool _isOnionHost(String host) => host.toLowerCase().endsWith('.onion');

Future<void> initializeApp(ProviderContainer container) async {
  usePathUrlStrategy();

  final resolvedApiUrl = _resolveApiUrl();
  debugPrint('🌐 Web Admin API URL: $resolvedApiUrl');

  configureResolvedApiUrl(container, resolvedApiUrl);
}

@visibleForTesting
void configureResolvedApiUrl(
  ProviderContainer container,
  String resolvedApiUrl,
) {
  // Web requests go directly to the resolved origin. Keep the logical active
  // node aligned with that host so passkey rpId/authenticatorData validation
  // uses the same host the backend actually receives.
  AppConfig.apiUrl = resolvedApiUrl;
  AppConfig.activeNodeUrl = resolvedApiUrl;

  try {
    final host = Uri.parse(resolvedApiUrl).host;
    final browserHost = Uri.base.host;
    AppConfig.isTorEnabled = _isOnionHost(host) || _isOnionHost(browserHost);
    if (_isOnionHost(host)) {
      debugPrint('🧅 Onion routing active → $host');
    }
  } catch (_) {}

  container.read(torApiUrlProvider.notifier).updateUrl(resolvedApiUrl);
}

Widget buildApp() => const _AdminWebApp();

class _AdminWebApp extends ConsumerWidget {
  const _AdminWebApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Kerosene',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.themeData.copyWith(
        pageTransitionsTheme: kerosenePageTransitionsTheme,
      ),
      scrollBehavior: const _WebScrollBehavior(),
      builder: (context, child) {
        return KeroseneResponsiveBoundary(
          child: KerosenePerformanceBoundary(child: child!),
        );
      },
      initialRoute: _initialRoute(),
      routes: {
        '/': (_) => DeferredPage(
              loadLibrary: landing.loadLibrary,
              builder: (_) => landing.KeroseneLandingPage(),
            ),
        '/bitcoin-banking': (_) => DeferredPage(
              loadLibrary: landing.loadLibrary,
              builder: (_) => landing.KeroseneLandingPage(),
            ),
        '/admin': (_) => const _AdminAuthGate(),
        '/download': (_) => DeferredPage(
              loadLibrary: landing.loadLibrary,
              builder: (_) => landing.KeroseneLandingPage(focusDownload: true),
            ),
        '/status': (_) => DeferredPage(
              loadLibrary: landing.loadLibrary,
              builder: (_) => landing.KerosenePublicStatusPage(),
            ),
      },
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) => DeferredPage(
          loadLibrary: landing.loadLibrary,
          builder: (_) => landing.KeroseneLandingPage(),
        ),
      ),
    );
  }

  String _initialRoute() {
    return resolveWebInitialRoute(Uri.base.path);
  }
}

@visibleForTesting
String resolveWebInitialRoute(String path) {
  if (path == '/bitcoin-banking' || path.startsWith('/bitcoin-banking/')) {
    return '/bitcoin-banking';
  }
  if (path == '/admin' || path.startsWith('/admin/')) return '/admin';
  if (path == '/download') return '/download';
  if (path == '/status') return '/status';
  return '/';
}

class _AdminAuthGate extends ConsumerWidget {
  const _AdminAuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    if (authState is AuthInitial || authState is AuthLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0E0E10),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF6A6A74),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Establishing secure connection...',
                style: TextStyle(
                  fontFamily: 'IBMPlexSansHebrew',
                  fontSize: 12,
                  color: Color(0xFF6A6A74),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (authState is AuthAuthenticated && authState.user.isAdmin) {
      return DeferredPage(
        loadLibrary: _loadAdminSurface,
        builder: (_) => admin_shell.AdminShell(
          child: admin_content_router.AdminContentRouter(),
        ),
      );
    }

    if (authState is AuthRequiresLoginTotp) {
      return DeferredPage(
        loadLibrary: admin_login.loadLibrary,
        builder: (_) => admin_login.AdminLoginScreen(),
      );
    }

    if (authState is AuthServerUnavailable) {
      return _ServerUnavailableView(message: authState.message, ref: ref);
    }

    return DeferredPage(
      loadLibrary: admin_login.loadLibrary,
      builder: (_) => admin_login.AdminLoginScreen(),
    );
  }
}

class _ServerUnavailableView extends StatelessWidget {
  final String message;
  final WidgetRef ref;

  const _ServerUnavailableView({required this.message, required this.ref});

  @override
  Widget build(BuildContext context) {
    return DeferredPage(
      loadLibrary: server_unavailable.loadLibrary,
      builder: (_) => server_unavailable.ServerUnavailableScreen(
        message: message,
        onRetryOverride: () {
          return ref.read(authControllerProvider.notifier).retrySessionCheck();
        },
      ),
    );
  }
}

Future<void> _loadAdminSurface() async {
  await Future.wait<void>([
    admin_shell.loadLibrary(),
    admin_content_router.loadLibrary(),
  ]);
}

class _WebScrollBehavior extends ScrollBehavior {
  const _WebScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}
