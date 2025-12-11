import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

/// Interface do AuthLocalDataSource
abstract class AuthLocalDataSource {
  /// Salvar JWT token
  Future<void> saveToken(String token);

  /// Obter JWT token
  Future<String?> getToken();

  /// Remover JWT token
  Future<void> removeToken();

  /// Salvar dados do usuário
  Future<void> saveUser(UserModel user);

  /// Obter dados do usuário
  Future<UserModel?> getUser();

  /// Remover dados do usuário
  Future<void> removeUser();

  /// Salvar TOTP secret
  Future<void> saveTotpSecret(String secret);

  /// Obter TOTP secret
  Future<String?> getTotpSecret();

  /// Remover TOTP secret
  Future<void> removeTotpSecret();

  /// Verificar se está autenticado
  Future<bool> isAuthenticated();

  /// Limpar todos os dados
  Future<void> clearAll();
}

/// Implementação do AuthLocalDataSource
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl(this.sharedPreferences);

  @override
  Future<void> saveToken(String token) async {
    try {
      await sharedPreferences.setString(AppConfig.authTokenKey, token);
    } catch (e) {
      throw CacheException(message: 'Erro ao salvar token: $e');
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return sharedPreferences.getString(AppConfig.authTokenKey);
    } catch (e) {
      throw CacheException(message: 'Erro ao obter token: $e');
    }
  }

  @override
  Future<void> removeToken() async {
    try {
      await sharedPreferences.remove(AppConfig.authTokenKey);
    } catch (e) {
      throw CacheException(message: 'Erro ao remover token: $e');
    }
  }

  @override
  Future<void> saveUser(UserModel user) async {
    try {
      final userJson = json.encode(user.toJson());
      await sharedPreferences.setString(AppConfig.userDataKey, userJson);
    } catch (e) {
      throw CacheException(message: 'Erro ao salvar usuário: $e');
    }
  }

  @override
  Future<UserModel?> getUser() async {
    try {
      final userJson = sharedPreferences.getString(AppConfig.userDataKey);
      if (userJson == null) return null;

      final userMap = json.decode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    } catch (e) {
      throw CacheException(message: 'Erro ao obter usuário: $e');
    }
  }

  @override
  Future<void> removeUser() async {
    try {
      await sharedPreferences.remove(AppConfig.userDataKey);
    } catch (e) {
      throw CacheException(message: 'Erro ao remover usuário: $e');
    }
  }

  @override
  Future<void> saveTotpSecret(String secret) async {
    try {
      await sharedPreferences.setString(AppConfig.totpSecretKey, secret);
    } catch (e) {
      throw CacheException(message: 'Erro ao salvar TOTP secret: $e');
    }
  }

  @override
  Future<String?> getTotpSecret() async {
    try {
      return sharedPreferences.getString(AppConfig.totpSecretKey);
    } catch (e) {
      throw CacheException(message: 'Erro ao obter TOTP secret: $e');
    }
  }

  @override
  Future<void> removeTotpSecret() async {
    try {
      await sharedPreferences.remove(AppConfig.totpSecretKey);
    } catch (e) {
      throw CacheException(message: 'Erro ao remover TOTP secret: $e');
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await removeToken();
      await removeUser();
      await removeTotpSecret();
    } catch (e) {
      throw CacheException(message: 'Erro ao limpar dados: $e');
    }
  }
}
