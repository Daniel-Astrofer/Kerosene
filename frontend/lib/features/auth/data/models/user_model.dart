import '../../domain/entities/user.dart';

/// Model de User - DTO com serialização JSON
/// Alinhado com GET /auth/me da API v5.8
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    super.testBalanceClaimed,
    super.passkeyEnabledForTransactions,
    super.role,
    super.isAdmin,
    super.lastLogin,
    super.photoUrl,
    required super.createdAt,
  });

  /// Criar UserModel a partir de JSON da API (/auth/me)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['userId'] ?? '0').toString(),
      username: (json['username'] ?? json['name'] ?? '').toString(),
      testBalanceClaimed: json['testBalanceClaimed'] == true,
      passkeyEnabledForTransactions:
          json['passkeyEnabledForTransactions'] == true,
      role: (json['role'] ?? 'USER').toString(),
      isAdmin: json['isAdmin'] == true ||
          (json['role'] ?? '').toString().toUpperCase() == 'ADMIN',
      lastLogin: json['lastLogin'] != null
          ? DateTime.tryParse(json['lastLogin'].toString())
          : (json['last_login'] != null
              ? DateTime.tryParse(json['last_login'].toString())
              : null),
      photoUrl: json['photo_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : (json['createdAt'] != null
              ? DateTime.parse(json['createdAt'].toString())
              : DateTime.now()),
    );
  }

  /// Converter UserModel para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'testBalanceClaimed': testBalanceClaimed,
      'passkeyEnabledForTransactions': passkeyEnabledForTransactions,
      'role': role,
      'isAdmin': isAdmin,
      if (lastLogin != null) 'lastLogin': lastLogin!.toIso8601String(),
      if (photoUrl != null) 'photo_url': photoUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Converter UserModel para User (entidade do domínio)
  User toEntity() {
    return User(
      id: id,
      username: username,
      testBalanceClaimed: testBalanceClaimed,
      passkeyEnabledForTransactions: passkeyEnabledForTransactions,
      role: role,
      isAdmin: isAdmin,
      lastLogin: lastLogin,
      photoUrl: photoUrl,
      createdAt: createdAt,
    );
  }

  /// Criar UserModel a partir de User (entidade do domínio)
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      username: user.username,
      testBalanceClaimed: user.testBalanceClaimed,
      passkeyEnabledForTransactions: user.passkeyEnabledForTransactions,
      role: user.role,
      isAdmin: user.isAdmin,
      lastLogin: user.lastLogin,
      photoUrl: user.photoUrl,
      createdAt: user.createdAt,
    );
  }

  /// Criar cópia com modificações
  UserModel copyWith({
    String? id,
    String? username,
    bool? testBalanceClaimed,
    bool? passkeyEnabledForTransactions,
    String? role,
    bool? isAdmin,
    DateTime? lastLogin,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      testBalanceClaimed: testBalanceClaimed ?? this.testBalanceClaimed,
      passkeyEnabledForTransactions:
          passkeyEnabledForTransactions ?? this.passkeyEnabledForTransactions,
      role: role ?? this.role,
      isAdmin: isAdmin ?? this.isAdmin,
      lastLogin: lastLogin ?? this.lastLogin,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
