import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../models/user_model.dart';

/// Interface do AuthLocalDataSource
abstract class AuthLocalDataSource {
  /// Salvar JWT token
  Future<void> saveToken(String token);

  /// Obter JWT token
  Future<String?> getToken();

  /// Remover JWT token
  Future<void> removeToken();

  /// Obter username do usuário logado
  Future<String?> getUsername();

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

  /// Salvar Backup Codes
  Future<void> saveBackupCodes(List<String> codes);

  /// Obter Backup Codes
  Future<List<String>?> getBackupCodes();

  /// Remover Backup Codes
  Future<void> removeBackupCodes();

  /// Verificar se está autenticado
  Future<bool> isAuthenticated();

  /// Limpar todos os dados
  Future<void> clearAll();

  /// Salvar Mnemonic (Inseguro - Apenas para dev/demo se secure storage não estiver disponível)
  Future<void> saveMnemonic(String mnemonic);

  /// Obter Mnemonic
  Future<String?> getMnemonic();

  /// Definir se biometria está habilitada
  Future<void> setBiometricEnabled(bool enabled);

  /// Verificar se biometria está habilitada
  Future<bool> getBiometricEnabled();

  /// Salvar credenciais de login (Remember Me)
  Future<void> saveCredentials(String username, String passphrase);

  /// Obter credenciais de login salvas
  Future<Map<String, String>?> getCredentials();

  /// Remover credenciais de login salvas
  Future<void> removeCredentials();
}

/// Implementação do AuthLocalDataSource
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;
  final SecureStorageService secureStorage;

  AuthLocalDataSourceImpl(
    this.sharedPreferences, {
    SecureStorageService? secureStorage,
  }) : secureStorage = secureStorage ?? SecureStorageService();

  @override
  Future<void> saveToken(String token) async {
    try {
      await secureStorage.write(key: AppConfig.authTokenKey, value: token);
    } catch (e) {
      throw CacheException(message: 'Erro ao salvar token: $e');
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return await secureStorage.read(key: AppConfig.authTokenKey);
    } catch (e) {
      throw CacheException(message: 'Erro ao obter token: $e');
    }
  }

  @override
  Future<void> removeToken() async {
    try {
      await secureStorage.delete(key: AppConfig.authTokenKey);
    } catch (e) {
      throw CacheException(message: 'Erro ao remover token: $e');
    }
  }

  @override
  Future<String?> getUsername() async {
    try {
      final user = await getUser();
      return user?.username;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveUser(UserModel user) async {
    try {
      final userJson = json.encode(user.toJson());
      await secureStorage.write(key: AppConfig.userDataKey, value: userJson);
      await sharedPreferences.remove(AppConfig.userDataKey);
    } catch (e) {
      throw CacheException(message: 'Erro ao salvar usuário: $e');
    }
  }

  @override
  Future<UserModel?> getUser() async {
    try {
      var userJson = await secureStorage.read(key: AppConfig.userDataKey);
      final legacyUserJson = sharedPreferences.getString(AppConfig.userDataKey);
      if ((userJson == null || userJson.isEmpty) &&
          legacyUserJson != null &&
          legacyUserJson.isNotEmpty) {
        userJson = legacyUserJson;
        await secureStorage.write(
          key: AppConfig.userDataKey,
          value: legacyUserJson,
        );
        await sharedPreferences.remove(AppConfig.userDataKey);
      }
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
      await secureStorage.delete(key: AppConfig.userDataKey);
      await sharedPreferences.remove(AppConfig.userDataKey);
    } catch (e) {
      throw CacheException(message: 'Erro ao remover usuário: $e');
    }
  }

  @override
  Future<void> saveTotpSecret(String secret) async {
    try {
      await secureStorage.write(key: AppConfig.totpSecretKey, value: secret);
    } catch (e) {
      throw CacheException(message: 'Erro ao salvar TOTP secret: $e');
    }
  }

  @override
  Future<String?> getTotpSecret() async {
    try {
      return await secureStorage.read(key: AppConfig.totpSecretKey);
    } catch (e) {
      throw CacheException(message: 'Erro ao obter TOTP secret: $e');
    }
  }

  @override
  Future<void> removeTotpSecret() async {
    try {
      await secureStorage.delete(key: AppConfig.totpSecretKey);
    } catch (e) {
      throw CacheException(message: 'Erro ao remover TOTP secret: $e');
    }
  }

  @override
  Future<void> saveBackupCodes(List<String> codes) async {
    try {
      await secureStorage.write(
        key: AppConfig.backupCodesKey,
        value: jsonEncode(codes),
      );
    } catch (e) {
      throw CacheException(message: 'Erro ao salvar backup codes: $e');
    }
  }

  @override
  Future<List<String>?> getBackupCodes() async {
    try {
      final raw = await secureStorage.read(key: AppConfig.backupCodesKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded.map((item) => item.toString()).toList();
    } catch (e) {
      throw CacheException(message: 'Erro ao obter backup codes: $e');
    }
  }

  @override
  Future<void> removeBackupCodes() async {
    try {
      await secureStorage.delete(key: AppConfig.backupCodesKey);
    } catch (e) {
      throw CacheException(message: 'Erro ao remover backup codes: $e');
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      final looksLikeJwt = token.split('.').length == 3;
      if (!looksLikeJwt) {
        await removeToken();
        return false;
      }

      return true;
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
      await removeBackupCodes();
      await secureStorage.delete(key: 'auth_mnemonic');
      await secureStorage.delete(key: 'saved_username');
      await secureStorage.delete(key: 'saved_passphrase');
    } catch (e) {
      throw CacheException(message: 'Erro ao limpar dados: $e');
    }
  }

  @override
  Future<void> saveMnemonic(String mnemonic) async {
    try {
      await secureStorage.write(key: 'auth_mnemonic', value: mnemonic);
    } catch (e) {
      throw CacheException(message: 'Erro ao salvar mnemonic: $e');
    }
  }

  @override
  Future<String?> getMnemonic() async {
    try {
      return await secureStorage.read(key: 'auth_mnemonic');
    } catch (e) {
      throw CacheException(message: 'Erro ao obter mnemonic: $e');
    }
  }

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await sharedPreferences.setBool('auth_biometric_enabled', enabled);
    } catch (e) {
      throw CacheException(
        message: 'Erro ao salvar preferência biométrica: $e',
      );
    }
  }

  @override
  Future<bool> getBiometricEnabled() async {
    try {
      return sharedPreferences.getBool('auth_biometric_enabled') ?? false;
    } catch (e) {
      // Default info false if error
      return false;
    }
  }

  @override
  Future<void> saveCredentials(String username, String passphrase) async {
    try {
      await secureStorage.write(key: 'saved_username', value: username);
      await secureStorage.write(key: 'saved_passphrase', value: passphrase);
    } catch (e) {
      throw CacheException(message: 'Erro ao salvar credenciais: $e');
    }
  }

  @override
  Future<Map<String, String>?> getCredentials() async {
    try {
      final username = await secureStorage.read(key: 'saved_username');
      final passphrase = await secureStorage.read(key: 'saved_passphrase');

      if (username != null && passphrase != null) {
        return {'username': username, 'passphrase': passphrase};
      }
      return null;
    } catch (e) {
      throw CacheException(message: 'Erro ao obter credenciais: $e');
    }
  }

  @override
  Future<void> removeCredentials() async {
    try {
      await secureStorage.delete(key: 'saved_username');
      await secureStorage.delete(key: 'saved_passphrase');
    } catch (e) {
      throw CacheException(message: 'Erro ao remover credenciais: $e');
    }
  }
}
