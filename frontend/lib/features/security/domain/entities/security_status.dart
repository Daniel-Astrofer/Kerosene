import 'package:equatable/equatable.dart';

class SecurityStatus extends Equatable {
  final Map<String, dynamic> hardwareAttestation;
  final Map<String, dynamic> networkConsensus;
  final Map<String, dynamic> ledgerIntegrity;
  final Map<String, dynamic> memoryProtection;
  final int serverUptimeSeconds;

  const SecurityStatus({
    required this.hardwareAttestation,
    required this.networkConsensus,
    required this.ledgerIntegrity,
    required this.memoryProtection,
    required this.serverUptimeSeconds,
  });

  factory SecurityStatus.fromJson(Map<String, dynamic> json) {
    return SecurityStatus(
      hardwareAttestation: json['hardwareAttestation'] ?? {},
      networkConsensus: json['networkConsensus'] ?? {},
      ledgerIntegrity: json['ledgerIntegrity'] ?? {},
      memoryProtection: json['memoryProtection'] ?? {},
      serverUptimeSeconds: (json['serverUptimeSeconds'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        hardwareAttestation,
        networkConsensus,
        ledgerIntegrity,
        memoryProtection,
        serverUptimeSeconds,
      ];
}
