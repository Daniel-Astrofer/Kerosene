import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/controller/auth_controller.dart';
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
  final _totpController = TextEditingController();

  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _totpFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _totpController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _totpFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter username and passphrase');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    await ref.read(authControllerProvider.notifier).login(
          username: username,
          password: password,
        );

    if (!mounted) return;

    final state = ref.read(authControllerProvider);
    if (state is AuthError) {
      setState(() {
        _isLoading = false;
        _error = state.message;
      });
    } else if (state is AuthRequiresLoginTotp) {
      // TOTP required — switch to TOTP view
      setState(() {
        _isLoading = false;
        _error = null;
      });
      // Auto-focus the TOTP input
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _totpFocus.requestFocus();
      });
    } else {
      setState(() => _isLoading = false);
    }
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
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Connection status indicator
              _ConnectionIndicator(),
              const SizedBox(height: AdminTheme.spacingXl),

              // Main login card
              Container(
                width: 420,
                padding: const EdgeInsets.all(AdminTheme.spacingXxl),
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
            prefixIcon: Icon(Icons.person_outline,
                size: 18, color: AdminColors.textTertiary),
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
            prefixIcon: const Icon(Icons.lock_outline,
                size: 18, color: AdminColors.textTertiary),
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
          onSubmitted: (_) => _handleLogin(),
        ),

        _buildError(),

        const SizedBox(height: AdminTheme.spacingXl),

        // Login button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            child: _isLoading
                ? const _LoadingIndicator()
                : const Text('SIGN IN'),
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
            fontFamily: 'HubotSans',
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
            fontFamily: 'HubotSansCondensed',
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AdminColors.textPrimary,
            letterSpacing: 8.0,
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
              fontFamily: 'HubotSansCondensed',
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AdminColors.textDisabled,
              letterSpacing: 8.0,
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
            child: _isLoading
                ? const _LoadingIndicator()
                : const Text('VERIFY'),
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
                fontFamily: 'HubotSans',
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
            fontFamily: 'HubotSans',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AdminColors.textPrimary,
            letterSpacing: 3.0,
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
            const Icon(Icons.error_outline,
                size: 16, color: AdminColors.negative),
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
    final isOnion = _isOnionConnection();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminTheme.spacingMd,
        vertical: AdminTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: isOnion ? AdminColors.positiveSubtle : AdminColors.warningSubtle,
        border: Border.all(
          color: isOnion
              ? AdminColors.positive.withValues(alpha: 0.3)
              : AdminColors.warning.withValues(alpha: 0.3),
        ),
        borderRadius: AdminTheme.borderRadiusXs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnion ? Icons.shield_outlined : Icons.warning_amber,
            size: 14,
            color: isOnion ? AdminColors.positive : AdminColors.warning,
          ),
          const SizedBox(width: AdminTheme.spacingSm),
          Text(
            isOnion
                ? 'Connected via Onion Service'
                : 'Direct connection — configure onion gateway for maximum security',
            style: AdminTypography.caption.copyWith(
              color: isOnion ? AdminColors.positive : AdminColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  bool _isOnionConnection() {
    try {
      final currentUrl = Uri.base.toString();
      return currentUrl.contains('.onion');
    } catch (_) {
      return false;
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
        color: AdminColors.textPrimary,
      ),
    );
  }
}
