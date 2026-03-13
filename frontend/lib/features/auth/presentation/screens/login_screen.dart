import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/widgets/custom_error_dialog.dart';
import '../../../../core/utils/error_translator.dart';
import '../../../../l10n/l10n_extension.dart';
import '../providers/auth_provider.dart';
import '../state/auth_state.dart';
import 'unknown_device_screen.dart';
import 'package:teste/features/home/presentation/screens/home_screen.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/neon_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final localDataSource = ref.read(authLocalDataSourceProvider);
      final creds = await localDataSource.getCredentials();
      if (creds != null && mounted) {
        setState(() {
          _usernameController.text = creds['username'] ?? '';
          _passwordController.text = creds['passphrase'] ?? '';
          _rememberMe = true;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
        return;
      }
      ref.read(authProvider.notifier).login(
            username: _usernameController.text,
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authProvider, (previous, next) async {
      if (next is AuthAuthenticated) {
        final localDataSource = ref.read(authLocalDataSourceProvider);
        if (_rememberMe) {
          await localDataSource.saveCredentials(
            _usernameController.text,
            _passwordController.text,
          );
        } else {
          await localDataSource.removeCredentials();
        }

        if (context.mounted) {
          HomeScreen.skipNextAuth = true;
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else if (next is AuthRequiresLoginTotp) {
        // Redirecionamento temporário mantido até refatorar a TOTP final
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UnknownDeviceScreen(
              username: next.username,
              passphrase: next.passphrase,
              rememberMe: _rememberMe,
              preAuthToken: next.preAuthToken,
            ),
          ),
        );
      } else if (next is AuthError) {
        if (context.mounted) {
          showCustomErrorDialog(
            context,
            ErrorTranslator.translate(context.l10n, next.message),
            onRetry: () {
              ref.read(authProvider.notifier).clearError();
              if (_usernameController.text.isNotEmpty &&
                  _passwordController.text.isNotEmpty) {
                _handleLogin();
              }
            },
            onGoBack: () {
              ref.read(authProvider.notifier).clearError();
              Navigator.pop(context);
            },
          );
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),

                const SizedBox(height: 60),

                // Textos de Boas-vindas
                const Text(
                  'Bem-vindo de Volta',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Entre para acessar sua carteira',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 60),

                // Campos de Entrada usando o AuthTextField novo
                AuthTextField(
                  controller: _usernameController,
                  label: 'Usuário',
                  hint: 'astrofras',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 20),
                AuthTextField(
                  controller: _passwordController,
                  label: 'Senha da conta',
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  isPassword: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white.withValues(alpha: 0.4),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Lembrar de mim e Esqueci a Senha
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _rememberMe = !_rememberMe;
                        });
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _rememberMe
                                    ? const Color(0xFF00FFA3)
                                    : Colors.white.withValues(alpha: 0.3),
                                width: 2,
                              ),
                              color: _rememberMe
                                  ? const Color(0xFF00FFA3)
                                  : Colors.transparent,
                            ),
                            child: _rememberMe
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.black,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Lembrar de mim',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Implementar esqueceu a senha se necessário
                      },
                      child: Text(
                        'Esqueceu sua senha?',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // Botão de Login usando NeonButton novo
                isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00FFA3),
                        ),
                      )
                    : Column(
                        children: [
                          NeonButton(
                            text: 'Entrar',
                            onPressed: _handleLogin,
                            baseColor: const Color(0xFF00FFA3),
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: isLoading
                                ? null
                                : () => ref
                                    .read(authProvider.notifier)
                                    .loginWithHardware(_usernameController.text),
                            icon: const Icon(Icons.security, color: Color(0xFF00FFA3)),
                            label: const Text(
                              'Entrar com Hardware Auth',
                              style: TextStyle(
                                color: Color(0xFF00FFA3),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 48),

                // Sign Up Link
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/signup'),
                    child: RichText(
                      text: TextSpan(
                        text: 'New here? ',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign up',
                            style: const TextStyle(
                              color: Color(0xFF0033FF),
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
