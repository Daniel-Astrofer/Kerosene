import 'package:intl/intl.dart';

class MiningFormatters {
  static final NumberFormat _compactNumber = NumberFormat.compact();
  static final NumberFormat _compactCurrency =
      NumberFormat.compactCurrency(symbol: '', decimalDigits: 2);
  static final NumberFormat _btcFormat = NumberFormat('0.00000000');
  static final NumberFormat _feeFormat = NumberFormat('0.##');
  static final NumberFormat _percentFormat = NumberFormat('0.0');

  static String btc(double value) => '${_btcFormat.format(value)} BTC';

  static String btcFromSats(int sats) => btc(sats / 100000000.0);

  static String compactInt(num value) => _compactNumber.format(value);

  static String compactUnsigned(num value) =>
      _compactCurrency.format(value).trim();

  static String largeNumber(num value) {
    final absolute = value.abs();
    if (absolute >= 1000000000000) {
      return '${(value / 1000000000000).toStringAsFixed(2)} T';
    }
    if (absolute >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(2)} B';
    }
    if (absolute >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)} M';
    }
    if (absolute >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)} K';
    }
    return NumberFormat('0.##').format(value);
  }

  static String feeRate(double value) => '${_feeFormat.format(value)} sat/vB';

  static String percent(double value) => '${_percentFormat.format(value)}%';

  static String signedPercent(double value) =>
      '${value >= 0 ? '+' : ''}${_percentFormat.format(value)}%';

  static String hashrate(double hashesPerSecond) {
    const units = ['H/s', 'KH/s', 'MH/s', 'GH/s', 'TH/s', 'PH/s', 'EH/s'];
    var value = hashesPerSecond;
    var unitIndex = 0;

    while (value >= 1000 && unitIndex < units.length - 1) {
      value /= 1000;
      unitIndex++;
    }

    final format = value >= 100 ? NumberFormat('0') : NumberFormat('0.0');
    return '${format.format(value)} ${units[unitIndex]}';
  }

  static String hashrateFromTh(double teraHashesPerSecond) {
    return hashrate(teraHashesPerSecond * 1000000000000);
  }

  static String duration(Duration duration) {
    if (duration.inHours >= 24) {
      final days = duration.inDays;
      final hours = duration.inHours - (days * 24);
      return '${days}d ${hours}h';
    }
    if (duration.inHours > 0) {
      final minutes = duration.inMinutes - (duration.inHours * 60);
      return '${duration.inHours}h ${minutes}m';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes} min';
    }
    return '${duration.inSeconds.clamp(0, 59)} s';
  }

  static String dateTimeFromEpochSeconds(int epochSeconds) {
    return DateFormat(
      'dd/MM HH:mm',
    ).format(DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000));
  }

  static String dateTimeFromEpochMillis(int epochMillis) {
    return DateFormat(
      'dd/MM HH:mm',
    ).format(DateTime.fromMillisecondsSinceEpoch(epochMillis));
  }

  static String shortDateTime(DateTime value) {
    return DateFormat('dd/MM HH:mm').format(value);
  }

  static String timeOfDay(DateTime value) {
    return DateFormat('HH:mm:ss').format(value);
  }

  static String megabytes(double value) {
    return '${NumberFormat('0.00').format(value)} MB';
  }

  static String blockFill(double ratio) {
    return '${(ratio * 100).toStringAsFixed(0)}% cheio';
  }
}
