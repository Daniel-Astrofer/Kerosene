import 'dart:math' as math;

class MempoolTransactionSummary {
  final String txid;
  final int fee;
  final int size;
  final int weight;
  final bool confirmed;
  final int? blockHeight;
  final String? blockHash;
  final int? blockTime;
  final int? positionInBlock;
  final int? blockTxCount;

  const MempoolTransactionSummary({
    required this.txid,
    required this.fee,
    required this.size,
    required this.weight,
    required this.confirmed,
    required this.blockHeight,
    required this.blockHash,
    required this.blockTime,
    required this.positionInBlock,
    required this.blockTxCount,
  });

  int get virtualSize {
    final calculatedFromWeight = (weight / 4).ceil();
    return math.max(1, math.max(size, calculatedFromWeight));
  }

  double get effectiveFeeRate => fee / virtualSize;

  factory MempoolTransactionSummary.fromJson(
    Map<String, dynamic> json, {
    List<String> blockTxids = const <String>[],
  }) {
    final status =
        (json['status'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final txid = (json['txid'] ?? '').toString();
    final position = blockTxids.indexOf(txid);

    return MempoolTransactionSummary(
      txid: txid,
      fee: _intOf(json['fee']),
      size: _intOf(json['size']),
      weight: _intOf(json['weight']),
      confirmed: status['confirmed'] == true,
      blockHeight: _nullableIntOf(status['block_height']),
      blockHash: _nullableStringOf(status['block_hash']),
      blockTime: _nullableIntOf(status['block_time']),
      positionInBlock: position >= 0 ? position + 1 : null,
      blockTxCount: blockTxids.isNotEmpty ? blockTxids.length : null,
    );
  }
}

int _intOf(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _nullableIntOf(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString());
}

String? _nullableStringOf(dynamic value) {
  final normalized = value?.toString().trim() ?? '';
  return normalized.isEmpty ? null : normalized;
}
