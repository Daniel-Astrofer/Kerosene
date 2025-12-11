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

  /// Saldo em satoshis (1 BTC = 100,000,000 satoshis)
  /// Usar int64 para evitar problemas de precisão com double
  final int balanceSatoshis;

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

  const Wallet({
    required this.id,
    required this.name,
    required this.address,
    required this.balanceSatoshis,
    required this.derivationPath,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  /// Saldo em BTC (conversão de satoshis)
  double get balanceBTC => balanceSatoshis / 100000000.0;

  /// Saldo formatado em USD (requer taxa de câmbio)
  String balanceInUSD(double btcToUsdRate) {
    final usdValue = balanceBTC * btcToUsdRate;
    return '\$${usdValue.toStringAsFixed(2)}';
  }

  /// Cria cópia com modificações
  Wallet copyWith({
    String? id,
    String? name,
    String? address,
    int? balanceSatoshis,
    String? derivationPath,
    WalletType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      balanceSatoshis: balanceSatoshis ?? this.balanceSatoshis,
      derivationPath: derivationPath ?? this.derivationPath,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  factory Wallet.fromJson(Map<String, dynamic> json) {
    final balanceVal = json['balance'];
    final satoshis = (balanceVal is num) ? balanceVal.toInt() : 0;

    return Wallet(
      id:
          (json['id'] ??
                  json['walletId'] ??
                  DateTime.now().millisecondsSinceEpoch)
              .toString(),
      name: json['name'] ?? json['walletName'] ?? 'Wallet',
      address:
          json['address'] ?? json['walletName'] ?? '', // Fallback para nome
      balanceSatoshis: satoshis,
      derivationPath: "m/84'/0'/0'",
      type: WalletType.nativeSegwit,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    address,
    balanceSatoshis,
    derivationPath,
    type,
    createdAt,
    updatedAt,
    isActive,
  ];
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
