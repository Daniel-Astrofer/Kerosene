import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:kerosene/core/config/app_config.dart';
import 'package:kerosene/core/errors/exceptions.dart';
import 'package:kerosene/core/network/api_client.dart';
import 'package:kerosene/core/services/passkey_service.dart';
import 'package:kerosene/features/auth/domain/emergency_recovery_models.dart';

abstract class EmergencyRecoveryService {
  Future<EmergencyRecoveryStartResult> start(
    EmergencyRecoveryStartDraft draft,
  );

  Future<EmergencyRecoveryFinishResult> finish({
    required String username,
    required EmergencyRecoveryStartResult started,
    required String totpCode,
  });
}

class RemoteEmergencyRecoveryService implements EmergencyRecoveryService {
  final ApiClient _api;
  final PasskeyService _passkeyService;

  RemoteEmergencyRecoveryService(
    this._api, {
    PasskeyService? passkeyService,
  }) : _passkeyService = passkeyService ?? PasskeyService.instance;

  @override
  Future<EmergencyRecoveryStartResult> start(
    EmergencyRecoveryStartDraft draft,
  ) async {
    final challenge = await _powChallenge();
    final nonce = await compute(_solveEmergencyRecoveryPow, challenge);
    final response = await _api.post(
      AppConfig.authEmergencyRecoveryStart,
      data: {
        'username': draft.username.trim().toLowerCase(),
        'newPassphrase': draft.newPassphrase,
        'recoveryCodes': draft.recoveryCodes
            .map((code) => code.trim())
            .where((code) => code.isNotEmpty)
            .toList(growable: false),
        'challenge': challenge,
        'nonce': nonce,
      },
    );
    final result = EmergencyRecoveryStartResult.fromJson(
      _requireMap(response.data, 'start'),
    );
    if (!result.isUsable) {
      throw const ServerException(
        message: 'A sessão de recuperação voltou incompleta.',
        errorCode: 'ERR_RECOVERY_START_INVALID_RESPONSE',
      );
    }
    return result;
  }

  @override
  Future<EmergencyRecoveryFinishResult> finish({
    required String username,
    required EmergencyRecoveryStartResult started,
    required String totpCode,
  }) async {
    final credential = await _passkeyService.register(
      challengeHex: started.passkeyChallenge,
      username: username.trim().toLowerCase(),
    );
    final response = await _api.post(
      AppConfig.authEmergencyRecoveryFinish,
      data: {
        'recoverySessionId': started.recoverySessionId,
        'totpCode': totpCode.trim(),
        'publicKey': credential['publicKey'],
        'publicKeyCose': credential['publicKeyCose'],
        'deviceName': credential['deviceName'],
        'signature': credential['signature'],
        'authData': credential['authData'],
        'clientDataJSON': credential['clientDataJSON'],
        'credentialId': credential['credentialId'],
        'userHandle': credential['userHandle'],
      },
    );
    return EmergencyRecoveryFinishResult.fromJson(
      _requireMap(response.data, 'finish'),
    );
  }

  Future<String> _powChallenge() async {
    final response = await _api.get(AppConfig.authPowChallenge);
    final body = response.data;
    if (body is Map) {
      final challenge = body['challenge']?.toString().trim();
      if (challenge != null && challenge.isNotEmpty) {
        return challenge;
      }
    }
    throw const ServerException(
      message: 'Não conseguimos preparar a proteção da recuperação.',
      errorCode: 'ERR_RECOVERY_POW_CHALLENGE_INVALID_RESPONSE',
    );
  }

  static Map<String, dynamic> _requireMap(Object? data, String operation) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ServerException(
      message: 'Resposta inesperada do backend de recuperação.',
      errorCode: 'ERR_RECOVERY_${operation.toUpperCase()}_INVALID_RESPONSE',
      data: data,
    );
  }
}

String _solveEmergencyRecoveryPow(String challenge) {
  var nonce = 0;
  const prefix = '0000';
  while (nonce <= 10000000) {
    final digest = crypto.sha256.convert(utf8.encode('$challenge$nonce'));
    if (digest.toString().startsWith(prefix)) {
      return nonce.toString();
    }
    nonce++;
  }
  return nonce.toString();
}
