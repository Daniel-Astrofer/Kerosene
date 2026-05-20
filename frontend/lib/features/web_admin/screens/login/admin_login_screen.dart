import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/core/providers/tor_providers.dart';
import 'package:teste/core/utils/device_helper.dart';
import '../../../auth/controller/auth_controller.dart';
import '../../../auth/controller/auth_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_typography.dart';
import '../../theme/admin_theme.dart';

/// Corporate login screen with full TOTP 2FA flow.
/// Handles: credentials → AuthRequiresLoginTotp → TOTP code entry → AuthAuthenticated
class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _adminKeyController = TextEditingController();
  final _totpController = TextEditingController();

  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _adminKeyFocus = FocusNode();
  final _totpFocus = FocusNode();
  Timer? _pollTimer;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureAdminKey = true;
  String? _error;
  String? _pendingAttemptId;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _adminKeyController.dispose();
    _totpController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _adminKeyFocus.dispose();
    _totpFocus.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final adminKey = _adminKeyController.text.trim();

    if (username.isEmpty || password.isEmpty || adminKey.isEmpty) {
      setState(() => _error = 'Enter username, passphrase and admin key');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final metadata = await DeviceHelper.getDeviceMetadata();
    final adminKeyProof =
        crypto.sha256.convert(utf8.encode(adminKey)).toString();
    final result = await ref.read(authRepositoryProvider).startAdminLogin(
          username: username,
          password: password,
          adminKeyProof: adminKeyProof,
          deviceMetadata: metadata,
        );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _error = failure.message;
        });
      },
      (adminLogin) {
        if (adminLogin.requiresMobileApproval &&
            adminLogin.attemptId.isNotEmpty) {
          setState(() {
            _isLoading = false;
            _error = null;
            _pendingAttemptId = adminLogin.attemptId;
          });
          _startApprovalPolling(adminLogin.attemptId);
          return;
        }
        setState(() => _isLoading = false);
        ref.read(authControllerProvider.notifier).retrySessionCheck();
      },
    );
  }

  void _startApprovalPolling(String attemptId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final result =
          await ref.read(authRepositoryProvider).pollAdminLogin(attemptId);
      if (!mounted) return;
      result.fold(
        (failure) {
          _pollTimer?.cancel();
          setState(() {
            _pendingAttemptId = null;
            _error = failure.message;
          });
        },
        (adminLogin) async {
          if (adminLogin.status.toUpperCase() == 'APPROVED' &&
              adminLogin.token.isNotEmpty) {
            _pollTimer?.cancel();
            setState(() => _pendingAttemptId = null);
            await ref.read(authControllerProvider.notifier).retrySessionCheck();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Acesso administrativo registrado.')),
              );
            }
          } else if (!adminLogin.requiresMobileApproval) {
            _pollTimer?.cancel();
            setState(() {
              _pendingAttemptId = null;
              _error = adminLogin.message.isNotEmpty
                  ? adminLogin.message
                  : 'Admin access was not approved.';
            });
          }
        },
      );
    });
  }

  Future<void> _handleTotpVerify() async {
    final code = _totpController.text.trim();
    if (code.isEmpty || code.length < 6) {
      setState(() => _error = 'Enter a valid 6-digit TOTP code');
      return;
    }

    final authState = ref.read(authControllerProvider);
    if (authState is! AuthRequiresLoginTotp) {
      setState(() => _error = 'Session expired. Please login again.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    await ref.read(authControllerProvider.notifier).verifyLoginTotp(
          username: authState.username,
          passphrase: authState.passphrase,
          totpCode: code,
          preAuthToken: authState.preAuthToken,
        );

    if (!mounted) return;

    final newState = ref.read(authControllerProvider);
    if (newState is AuthError) {
      setState(() {
        _isLoading = false;
        _error = newState.message;
        _totpController.clear();
      });
      _totpFocus.requestFocus();
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _handleBackToLogin() {
    ref.read(authControllerProvider.notifier).clearError();
    setState(() {
      _error = null;
      _totpController.clear();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isTotpStep = authState is AuthRequiresLoginTotp;

    return Scaffold(
      backgroundColor: AdminColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AdminTheme.spacingXl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Connection status indicator
                  _ConnectionIndicator(),
                  const SizedBox(height: AdminTheme.spacingXl),

                  // Main login card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(
                      MediaQuery.sizeOf(context).width < 390
                          ? AdminTheme.spacingXl
                          : AdminTheme.spacingXxl,
                    ),
                    decoration: BoxDecoration(
                      color: AdminColors.surface,
                      border: Border.all(color: AdminColors.border),
                      borderRadius: AdminTheme.borderRadiusMd,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: isTotpStep
                          ? _buildTotpView(authState)
                          : _buildLoginView(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginView() {
    return Column(
      key: const ValueKey('login'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        const SizedBox(height: AdminTheme.spacingXxl),

        // Username
        TextField(
          controller: _usernameController,
          focusNode: _usernameFocus,
          style: AdminTypography.bodyLarge,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'Username',
            prefixIcon: Icon(
              Icons.person_outline,
              size: 18,
              color: AdminColors.textTertiary,
            ),
          ),
          onSubmitted: (_) => _passwordFocus.requestFocus(),
        ),
        const SizedBox(height: AdminTheme.spacingLg),

        // Password
        TextField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          obscureText: _obscurePassword,
          style: AdminTypography.bodyLarge,
          textInputAction: TextInputAction.go,
          decoration: InputDecoration(
            hintText: 'Passphrase',
            prefixIcon: const Icon(
              Icons.lock_outline,
              size: 18,
              color: AdminColors.textTertiary,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: AdminColors.textTertiary,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          onSubmitted: (_) => _adminKeyFocus.requestFocus(),
        ),
        const SizedBox(height: AdminTheme.spacingLg),

        TextField(
          controller: _adminKeyController,
          focusNode: _adminKeyFocus,
          obscureText: _obscureAdminKey,
          style: AdminTypography.bodyLarge,
          textInputAction: TextInputAction.go,
          decoration: InputDecoration(
            hintText: 'Admin key',
            prefixIcon: const Icon(
              Icons.vpn_key_outlined,
              size: 18,
              color: AdminColors.textTertiary,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureAdminKey
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: AdminColors.textTertiary,
              ),
              onPressed: () =>
                  setState(() => _obscureAdminKey = !_obscureAdminKey),
            ),
          ),
          onSubmitted: (_) => _handleLogin(),
        ),

        if (_pendingAttemptId != null) ...[
          const SizedBox(height: AdminTheme.spacingLg),
          _ApprovalPendingBanner(attemptId: _pendingAttemptId!),
        ],

        _buildError(),

        const SizedBox(height: AdminTheme.spacingXl),

        // Login button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            child:
                _isLoading ? const _LoadingIndicator() : const Text('SIGN IN'),
          ),
        ),

        const SizedBox(height: AdminTheme.spacingXl),

        // Footer
        Text(
          'Secure access via onion service',
          style: AdminTypography.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTotpView(AuthRequiresLoginTotp totpState) {
    return Column(
      key: const ValueKey('totp'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Lock icon
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AdminColors.warningSubtle,
            borderRadius: AdminTheme.borderRadiusSm,
            border: Border.all(
              color: AdminColors.warning.withValues(alpha: 0.3),
            ),
          ),
          child: const Center(
            child: Icon(Icons.security, size: 24, color: AdminColors.warning),
          ),
        ),
        const SizedBox(height: AdminTheme.spacingXl),
        const Text(
          'TWO-FACTOR AUTHENTICATION',
          style: TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AdminColors.textPrimary,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: AdminTheme.spacingSm),
        Text(
          'Enter the 6-digit code from your authenticator app',
          style: AdminTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AdminTheme.spacingXs),
        Text(
          'Authenticating as ${totpState.username}',
          style: AdminTypography.caption,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AdminTheme.spacingXxl),

        // TOTP input
        TextField(
          controller: _totpController,
          focusNode: _totpFocus,
          style: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AdminColors.textPrimary,
            letterSpacing: 0,
          ),
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: InputDecoration(
            counterText: '',
            hintText: '000000',
            hintStyle: TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AdminColors.textDisabled,
              letterSpacing: 0,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AdminTheme.spacingLg,
              vertical: AdminTheme.spacingLg,
            ),
          ),
          onChanged: (value) {
            // Auto-submit when 6 digits entered
            if (value.length == 6) {
              _handleTotpVerify();
            }
          },
          onSubmitted: (_) => _handleTotpVerify(),
        ),

        _buildError(),

        const SizedBox(height: AdminTheme.spacingXl),

        // Verify button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleTotpVerify,
            child:
                _isLoading ? const _LoadingIndicator() : const Text('VERIFY'),
          ),
        ),

        const SizedBox(height: AdminTheme.spacingLg),

        // Back button
        TextButton.icon(
          onPressed: _isLoading ? null : _handleBackToLogin,
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Back to login'),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AdminColors.accent,
            borderRadius: AdminTheme.borderRadiusSm,
          ),
          child: const Center(
            child: Text(
              'K',
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: AdminTheme.spacingXl),
        const Text(
          'KEROSENE',
          style: TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AdminColors.textPrimary,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AdminTheme.spacingSm),
        Text(
          'Enterprise Management Console',
          style: AdminTypography.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildError() {
    if (_error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AdminTheme.spacingLg),
      child: Container(
        padding: const EdgeInsets.all(AdminTheme.spacingMd),
        decoration: BoxDecoration(
          color: AdminColors.negativeSubtle,
          border: Border.all(
            color: AdminColors.negative.withValues(alpha: 0.3),
          ),
          borderRadius: AdminTheme.borderRadiusSm,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              size: 16,
              color: AdminColors.negative,
            ),
            const SizedBox(width: AdminTheme.spacingSm),
            Expanded(
              child: Text(
                _error!,
                style: AdminTypography.bodySmall.copyWith(
                  color: AdminColors.negative,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Connection status indicator — shows onion routing status
class _ConnectionIndicator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status =
        _AdminConnectionStatus.fromApiUrl(ref.watch(torApiUrlProvider));
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminTheme.spacingMd,
        vertical: AdminTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: status.background,
        border: Border.all(color: status.border),
        borderRadius: AdminTheme.borderRadiusXs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            size: 14,
            color: status.foreground,
          ),
          const SizedBox(width: AdminTheme.spacingSm),
          Flexible(
            child: Text(
              status.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AdminTypography.caption.copyWith(
                color: status.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalPendingBanner extends StatelessWidget {
  final String attemptId;

  const _ApprovalPendingBanner({required this.attemptId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AdminTheme.spacingMd),
      decoration: BoxDecoration(
        color: AdminColors.warningSubtle,
        border: Border.all(color: AdminColors.warning.withValues(alpha: 0.3)),
        borderRadius: AdminTheme.borderRadiusSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AdminColors.warning,
            ),
          ),
          const SizedBox(width: AdminTheme.spacingSm),
          Expanded(
            child: Text(
              'Waiting for approval in the mobile app.',
              style: AdminTypography.bodySmall.copyWith(
                color: AdminColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminConnectionStatus {
  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;
  final Color border;

  const _AdminConnectionStatus({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.border,
  });

  factory _AdminConnectionStatus.fromApiUrl(String apiUrl) {
    final apiHost = Uri.tryParse(apiUrl)?.host.toLowerCase() ?? '';
    final browserHost = _currentBrowserHost();
    final isBrowserOnion = browserHost.endsWith('.onion');
    final isApiOnion = apiHost.endsWith('.onion');

    if (isBrowserOnion && (apiHost.isEmpty || apiHost == browserHost)) {
      return _AdminConnectionStatus(
        label: 'Connected via Onion Service',
        icon: Icons.shield_outlined,
        foreground: AdminColors.positive,
        background: AdminColors.positiveSubtle,
        border: AdminColors.positive.withValues(alpha: 0.3),
      );
    }

    if (isApiOnion) {
      return _AdminConnectionStatus(
        label: 'API routed to Onion Service',
        icon: Icons.shield_outlined,
        foreground: AdminColors.positive,
        background: AdminColors.positiveSubtle,
        border: AdminColors.positive.withValues(alpha: 0.3),
      );
    }

    return _AdminConnectionStatus(
      label: 'Direct/gateway route - onion not browser-verified',
      icon: Icons.warning_amber,
      foreground: AdminColors.warning,
      background: AdminColors.warningSubtle,
      border: AdminColors.warning.withValues(alpha: 0.3),
    );
  }

  static String _currentBrowserHost() {
    try {
      return Uri.base.host.toLowerCase();
    } catch (_) {
      return '';
    }
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AdminColors.background,
      ),
    );
  }
}
