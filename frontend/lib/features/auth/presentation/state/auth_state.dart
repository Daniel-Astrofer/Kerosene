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

class AuthTotpVerified extends AuthState {
  final String sessionId;

  const AuthTotpVerified(this.sessionId);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthTotpVerified && other.sessionId == sessionId;
  }

  @override
  int get hashCode => sessionId.hashCode;
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
  final String qrCodeUri;

  const AuthRequiresTotpSetup({
    required this.username,
    required this.passphrase,
    required this.totpSecret,
    required this.qrCodeUri,
  });
}

/// Estado indicando que o login requer 2FA
class AuthRequiresLoginTotp extends AuthState {
  final String username;
  final String passphrase;
  final String? preAuthToken;

  const AuthRequiresLoginTotp({
    required this.username,
    required this.passphrase,
    this.preAuthToken,
  });
}
/// Estado indicando que o desafio de hardware foi recebido e aguarda assinatura
class AuthHardwareChallengeReceived extends AuthState {
  final String challengeHex;
  const AuthHardwareChallengeReceived(this.challengeHex);
}

/// Estado indicando que o desafio de passkey foi recebido (JSON options)
class AuthPasskeyChallengeReceived extends AuthState {
  final String optionsJson;
  const AuthPasskeyChallengeReceived(this.optionsJson);
}

/// Estado indicando que a chave de hardware foi verificada com sucesso
class AuthHardwareVerified extends AuthState {
  const AuthHardwareVerified();
}

/// Estado indicando que o pagamento de onboarding é necessário
class AuthPaymentRequired extends AuthState {
  final String sessionId;
  final double amountBtc;
  final String depositAddress;

  const AuthPaymentRequired({
    required this.sessionId,
    required this.amountBtc,
    required this.depositAddress,
  });
}
