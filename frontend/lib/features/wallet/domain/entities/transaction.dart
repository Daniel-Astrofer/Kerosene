import 'package:equatable/equatable.dart';

/// Entidade Transaction - Transação Bitcoin
/// Representa uma transação na blockchain ou pendente
final class Transaction extends Equatable {
  /// ID da transação (txid - hash SHA256)
  final String id;

  /// Endereço de origem
  final String fromAddress;

  /// Endereço de destino
  final String toAddress;

  /// Valor em satoshis
  final int amountSatoshis;

  /// Taxa de mineração em satoshis
  final int feeSatoshis;

  /// Status da transação
  final TransactionStatus status;

  /// Tipo de transação
  final TransactionType type;

  /// Número de confirmações na blockchain
  final int confirmations;

  /// Timestamp da transação
  final DateTime timestamp;

  /// Hash do bloco (null se pendente)
  final String? blockHash;

  /// Altura do bloco (null se pendente)
  final int? blockHeight;

  /// Descrição/nota da transação
  final String? description;

  const Transaction({
    required this.id,
    required this.fromAddress,
    required this.toAddress,
    required this.amountSatoshis,
    required this.feeSatoshis,
    required this.status,
    required this.type,
    required this.confirmations,
    required this.timestamp,
    this.blockHash,
    this.blockHeight,
    this.description,
  });

  /// Valor total (amount + fee)
  int get totalSatoshis => amountSatoshis + feeSatoshis;

  /// Valor em BTC
  double get amountBTC => amountSatoshis / 100000000.0;

  /// Taxa em BTC
  double get feeBTC => feeSatoshis / 100000000.0;

  /// Verifica se a transação está confirmada (6+ confirmações)
  bool get isConfirmed => confirmations >= 6;

  /// Verifica se a transação está pendente
  bool get isPending => status == TransactionStatus.pending;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      'amountSatoshis': amountSatoshis,
      'feeSatoshis': feeSatoshis,
      'status': status.name,
      'type': type.name,
      'confirmations': confirmations,
      'timestamp': timestamp.toIso8601String(),
      'blockHash': blockHash,
      'blockHeight': blockHeight,
      'description': description,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // If it's from local storage (newly added format)
    if (json.containsKey('status') && json['status'] is String) {
      return Transaction(
        id: json['id'],
        fromAddress: json['fromAddress'],
        toAddress: json['toAddress'],
        amountSatoshis: json['amountSatoshis'] is int
            ? json['amountSatoshis']
            : (json['amountSatoshis'] as num).toInt(),
        feeSatoshis: json['feeSatoshis'] is int
            ? json['feeSatoshis']
            : (json['feeSatoshis'] as num).toInt(),
        status: TransactionStatus.values.firstWhere(
          (e) => e.name == json['status'],
        ),
        type: TransactionType.values.firstWhere((e) => e.name == json['type']),
        confirmations: json['confirmations'],
        timestamp: DateTime.parse(json['timestamp']),
        blockHash: json['blockHash'],
        blockHeight: json['blockHeight'],
        description: json['description'],
      );
    }

    // Original Ledger API format
    final amountVal = json['amount'] as num? ?? 0;
    final isNegative = amountVal < 0;

    return Transaction(
      id: (json['id'] ?? '').toString(),
      fromAddress: json['sender'] ?? (isNegative ? 'Me' : 'External'),
      toAddress: json['receiver'] ?? (isNegative ? 'External' : 'Me'),
      amountSatoshis: amountVal.abs().toInt(),
      feeSatoshis: 0,
      status: TransactionStatus.confirmed,
      type: isNegative ? TransactionType.send : TransactionType.receive,
      confirmations: (json['nonce'] ?? 6) as int,
      timestamp: DateTime.now(),
      description: json['context'] ?? json['walletName'],
    );
  }

  @override
  List<Object?> get props => [
    id,
    fromAddress,
    toAddress,
    amountSatoshis,
    feeSatoshis,
    status,
    type,
    confirmations,
    timestamp,
    blockHash,
    blockHeight,
    description,
  ];
}

/// Status da transação
enum TransactionStatus {
  /// Pendente (não confirmada)
  pending('Pending', 'Waiting for confirmation'),

  /// Confirmando (1-5 confirmações)
  confirming('Confirming', 'Being confirmed'),

  /// Confirmada (6+ confirmações)
  confirmed('Confirmed', 'Transaction confirmed'),

  /// Falhou
  failed('Failed', 'Transaction failed');

  const TransactionStatus(this.displayName, this.description);

  final String displayName;
  final String description;
}

/// Tipo de transação
enum TransactionType {
  /// Envio de Bitcoin
  send('Send', 'Sent Bitcoin'),

  /// Recebimento de Bitcoin
  receive('Receive', 'Received Bitcoin'),

  /// Swap/Exchange
  swap('Swap', 'Token swap'),

  /// Taxa de rede
  fee('Fee', 'Network fee');

  const TransactionType(this.displayName, this.description);

  final String displayName;
  final String description;
}
