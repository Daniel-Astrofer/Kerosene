import '../../domain/entities/user.dart';

/// Model de User - DTO com serialização JSON
/// Estende a entidade do domínio e adiciona funcionalidades de serialização
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    super.photoUrl,
    required super.createdAt,
  });

  /// Criar UserModel a partir de JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      photoUrl: json['photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Converter UserModel para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Converter UserModel para User (entidade do domínio)
  User toEntity() {
    return User(
      id: id,
      email: email,
      name: name,
      photoUrl: photoUrl,
      createdAt: createdAt,
    );
  }

  /// Criar UserModel a partir de User (entidade do domínio)
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      name: user.name,
      photoUrl: user.photoUrl,
      createdAt: user.createdAt,
    );
  }

  /// Criar cópia com modificações
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
