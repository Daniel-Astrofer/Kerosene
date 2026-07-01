import 'dart:convert';

import 'package:kerosene/core/config/app_config.dart';
import 'package:kerosene/core/network/api_client.dart';

abstract class KfeReceivingCapabilitiesService {
  Future<KfeReceivingCapabilities> receivingCapabilities(
    String receiverIdentifier,
  );
}

class RemoteKfeReceivingCapabilitiesService
    implements KfeReceivingCapabilitiesService {
  final ApiClient _api;

  const RemoteKfeReceivingCapabilitiesService(this._api);

  @override
  Future<KfeReceivingCapabilities> receivingCapabilities(
    String receiverIdentifier,
  ) async {
    final response = await _api.get(
      AppConfig.kfeReceivingCapabilities(receiverIdentifier),
    );
    return KfeReceivingCapabilities.fromJson(_mapFrom(response.data));
  }
}

class KfeReceivingCapabilities {
  final bool canReceiveInternal;
  final bool canReceiveLightning;
  final bool canReceiveOnchain;
  final String preferredRail;
  final List<String> missingRequirements;
  final String receiverDisplayName;
  final String? internalWalletId;
  final List<String> availableRails;

  const KfeReceivingCapabilities({
    required this.canReceiveInternal,
    required this.canReceiveLightning,
    required this.canReceiveOnchain,
    required this.preferredRail,
    required this.missingRequirements,
    required this.receiverDisplayName,
    this.internalWalletId,
    required this.availableRails,
  });

  factory KfeReceivingCapabilities.fromJson(Map<String, dynamic> json) {
    final payload = _payloadFrom(json);
    return KfeReceivingCapabilities(
      canReceiveInternal: _boolFrom(payload['canReceiveInternal']),
      canReceiveLightning: _boolFrom(payload['canReceiveLightning']),
      canReceiveOnchain: _boolFrom(payload['canReceiveOnchain']),
      preferredRail: _trimmedOrNull(payload['preferredRail']) ?? '',
      missingRequirements: _stringList(payload['missingRequirements']),
      receiverDisplayName:
          _trimmedOrNull(payload['receiverDisplayName']) ?? 'Kerosene user',
      internalWalletId: _trimmedOrNull(payload['internalWalletId']),
      availableRails: _stringList(payload['availableRails']),
    );
  }
}

Map<String, dynamic> _mapFrom(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        return _mapFrom(jsonDecode(trimmed));
      } catch (_) {
        return const {};
      }
    }
  }
  return const {};
}

Map<String, dynamic> _payloadFrom(Map<String, dynamic> json) {
  if (!json.containsKey('success')) return json;

  final data = _mapFrom(json['data']);
  return data.isEmpty ? json : data;
}

bool _boolFrom(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    return switch (value.trim().toLowerCase()) {
      'true' || '1' || 'yes' || 'y' => true,
      _ => false,
    };
  }
  return false;
}

String? _trimmedOrNull(Object? value) {
  final trimmed = value?.toString().trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

List<String> _stringList(Object? value) {
  if (value is Iterable) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  return const [];
}
