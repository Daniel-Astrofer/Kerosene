import 'package:equatable/equatable.dart';

/// Entidade Wallet - Carteira Bitcoin/DeFi
/// Representa uma carteira HD (Hierarchical Deterministic) seguindo BIP32/BIP44
final class Wallet extends Equatable {
  /// Identificador único da carteira
  final String id;

  /// Nome da carteira (ex: "Chase Card", "Savings Wallet")
  final String name;

  /// Endereço Bitcoin principal (derivado do HD path)
  final String address;

  /// Hash da passphrase retornado pela API autenticada.
  final String passphraseHash;

  /// Saldo em BTC (exatamente como vem da API)
  final double balance;

  /// Path de derivação HD (ex: "m/84'/0'/0'/0/0" para Native SegWit)
  final String derivationPath;

  /// Tipo de carteira (SegWit, Legacy, Taproot)
  final WalletType type;

  /// Timestamp de criação
  final DateTime createdAt;

  /// Timestamp de última atualização
  final DateTime updatedAt;

  /// Indica se a carteira está ativa
  final bool isActive;

  /// Nível de segurança (STANDARD, SHAMIR, etc)
  final String accountSecurity;

  /// Perfil de cartão calculado pelo backend para taxas externas.
  final WalletCardType cardType;

  /// Taxa de saque externo aplicada pelo backend (ex: 0.009 = 0.9%).
  final double withdrawalFeeRate;

  /// Taxa de depósito externo aplicada pelo backend (ex: 0.009 = 0.9%).
  final double depositFeeRate;

  const Wallet({
    required this.id,
    required this.name,
    required this.address,
    this.passphraseHash = '',
    required this.balance,
    required this.derivationPath,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.accountSecurity = 'STANDARD',
    this.cardType = WalletCardType.bronze,
    this.withdrawalFeeRate = WalletCardType.bronzeDefaultFeeRate,
    this.depositFeeRate = WalletCardType.bronzeDefaultFeeRate,
  });

  /// Cria cópia com modificações
  Wallet copyWith({
    String? id,
    String? name,
    String? address,
    String? passphraseHash,
    double? balance,
    String? derivationPath,
    WalletType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? accountSecurity,
    WalletCardType? cardType,
    double? withdrawalFeeRate,
    double? depositFeeRate,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      passphraseHash: passphraseHash ?? this.passphraseHash,
      balance: balance ?? this.balance,
      derivationPath: derivationPath ?? this.derivationPath,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      accountSecurity: accountSecurity ?? this.accountSecurity,
      cardType: cardType ?? this.cardType,
      withdrawalFeeRate: withdrawalFeeRate ?? this.withdrawalFeeRate,
      depositFeeRate: depositFeeRate ?? this.depositFeeRate,
    );
  }

  factory Wallet.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    final balanceVal = data['balance'];
    final btcValue = (balanceVal is num) ? balanceVal.toDouble() : 0.0;
    final cardType = WalletCardType.fromApi(data['cardType']);

    return Wallet(
      id: (data['id'] ??
              data['walletId'] ??
              DateTime.now().millisecondsSinceEpoch)
          .toString(),
      name: data['name'] ?? data['walletName'] ?? 'Wallet',
      address: (data['depositAddress'] ??
              data['onchainAddress'] ??
              data['address'] ??
              '')
          .toString(),
      passphraseHash: data['passphraseHash']?.toString() ?? '',
      balance: btcValue,
      derivationPath: "m/84'/0'/0'",
      type: WalletType.nativeSegwit,
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      isActive: _parseBool(data['isActive'], fallback: true),
      accountSecurity: data['accountSecurity']?.toString() ?? 'STANDARD',
      cardType: cardType,
      withdrawalFeeRate: _parseFeeRate(
        data['withdrawalFeeRate'],
        cardType.defaultFeeRate,
      ),
      depositFeeRate: _parseFeeRate(
        data['depositFeeRate'],
        cardType.defaultFeeRate,
      ),
    );
  }

  static double _parseFeeRate(Object? value, double fallback) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim()) ?? fallback;
    }
    return fallback;
  }

  static DateTime _parseDateTime(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static bool _parseBool(Object? value, {required bool fallback}) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
        return false;
      }
    }
    return fallback;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        passphraseHash,
        balance,
        derivationPath,
        type,
        createdAt,
        updatedAt,
        isActive,
        accountSecurity,
        cardType,
        withdrawalFeeRate,
        depositFeeRate,
      ];
}

enum WalletCardType {
  bronze('BRONZE', 'Bronze', bronzeDefaultFeeRate),
  white('WHITE', 'White', 0.008),
  black('BLACK', 'Black', 0.007);

  const WalletCardType(this.apiValue, this.label, this.defaultFeeRate);

  static const double bronzeDefaultFeeRate = 0.009;

  final String apiValue;
  final String label;
  final double defaultFeeRate;

  static WalletCardType fromApi(Object? value) {
    final normalized = value?.toString().trim().toUpperCase();
    return WalletCardType.values.firstWhere(
      (type) => type.apiValue == normalized,
      orElse: () => WalletCardType.bronze,
    );
  }

  static String formatRate(double rate) {
    final percent = rate * 100;
    var fixed = percent.toStringAsFixed(2);
    fixed = fixed.replaceFirst(RegExp(r'\.?0+$'), '');
    return '$fixed%';
  }
}

/// Tipos de carteira Bitcoin
enum WalletType {
  /// Legacy (P2PKH) - Endereços começam com "1"
  legacy('Legacy', 'P2PKH'),

  /// SegWit (P2SH-P2WPKH) - Endereços começam com "3"
  segwit('SegWit', 'P2SH-P2WPKH'),

  /// Native SegWit (P2WPKH) - Endereços começam com "bc1q"
  nativeSegwit('Native SegWit', 'P2WPKH'),

  /// Taproot (P2TR) - Endereços começam com "bc1p"
  taproot('Taproot', 'P2TR');

  const WalletType(this.displayName, this.scriptType);

  final String displayName;
  final String scriptType;

  /// Derivation path BIP44 para cada tipo
  String get basePath {
    switch (this) {
      case WalletType.legacy:
        return "m/44'/0'/0'"; // BIP44
      case WalletType.segwit:
        return "m/49'/0'/0'"; // BIP49
      case WalletType.nativeSegwit:
        return "m/84'/0'/0'"; // BIP84
      case WalletType.taproot:
        return "m/86'/0'/0'"; // BIP86
    }
  }
}
