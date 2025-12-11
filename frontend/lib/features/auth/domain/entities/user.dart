/// Entidade User - Objeto puro do domínio
class User {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
        other.id == id &&
        other.email == email &&
        other.name == name &&
        other.photoUrl == photoUrl &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        name.hashCode ^
        photoUrl.hashCode ^
        createdAt.hashCode;
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, photoUrl: $photoUrl, createdAt: $createdAt)';
  }
}
