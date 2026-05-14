import 'dart:convert';

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
  final String username;

  const AuthTotpVerified(this.sessionId, this.username);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthTotpVerified &&
        other.sessionId == sessionId &&
        other.username == username;
  }

  @override
  int get hashCode => sessionId.hashCode ^ username.hashCode;
}

/// Estado não autenticado
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Estado de erro
class AuthError extends AuthState {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final Object? data;

  const AuthError(
    this.message, {
    this.statusCode,
    this.errorCode,
    this.data,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthError &&
        other.message == message &&
        other.statusCode == statusCode &&
        other.errorCode == errorCode &&
        other.data == data;
  }

  @override
  int get hashCode =>
      message.hashCode ^
      statusCode.hashCode ^
      errorCode.hashCode ^
      data.hashCode;

  @override
  String toString() => jsonEncode({
        'type': 'AuthError',
        'message': message,
        'statusCode': statusCode,
        'errorCode': errorCode,
        'data': data,
      });
}

/// Estado indicando que o signup foi iniciado e requer setup de TOTP
class AuthRequiresTotpSetup extends AuthState {
  final String username;
  final String passphrase;
  final String sessionId;
  final String totpSecret;
  final String qrCodeUri;
  final List<String> backupCodes;
  final bool totpOptional;

  const AuthRequiresTotpSetup({
    required this.username,
    required this.passphrase,
    required this.sessionId,
    required this.totpSecret,
    required this.qrCodeUri,
    this.backupCodes = const [],
    this.totpOptional = true,
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

/// Estado indicando que o depósito de ativação é necessário
class AuthPaymentRequired extends AuthState {
  final String sessionId;
  final String paymentLinkId;
  final double amountBtc;
  final String depositAddress;
  final String paymentStatus;
  final String? submittedTxid;
  final String? statusMessage;
  final String? errorMessage;
  final bool isSubmitting;

  const AuthPaymentRequired({
    required this.sessionId,
    required this.paymentLinkId,
    required this.amountBtc,
    required this.depositAddress,
    this.paymentStatus = 'pending',
    this.submittedTxid,
    this.statusMessage,
    this.errorMessage,
    this.isSubmitting = false,
  });

  AuthPaymentRequired copyWith({
    String? sessionId,
    String? paymentLinkId,
    double? amountBtc,
    String? depositAddress,
    String? paymentStatus,
    String? submittedTxid,
    String? statusMessage,
    String? errorMessage,
    bool? isSubmitting,
    bool clearError = false,
  }) {
    return AuthPaymentRequired(
      sessionId: sessionId ?? this.sessionId,
      paymentLinkId: paymentLinkId ?? this.paymentLinkId,
      amountBtc: amountBtc ?? this.amountBtc,
      depositAddress: depositAddress ?? this.depositAddress,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      submittedTxid: submittedTxid ?? this.submittedTxid,
      statusMessage: statusMessage ?? this.statusMessage,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

/// Estado quando há falha de comunicação com o servidor mas o usuário tem token
class AuthServerUnavailable extends AuthState {
  final String message;
  const AuthServerUnavailable([
    this.message = 'Servidor indisponível no momento',
  ]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthServerUnavailable && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
