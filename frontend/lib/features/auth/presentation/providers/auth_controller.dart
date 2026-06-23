import 'package:kerosene/features/auth/controller/auth_controller.dart';
import 'package:kerosene/features/auth/domain/entities/login_result.dart';
import 'package:kerosene/features/auth/domain/usecases/login_usecase.dart';

extension AuthControllerDirectRequests on AuthController {
  Future<LoginResult> executeLoginRequest({
    required String username,
    required String passphrase,
  }) async {
    final result = await loginUseCase(
      LoginParams(username: username, passphrase: passphrase),
    );
    return result.fold(
      (failure) => throw Exception(failure.message),
      (loginResult) => loginResult,
    );
  }

  Future<void> executeTotpVerification({
    required String username,
    required String totpCode,
    required String preAuthToken,
  }) async {
    await verifyLoginTotp(
      username: username,
      passphrase: '',
      totpCode: totpCode,
      preAuthToken: preAuthToken,
    );
  }
}
