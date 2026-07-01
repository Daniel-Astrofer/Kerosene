class StatementReport {
  final List<StatementWalletInsight> wallets;
  final List<StatementMovementBucket> buckets;
  final List<StatementDistributionSegment> distribution;
  final int incomingSats;
  final int outgoingSats;
  final int feeSats;
  final int internalTransferSats;
  final int axisMaxSats;
  final int totalBalanceSats;
  final String dominantWalletName;
  final bool isPartial;

  const StatementReport({
    required this.wallets,
    required this.buckets,
    required this.distribution,
    required this.incomingSats,
    required this.outgoingSats,
    required this.feeSats,
    required this.internalTransferSats,
    required this.axisMaxSats,
    required this.totalBalanceSats,
    required this.dominantWalletName,
    required this.isPartial,
  });
}

enum StatementReportPeriod { monthly, weekly, annual }

class StatementWalletInsight {
  final String id;
  final String name;
  final Set<String> matchKeys;
  final int balanceSats;

  const StatementWalletInsight({
    required this.id,
    required this.name,
    required this.matchKeys,
    required this.balanceSats,
  });
}

class StatementMovementBucket {
  final String label;
  final DateTime start;
  final DateTime end;
  final List<StatementWalletBucketValue> values;

  const StatementMovementBucket({
    required this.label,
    required this.start,
    required this.end,
    required this.values,
  });
}

class StatementWalletBucketValue {
  final String walletId;
  final int sats;

  const StatementWalletBucketValue({
    required this.walletId,
    required this.sats,
  });
}

class StatementDistributionSegment {
  final String walletId;
  final String label;
  final int sats;
  final int visualSats;
  final double percent;

  const StatementDistributionSegment({
    required this.walletId,
    required this.label,
    required this.sats,
    required this.visualSats,
    required this.percent,
  });
}
