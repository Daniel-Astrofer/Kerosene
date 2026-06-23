import 'package:kerosene/core/errors/exceptions.dart';

class LoginResult {
  final String userId;
  final String jwt;
  final bool requiresTotp;

  const LoginResult({
    this.userId = '',
    this.jwt = '',
    this.requiresTotp = false,
  });

  /// Parses the backend response according to API v5.8:
  /// - Login returns 202: data = "pre_auth_token" (UUID string) → requiresTotp = true
  /// - Login returns 200: data = "userId jwt_token" (space-separated) → requiresTotp = false
  factory LoginResult.fromResponseData(dynamic data) {
    if (data == null) {
      return const LoginResult(requiresTotp: true);
    }

    String raw;
    if (data is Map) {
      raw = (data['data'] ??
              data['token'] ??
              data['jwt'] ??
              data['sessionId'] ??
              '')
          .toString()
          .trim();
      if (raw.isEmpty) {
        raw = data.toString().trim();
      }
    } else {
      raw = data.toString().trim();
    }

    final spaceIdx = raw.indexOf(' ');

    if (spaceIdx <= 0) {
      // No space: either a pre_auth_token (UUID-like) or a final JWT.
      if (raw.contains('.')) {
        return LoginResult(requiresTotp: false, jwt: raw);
      }

      if (raw.isNotEmpty && !raw.startsWith('{')) {
        return LoginResult(requiresTotp: true, jwt: raw);
      }

      if (data is Map && data.containsKey('token')) {
        return LoginResult(
          userId: (data['userId'] ?? '').toString(),
          jwt: (data['token'] ?? data['jwt'] ?? '').toString(),
          requiresTotp: false,
        );
      }

      throw AuthException(
        message: 'Login: formato de resposta inválido ou incompleto',
        statusCode: 200,
        errorCode: 'ERR_AUTH_PARSE',
      );
    }
    return LoginResult(
      userId: raw.substring(0, spaceIdx),
      jwt: raw.substring(spaceIdx + 1).trim(),
      requiresTotp: false,
    );
  }
}
