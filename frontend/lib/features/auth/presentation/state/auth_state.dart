import '../../domain/entities/user.dart';

/// Estado de autenticação
sealed class AuthState {
  const AuthState();
}

/// Estado inicial
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Estado de carregamento
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Estado autenticado
class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthAuthenticated && other.user == user;
  }

  @override
  int get hashCode => user.hashCode;
}

/// Estado não autenticado
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Estado de erro
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

/// Estado indicando que o signup foi iniciado e requer setup de TOTP
class AuthRequiresTotpSetup extends AuthState {
  final String username;
  final String passphrase;
  final String totpSecret;

  const AuthRequiresTotpSetup({
    required this.username,
    required this.passphrase,
    required this.totpSecret,
  });
}

/// Estado indicando que o login requer 2FA
class AuthRequiresLoginTotp extends AuthState {
  final String username;
  final String passphrase;

  const AuthRequiresLoginTotp({
    required this.username,
    required this.passphrase,
  });
}
