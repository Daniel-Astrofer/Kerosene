import 'package:teste/features/mining/data/models/mempool_market_models.dart';
import 'package:teste/features/wallet/domain/entities/transaction.dart';

enum MiningExplorerRail { blockchain, lightning, internal }

class MiningExplorerDescriptor {
  final MiningExplorerRail rail;
  final String buttonLabel;
  final String badgeLabel;
  final String? txid;
  final int? blockHeight;
  final String? blockHash;
  final String reference;

  const MiningExplorerDescriptor({
    required this.rail,
    required this.buttonLabel,
    required this.badgeLabel,
    required this.txid,
    required this.blockHeight,
    required this.blockHash,
    required this.reference,
  });

  bool get canLookupOnchain =>
      rail == MiningExplorerRail.blockchain &&
      txid != null &&
      txid!.trim().isNotEmpty;

  factory MiningExplorerDescriptor.fromTransaction(Transaction transaction) {
    final txid = _normalizeTxid(
      transaction.blockchainTxid ?? transaction.id,
    );

    if (transaction.isInternal) {
      return MiningExplorerDescriptor(
        rail: MiningExplorerRail.internal,
        buttonLabel: 'Fluxo',
        badgeLabel: 'Interna',
        txid: txid,
        blockHeight: transaction.blockHeight,
        blockHash: transaction.blockHash,
        reference: transaction.id,
      );
    }

    if (_looksLikeLightningTransaction(transaction)) {
      return MiningExplorerDescriptor(
        rail: MiningExplorerRail.lightning,
        buttonLabel: 'Lightning',
        badgeLabel: 'Lightning',
        txid: txid,
        blockHeight: transaction.blockHeight,
        blockHash: transaction.blockHash,
        reference: transaction.blockchainTxid ?? transaction.id,
      );
    }

    return MiningExplorerDescriptor(
      rail: MiningExplorerRail.blockchain,
      buttonLabel: 'Blockchain',
      badgeLabel: 'On-chain',
      txid: txid,
      blockHeight: transaction.blockHeight,
      blockHash: transaction.blockHash,
      reference: transaction.blockchainTxid ?? transaction.id,
    );
  }
}

int? estimateProjectedBlockIndex(
  List<MempoolFeeBlock> blocks,
  double feeRate,
) {
  if (blocks.isEmpty) {
    return null;
  }

  for (var i = 0; i < blocks.length; i++) {
    final minimumFee = blockMinimumFee(blocks[i]);
    if (feeRate >= minimumFee) {
      return i;
    }
  }

  return blocks.length - 1;
}

double blockMinimumFee(MempoolFeeBlock block) {
  if (block.feeRange.isEmpty) {
    return block.medianFee;
  }
  return block.feeRange
      .reduce((current, next) => current < next ? current : next);
}

double blockMaximumFee(MempoolFeeBlock block) {
  if (block.feeRange.isEmpty) {
    return block.medianFee;
  }
  return block.feeRange
      .reduce((current, next) => current > next ? current : next);
}

String shortHash(
  String value, {
  int leading = 10,
  int trailing = 8,
}) {
  final normalized = value.trim();
  if (normalized.length <= leading + trailing + 1) {
    return normalized;
  }
  return '${normalized.substring(0, leading)}...${normalized.substring(normalized.length - trailing)}';
}

String? _normalizeTxid(String? value) {
  final normalized = value?.trim() ?? '';
  if (!_looksLikeHexHash(normalized)) {
    return null;
  }
  return normalized;
}

bool _looksLikeHexHash(String value) {
  final normalized = value.trim();
  if (normalized.length != 64) {
    return false;
  }
  return RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(normalized);
}

bool _looksLikeLightningTransaction(Transaction transaction) {
  final candidates = <String>[
    transaction.description ?? '',
    transaction.toAddress,
    transaction.fromAddress,
    transaction.id,
    transaction.blockchainTxid ?? '',
  ];

  return candidates.any(_looksLikeLightningPayload);
}

bool _looksLikeLightningPayload(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) {
    return false;
  }

  return normalized.startsWith('lightning:') ||
      normalized.startsWith('lnbc') ||
      normalized.startsWith('lntb') ||
      normalized.startsWith('lnbcrt') ||
      normalized.startsWith('lnurl') ||
      normalized.contains('lightning') ||
      normalized.contains('bolt11') ||
      normalized.contains('@');
}
