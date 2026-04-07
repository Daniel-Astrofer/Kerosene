/// Entidade User - Objeto puro do domínio
/// Alinhado com GET /auth/me da API v5.8
class User {
  final String id;
  final String username;
  final bool testBalanceClaimed;
  final bool passkeyEnabledForTransactions;
  final DateTime? lastLogin;
  final String? photoUrl;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.username,
    this.testBalanceClaimed = false,
    this.passkeyEnabledForTransactions = false,
    this.lastLogin,
    this.photoUrl,
    required this.createdAt,
  });

  /// Alias for backward compat — UI references `user.name`
  String get name => username;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
        other.id == id &&
        other.username == username &&
        other.testBalanceClaimed == testBalanceClaimed &&
        other.passkeyEnabledForTransactions == passkeyEnabledForTransactions &&
        other.lastLogin == lastLogin &&
        other.photoUrl == photoUrl &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        username.hashCode ^
        testBalanceClaimed.hashCode ^
        passkeyEnabledForTransactions.hashCode ^
        lastLogin.hashCode ^
        photoUrl.hashCode ^
        createdAt.hashCode;
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, testBalanceClaimed: $testBalanceClaimed, passkeyEnabled: $passkeyEnabledForTransactions, lastLogin: $lastLogin)';
  }
}
