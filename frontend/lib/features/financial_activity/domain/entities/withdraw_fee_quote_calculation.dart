enum WithdrawFeeMode { senderPays, recipientPays }

class WithdrawFeeQuoteCalculation {
  static const int _satsPerBtc = 100000000;

  final WithdrawFeeMode mode;
  final double requestedAmountBtc;
  final double receiverAmountBtc;
  final double platformFeeRate;
  final double platformFeeBtc;
  final double networkFeeBtc;
  final double totalDebitedBtc;

  const WithdrawFeeQuoteCalculation({
    required this.mode,
    required this.requestedAmountBtc,
    required this.receiverAmountBtc,
    required this.platformFeeRate,
    required this.platformFeeBtc,
    required this.networkFeeBtc,
    required this.totalDebitedBtc,
  });

  double get totalFeesBtc => platformFeeBtc + networkFeeBtc;
  bool get deductsFees => mode == WithdrawFeeMode.recipientPays;

  static bool hasSufficientBalance({
    required double availableBtc,
    required double totalDebitedBtc,
  }) {
    if (totalDebitedBtc <= 0) {
      return true;
    }
    if (!availableBtc.isFinite || !totalDebitedBtc.isFinite) {
      return false;
    }

    return _toSats(availableBtc) >= _toSats(totalDebitedBtc);
  }

  static WithdrawFeeQuoteCalculation resolve({
    required WithdrawFeeMode mode,
    required double requestedAmountBtc,
    required double platformFeeRate,
    required double networkFeeBtc,
  }) {
    if (requestedAmountBtc <= 0) {
      return WithdrawFeeQuoteCalculation(
        mode: mode,
        requestedAmountBtc: requestedAmountBtc,
        receiverAmountBtc: 0,
        platformFeeRate: platformFeeRate,
        platformFeeBtc: 0,
        networkFeeBtc: 0,
        totalDebitedBtc: 0,
      );
    }

    final safeNetworkFeeBtc = networkFeeBtc < 0 ? 0.0 : networkFeeBtc;
    final safePlatformFeeRate = platformFeeRate < 0 ? 0.0 : platformFeeRate;
    final receiverAmountBtc = mode == WithdrawFeeMode.senderPays
        ? requestedAmountBtc
        : _receiverAmountAfterFees(
            requestedAmountBtc: requestedAmountBtc,
            platformFeeRate: safePlatformFeeRate,
            networkFeeBtc: safeNetworkFeeBtc,
          );
    final platformFeeBtc = receiverAmountBtc * safePlatformFeeRate;
    final totalDebitedBtc = receiverAmountBtc <= 0
        ? 0.0
        : receiverAmountBtc + platformFeeBtc + safeNetworkFeeBtc;

    return WithdrawFeeQuoteCalculation(
      mode: mode,
      requestedAmountBtc: requestedAmountBtc,
      receiverAmountBtc: receiverAmountBtc,
      platformFeeRate: safePlatformFeeRate,
      platformFeeBtc: platformFeeBtc,
      networkFeeBtc: safeNetworkFeeBtc,
      totalDebitedBtc: totalDebitedBtc,
    );
  }

  static double _receiverAmountAfterFees({
    required double requestedAmountBtc,
    required double platformFeeRate,
    required double networkFeeBtc,
  }) {
    final netBeforePlatformFee = requestedAmountBtc - networkFeeBtc;
    if (netBeforePlatformFee <= 0) {
      return 0;
    }
    return netBeforePlatformFee / (1 + platformFeeRate);
  }

  static int _toSats(double btc) => (btc * _satsPerBtc).round();
}
