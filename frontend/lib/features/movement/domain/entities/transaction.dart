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

  /// Carteira relacionada ao lançamento quando a API informa.
  final String? walletId;

  /// Carteira de origem quando a API informa.
  final String? sourceWalletId;

  /// Carteira de destino quando a API informa.
  final String? destinationWalletId;

  /// Nome ou identificador seguro do remetente quando a API fornece.
  final String? senderDisplayName;

  /// Nome ou identificador seguro do destinatário quando a API fornece.
  final String? receiverDisplayName;

  /// Valor em satoshis
  final int amountSatoshis;

  /// Taxa de rede em satoshis
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

  /// TXID on-chain quando a entrada do ledger referencia uma transação externa.
  final String? blockchainTxid;

  /// Referência externa do provedor ou invoice.
  final String? externalReference;

  /// Identificador do invoice no provedor.
  final String? invoiceId;

  /// BOLT11 ou payload do invoice Lightning.
  final String? lightningInvoice;

  /// Payment hash Lightning.
  final String? paymentHash;

  /// UUID interno do ExternalTransfer, usado para ações self-service.
  final String? externalTransferId;

  /// Status bruto do ExternalTransfer, quando a transação veio desse fluxo.
  final String? externalTransferStatus;

  /// Tipo bruto do ExternalTransfer, por exemplo INBOUND_INVOICE.
  final String? externalTransferType;

  /// Descrição/nota da transação
  final String? description;

  /// Indica se é uma transação interna (entre usuários da plataforma)
  final bool isInternal;

  /// Indica se é uma transação Lightning
  final bool isLightning;

  /// Indica se a transação possui taxa de rede exibível.
  final bool hasNetworkFee;

  /// Valor fiat congelado no momento da execução, em USD.
  final double? displayAmountUsd;

  /// Valor fiat congelado no momento da execução, em EUR.
  final double? displayAmountEur;

  /// Valor fiat congelado no momento da execução, em BRL.
  final double? displayAmountBrl;

  /// Cotação BTC/USD congelada no momento da execução.
  final double? displayBtcUsd;

  /// Cotação BTC/EUR congelada no momento da execução.
  final double? displayBtcEur;

  /// Cotação BTC/BRL congelada no momento da execução.
  final double? displayBtcBrl;

  const Transaction({
    required this.id,
    required this.fromAddress,
    required this.toAddress,
    this.walletId,
    this.sourceWalletId,
    this.destinationWalletId,
    this.senderDisplayName,
    this.receiverDisplayName,
    required this.amountSatoshis,
    required this.feeSatoshis,
    required this.status,
    required this.type,
    required this.confirmations,
    required this.timestamp,
    this.blockHash,
    this.blockHeight,
    this.blockchainTxid,
    this.externalReference,
    this.invoiceId,
    this.lightningInvoice,
    this.paymentHash,
    this.externalTransferId,
    this.externalTransferStatus,
    this.externalTransferType,
    this.description,
    this.isInternal = false,
    this.isLightning = false,
    this.hasNetworkFee = false,
    this.displayAmountUsd,
    this.displayAmountEur,
    this.displayAmountBrl,
    this.displayBtcUsd,
    this.displayBtcEur,
    this.displayBtcBrl,
  });

  /// Valor total (amount + fee)
  int get totalSatoshis => amountSatoshis + feeSatoshis;

  /// Valor em BTC
  double get amountBTC => amountSatoshis / 100000000.0;

  /// Taxa em BTC
  double get feeBTC => feeSatoshis / 100000000.0;

  /// Movimentos que reduzem o saldo do usuario.
  bool get isDebit =>
      type == TransactionType.send ||
      type == TransactionType.withdrawal ||
      type == TransactionType.fee;

  /// Movimentos que aumentam o saldo do usuario.
  bool get isCredit =>
      type == TransactionType.receive || type == TransactionType.deposit;

  /// Valor em BTC com sinal do ponto de vista do usuario atual.
  double get signedAmountBTC => isDebit ? -amountBTC : amountBTC;

  /// Verifica se a transação está confirmada (6+ confirmações)
  bool get isConfirmed => confirmations >= 6;

  /// Verifica se a transação está pendente
  bool get isPending => status == TransactionStatus.pending;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      'walletId': walletId,
      'sourceWalletId': sourceWalletId,
      'destinationWalletId': destinationWalletId,
      'senderDisplayName': senderDisplayName,
      'receiverDisplayName': receiverDisplayName,
      'amountSatoshis': amountSatoshis,
      'feeSatoshis': feeSatoshis,
      'status': status.name,
      'type': type.name,
      'confirmations': confirmations,
      'timestamp': timestamp.toIso8601String(),
      'blockHash': blockHash,
      'blockHeight': blockHeight,
      'blockchainTxid': blockchainTxid,
      'externalReference': externalReference,
      'invoiceId': invoiceId,
      'lightningInvoice': lightningInvoice,
      'paymentHash': paymentHash,
      'externalTransferId': externalTransferId,
      'externalTransferStatus': externalTransferStatus,
      'externalTransferType': externalTransferType,
      'description': description,
      'isInternal': isInternal,
      'isLightning': isLightning,
      'hasNetworkFee': hasNetworkFee,
      'displayAmountUsd': displayAmountUsd,
      'displayAmountEur': displayAmountEur,
      'displayAmountBrl': displayAmountBrl,
      'displayBtcUsd': displayBtcUsd,
      'displayBtcEur': displayBtcEur,
      'displayBtcBrl': displayBtcBrl,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('grossAmountSats') ||
        json.containsKey('receiverAmountSats') ||
        json.containsKey('totalDebitSats')) {
      return _fromKfeJson(json);
    }

    // If it's from local storage (newly added format)
    if (json.containsKey('status') &&
        json['status'] is String &&
        json.containsKey('amountSatoshis')) {
      return Transaction(
        id: json['id'],
        fromAddress: json['fromAddress'],
        toAddress: json['toAddress'],
        walletId: json['walletId']?.toString(),
        sourceWalletId: json['sourceWalletId']?.toString(),
        destinationWalletId: json['destinationWalletId']?.toString(),
        senderDisplayName: json['senderDisplayName']?.toString(),
        receiverDisplayName: json['receiverDisplayName']?.toString(),
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
        blockchainTxid: json['blockchainTxid']?.toString(),
        externalReference: json['externalReference']?.toString(),
        invoiceId: json['invoiceId']?.toString(),
        lightningInvoice: json['lightningInvoice']?.toString(),
        paymentHash: json['paymentHash']?.toString(),
        externalTransferId: json['externalTransferId']?.toString(),
        externalTransferStatus: json['externalTransferStatus']?.toString(),
        externalTransferType: json['externalTransferType']?.toString(),
        description: json['description'],
        isInternal: json['isInternal'] ?? false,
        isLightning: json['isLightning'] ?? false,
        hasNetworkFee: json['hasNetworkFee'] == true,
        displayAmountUsd: _parseDouble(_firstJsonValue(json, const [
          'displayAmountUsd',
          'historicalAmountUsd',
          'amountUsd',
        ])),
        displayAmountEur: _parseDouble(_firstJsonValue(json, const [
          'displayAmountEur',
          'historicalAmountEur',
          'amountEur',
        ])),
        displayAmountBrl: _parseDouble(_firstJsonValue(json, const [
          'displayAmountBrl',
          'historicalAmountBrl',
          'amountBrl',
        ])),
        displayBtcUsd: _parseDouble(_firstJsonValue(json, const [
          'displayBtcUsd',
          'btcUsdSnapshot',
          'btcUsd',
        ])),
        displayBtcEur: _parseDouble(_firstJsonValue(json, const [
          'displayBtcEur',
          'btcEurSnapshot',
          'btcEur',
        ])),
        displayBtcBrl: _parseDouble(_firstJsonValue(json, const [
          'displayBtcBrl',
          'btcBrlSnapshot',
          'btcBrl',
        ])),
      );
    }

    // LedgerSyncEventDTO / sanitized ephemeral API payload format
    final amountVal = (json['amount'] as num?)?.toDouble() ?? 0.0;
    final networkFee = (json['networkFee'] as num?)?.toDouble() ?? 0.0;
    final currentUserId = _parseInt(
      json['currentUserId'] ??
          json['currentUserID'] ??
          json['userId'] ??
          json['authenticatedUserId'],
    );
    final senderUserId = _parseInt(
      json['senderUserId'] ??
          json['senderUserID'] ??
          json['payerUserId'] ??
          json['fromUserId'],
    );
    final receiverUserId = _parseInt(
      json['receiverUserId'] ??
          json['receiverUserID'] ??
          json['payeeUserId'] ??
          json['toUserId'],
    );

    final senderField = [
      json['senderIdentifier'],
      json['sender'],
      json['from'],
      json['fromAddress'],
    ]
        .map((e) => e?.toString())
        .firstWhere((e) => e != null && e.isNotEmpty, orElse: () => null);

    final receiverField = [
      json['receiverIdentifier'],
      json['receiver'],
      json['to'],
      json['toAddress'],
    ]
        .map((e) => e?.toString())
        .firstWhere((e) => e != null && e.isNotEmpty, orElse: () => null);
    final currentUserIdentifier = [
      json['currentUsername'],
      json['currentUserName'],
      json['currentWalletName'],
      json['currentWalletAddress'],
    ]
        .map((e) => e?.toString())
        .firstWhere((e) => e != null && e.isNotEmpty, orElse: () => null);
    final rawWalletId = json['walletId']?.toString();
    final rawSourceWalletId = json['sourceWalletId']?.toString();
    final rawDestinationWalletId = json['destinationWalletId']?.toString();

    final typeField =
        (json['transactionType'] ?? json['type'])?.toString().toUpperCase() ??
            '';
    final transferTypeField =
        (json['externalTransferType'] ?? json['transferType'])
                ?.toString()
                .toUpperCase() ??
            '';
    final directionField = (json['direction'] ??
                json['ledgerDirection'] ??
                json['movement'] ??
                json['operation'] ??
                json['entryType'] ??
                json['side'] ??
                json['amountDirection'])
            ?.toString()
            .toUpperCase() ??
        '';
    final contextField =
        (json['context'] ?? json['description'])?.toString().toUpperCase() ??
            '';
    final confirmations =
        _parseInt(json['confirmations']) ?? _parseInt(json['nonce']) ?? 0;
    final txType = _resolveType(
      typeField: typeField,
      transferTypeField: transferTypeField,
      contextField: contextField,
      directionField: directionField,
      amountVal: amountVal,
      currentUserId: currentUserId,
      senderUserId: senderUserId,
      receiverUserId: receiverUserId,
      currentUserIdentifier: currentUserIdentifier,
      senderIdentifier: senderField,
      receiverIdentifier: receiverField,
    );
    final txStatus = _resolveStatus(
      rawStatus: json['status']?.toString(),
      confirmations: confirmations,
    );
    final createdAt = _parseDateTime(json['createdAt'] ?? json['timestamp']);

    return Transaction(
      id: (json['id'] ?? json['blockchainTxid'] ?? '').toString(),
      fromAddress: senderField ??
          (txType == TransactionType.send ||
                  txType == TransactionType.withdrawal
              ? 'Minha carteira'
              : 'Rede Bitcoin'),
      toAddress: receiverField ??
          (txType == TransactionType.send ||
                  txType == TransactionType.withdrawal
              ? 'Rede Bitcoin'
              : 'Minha carteira'),
      walletId: rawWalletId,
      sourceWalletId: rawSourceWalletId,
      destinationWalletId: rawDestinationWalletId,
      amountSatoshis: (amountVal.abs() * 100000000).round(),
      feeSatoshis: (networkFee.abs() * 100000000).round(),
      status: txStatus,
      type: txType,
      confirmations: confirmations,
      timestamp: createdAt ?? DateTime.now(),
      description:
          json['context']?.toString() ?? json['description']?.toString(),
      blockchainTxid: json['blockchainTxid']?.toString(),
      externalReference: json['externalReference']?.toString(),
      invoiceId: json['invoiceId']?.toString(),
      lightningInvoice: json['lightningInvoice']?.toString(),
      paymentHash: json['paymentHash']?.toString(),
      externalTransferId: json['externalTransferId']?.toString() ??
          json['externalTransferID']?.toString(),
      externalTransferStatus: json['externalTransferStatus']?.toString(),
      externalTransferType: json['externalTransferType']?.toString() ??
          json['transferType']?.toString(),
      isInternal: typeField == 'INTERNAL' ||
          typeField == 'TRANSFER' ||
          typeField == 'TRANSACTION_SEND' ||
          typeField == 'TRANSACTION_RECEIVE' ||
          json['context'] == 'transfer' ||
          (json['description']?.toString().toLowerCase().contains('transfer') ??
              false),
      isLightning: typeField.contains('LIGHTNING') ||
          (json['description']?.toString().toUpperCase().contains(
                    'LIGHTNING',
                  ) ??
              false) ||
          (json['context']?.toString().toUpperCase().contains('LIGHTNING') ??
              false),
      displayAmountUsd: _parseDouble(_firstJsonValue(json, const [
        'displayAmountUsd',
        'historicalAmountUsd',
        'amountUsd',
      ])),
      displayAmountEur: _parseDouble(_firstJsonValue(json, const [
        'displayAmountEur',
        'historicalAmountEur',
        'amountEur',
      ])),
      displayAmountBrl: _parseDouble(_firstJsonValue(json, const [
        'displayAmountBrl',
        'historicalAmountBrl',
        'amountBrl',
      ])),
      displayBtcUsd: _parseDouble(_firstJsonValue(json, const [
        'displayBtcUsd',
        'btcUsdSnapshot',
        'btcUsd',
      ])),
      displayBtcEur: _parseDouble(_firstJsonValue(json, const [
        'displayBtcEur',
        'btcEurSnapshot',
        'btcEur',
      ])),
      displayBtcBrl: _parseDouble(_firstJsonValue(json, const [
        'displayBtcBrl',
        'btcBrlSnapshot',
        'btcBrl',
      ])),
    );
  }

  static Transaction _fromKfeJson(Map<String, dynamic> json) {
    final rail = json['rail']?.toString().toUpperCase() ?? '';
    final direction = json['direction']?.toString().toUpperCase() ?? '';
    final walletId = json['walletId']?.toString();
    final sourceWalletId = json['sourceWalletId']?.toString();
    final destinationWalletId = json['destinationWalletId']?.toString();
    final externalReference = json['externalReference']?.toString();
    final grossAmountSats = _parseInt(json['grossAmountSats']) ??
        _parseInt(json['amountSats']) ??
        0;
    final receiverAmountSats =
        _parseInt(json['receiverAmountSats']) ?? grossAmountSats;
    final networkFeeSats = _parseInt(json['networkFeeSats']) ?? 0;
    final confirmations = _parseInt(json['confirmations']) ?? 0;
    final isLightning = rail == 'LIGHTNING';
    final isInternal = rail == 'INTERNAL' || direction == 'INTERNAL';
    final isCredit = direction == 'INBOUND' ||
        (isInternal &&
            walletId != null &&
            destinationWalletId != null &&
            walletId == destinationWalletId);
    final txType = isCredit
        ? TransactionType.receive
        : isInternal
            ? TransactionType.send
            : direction == 'INBOUND'
                ? TransactionType.deposit
                : TransactionType.withdrawal;
    final status = _resolveKfeStatus(
      json['status']?.toString(),
      confirmations: confirmations,
    );
    final blockchainTxid = json['blockchainTxid']?.toString();
    final id = [
      blockchainTxid,
      json['transactionId']?.toString(),
      json['id']?.toString(),
    ].firstWhere(
      (value) => value != null && value.trim().isNotEmpty,
      orElse: () => '',
    )!;

    return Transaction(
      id: id,
      fromAddress: sourceWalletId ?? (isCredit ? 'Rede Bitcoin' : ''),
      toAddress: destinationWalletId ?? externalReference ?? '',
      walletId: walletId,
      sourceWalletId: sourceWalletId,
      destinationWalletId: destinationWalletId,
      amountSatoshis: receiverAmountSats.abs(),
      feeSatoshis: networkFeeSats.abs(),
      status: status,
      type: txType,
      confirmations: confirmations,
      timestamp: _parseDateTime(json['createdAt'] ?? json['timestamp']) ??
          DateTime.now(),
      blockchainTxid: blockchainTxid,
      externalReference: externalReference,
      paymentHash: json['paymentHash']?.toString(),
      description: json['memo']?.toString() ??
          (status == TransactionStatus.confirming
              ? 'Transação detectada, aguardando confirmações'
              : null),
      isInternal: isInternal,
      isLightning: isLightning,
      hasNetworkFee: networkFeeSats.abs() > 0,
      displayAmountUsd: _parseDouble(_firstJsonValue(json, const [
        'displayAmountUsd',
        'historicalAmountUsd',
        'amountUsd',
      ])),
      displayAmountEur: _parseDouble(_firstJsonValue(json, const [
        'displayAmountEur',
        'historicalAmountEur',
        'amountEur',
      ])),
      displayAmountBrl: _parseDouble(_firstJsonValue(json, const [
        'displayAmountBrl',
        'historicalAmountBrl',
        'amountBrl',
      ])),
      displayBtcUsd: _parseDouble(_firstJsonValue(json, const [
        'displayBtcUsd',
        'btcUsdSnapshot',
        'btcUsd',
      ])),
      displayBtcEur: _parseDouble(_firstJsonValue(json, const [
        'displayBtcEur',
        'btcEurSnapshot',
        'btcEur',
      ])),
      displayBtcBrl: _parseDouble(_firstJsonValue(json, const [
        'displayBtcBrl',
        'btcBrlSnapshot',
        'btcBrl',
      ])),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return double.tryParse(raw.replaceAll(',', '.'));
  }

  static Object? _firstJsonValue(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return null;
    }
    final hasExplicitOffset = RegExp(
      r'(z|[+-]\d{2}:?\d{2})$',
      caseSensitive: false,
    ).hasMatch(raw);
    if (parsed.isUtc || hasExplicitOffset) {
      return parsed.toLocal();
    }
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    ).toLocal();
  }

  static TransactionType _resolveType({
    required String typeField,
    required String transferTypeField,
    required String contextField,
    required String directionField,
    required double amountVal,
    required int? currentUserId,
    required int? senderUserId,
    required int? receiverUserId,
    required String? currentUserIdentifier,
    required String? senderIdentifier,
    required String? receiverIdentifier,
  }) {
    final typeParts = [
      typeField,
      transferTypeField,
      directionField,
      contextField,
    ].where((value) => value.trim().isNotEmpty).join('|');

    if (typeField == 'INTERNAL' || typeField == 'TRANSFER') {
      if (currentUserId != null) {
        if (senderUserId == currentUserId && receiverUserId != currentUserId) {
          return TransactionType.send;
        }
        if (receiverUserId == currentUserId && senderUserId != currentUserId) {
          return TransactionType.receive;
        }
      }
      if (_containsAny(directionField, const [
        'OUTGOING',
        'OUTBOUND',
        'DEBIT',
        'SENT',
        'SEND',
        'PAYER',
      ])) {
        return TransactionType.send;
      }
      if (_containsAny(directionField, const [
        'INCOMING',
        'INBOUND',
        'CREDIT',
        'RECEIVED',
        'RECEIVE',
        'PAYEE',
      ])) {
        return TransactionType.receive;
      }
      final currentIdentifier = _normalizeIdentity(currentUserIdentifier);
      final sender = _normalizeIdentity(senderIdentifier);
      final receiver = _normalizeIdentity(receiverIdentifier);
      if (currentIdentifier.isNotEmpty) {
        if (sender == currentIdentifier && receiver != currentIdentifier) {
          return TransactionType.send;
        }
        if (receiver == currentIdentifier && sender != currentIdentifier) {
          return TransactionType.receive;
        }
      }
    }

    if (_containsAny(typeParts, const [
      'EXTERNAL_WITHDRAWAL',
      'WITHDRAWAL',
      'TRANSACTION_SEND',
      'TRANSFER_SENT',
      'PAYMENT_SENT',
      'PAYMENT_INTERNAL_DEBIT',
      'INTERNAL_DEBIT',
      'LEDGER_DEBIT',
      'OUTBOUND_PAYMENT',
      'OUTBOUND',
      'OUTGOING',
      'DEBIT',
      'SEND',
      'SENT',
      'CASHOUT',
      'CASH_OUT',
    ])) {
      return TransactionType.withdrawal;
    }

    if (_containsAny(typeParts, const [
      'EXTERNAL_DEPOSIT',
      'DEPOSIT',
      'TRANSACTION_RECEIVE',
      'TRANSFER_RECEIVED',
      'PAYMENT_RECEIVED',
      'PAYMENT_INTERNAL_CREDIT',
      'INTERNAL_CREDIT',
      'LEDGER_CREDIT',
      'INBOUND_INVOICE',
      'INBOUND',
      'INCOMING',
      'CREDIT',
      'RECEIVE',
      'RECEIVED',
    ])) {
      return TransactionType.deposit;
    }

    return amountVal < 0 ? TransactionType.send : TransactionType.receive;
  }

  static bool _containsAny(String value, List<String> tokens) {
    return tokens.any(value.contains);
  }

  static String _normalizeIdentity(String? value) {
    return (value ?? '').trim().toLowerCase().replaceAll(RegExp(r'^@+'), '');
  }

  static TransactionStatus _resolveStatus({
    required String? rawStatus,
    required int confirmations,
  }) {
    final normalized = rawStatus?.toUpperCase() ?? 'PENDING';

    switch (normalized) {
      case 'CONCLUDED':
      case 'COMPLETED':
      case 'PAID':
        return TransactionStatus.confirmed;
      case 'VERIFYING_ONBOARDING':
        return TransactionStatus.confirming;
      case 'PENDING':
        return confirmations > 0
            ? TransactionStatus.confirming
            : TransactionStatus.pending;
      case 'CANCELED':
      case 'CANCELLED':
      case 'EXPIRED':
      case 'FAILED':
        return TransactionStatus.failed;
      default:
        return confirmations > 0
            ? TransactionStatus.confirming
            : TransactionStatus.pending;
    }
  }

  static TransactionStatus _resolveKfeStatus(
    String? rawStatus, {
    int confirmations = 0,
  }) {
    switch (rawStatus?.toUpperCase()) {
      case 'SETTLED':
        return TransactionStatus.confirmed;
      case 'FAILED':
      case 'REQUIRES_RECONCILIATION':
        return TransactionStatus.failed;
      case 'EXECUTING':
      case 'LOCKED':
      case 'QUORUM_SYNC':
      case 'VALIDATING':
        return confirmations > 0
            ? TransactionStatus.confirming
            : TransactionStatus.pending;
      case 'INTENT':
      default:
        return TransactionStatus.pending;
    }
  }

  @override
  List<Object?> get props => [
        id,
        fromAddress,
        toAddress,
        walletId,
        sourceWalletId,
        destinationWalletId,
        senderDisplayName,
        receiverDisplayName,
        amountSatoshis,
        feeSatoshis,
        status,
        type,
        confirmations,
        timestamp,
        blockHash,
        blockHeight,
        blockchainTxid,
        externalReference,
        invoiceId,
        lightningInvoice,
        paymentHash,
        externalTransferId,
        externalTransferStatus,
        externalTransferType,
        description,
        isInternal,
        isLightning,
        hasNetworkFee,
        displayAmountUsd,
        displayAmountEur,
        displayAmountBrl,
        displayBtcUsd,
        displayBtcEur,
        displayBtcBrl,
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
  fee('Fee', 'Network fee'),

  /// Saque (Withdrawal)
  withdrawal('Withdrawal', 'Sent Bitcoin to external address'),

  /// Depósito (Deposit)
  deposit('Deposit', 'Received Bitcoin from external address');

  const TransactionType(this.displayName, this.description);

  final String displayName;
  final String description;
}
