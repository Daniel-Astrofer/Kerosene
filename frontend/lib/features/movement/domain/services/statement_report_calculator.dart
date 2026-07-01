import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/movement/domain/entities/statement_report.dart';
import 'package:kerosene/features/movement/domain/entities/transaction.dart';

class StatementReportCalculator {
  static const int _satsPerBtc = 100000000;
  static const int partialHistoryThreshold = 50;

  const StatementReportCalculator._();

  static StatementReport calculate({
    required List<Transaction> transactions,
    required List<Wallet> wallets,
    required StatementReportPeriod period,
    DateTime? now,
    String locale = 'pt',
    String emptyWalletName = 'Sem carteiras',
  }) {
    final effectiveNow = now ?? DateTime.now();
    final walletInsights = _walletInsights(
      wallets,
      emptyWalletName: emptyWalletName,
    );
    final ranges = _bucketRanges(
      wallets: wallets,
      period: period,
      now: effectiveNow,
      locale: locale,
    );
    final reportStart = ranges.first.start;
    final reportEnd = ranges.last.end;
    final countAllTransactionsAsSingleWallet =
        walletInsights.length == 1 && walletInsights.first.matchKeys.isEmpty;

    final usableTransactions = transactions
        .where((tx) => tx.status != TransactionStatus.failed)
        .toList(growable: false);

    final buckets = ranges.map((range) {
      return StatementMovementBucket(
        label: range.label,
        start: range.start,
        end: range.end,
        values: [
          for (final wallet in walletInsights)
            StatementWalletBucketValue(
              walletId: wallet.id,
              sats: _walletVolumeForRange(
                wallet,
                usableTransactions,
                start: range.start,
                end: range.end,
                fallbackToWallet: countAllTransactionsAsSingleWallet,
              ),
            ),
        ],
      );
    }).toList(growable: false);

    var incoming = 0;
    var outgoing = 0;
    var fees = 0;
    var internalTransfers = 0;

    for (final tx in usableTransactions) {
      final local = tx.timestamp.toLocal();
      if (local.isBefore(reportStart) || !local.isBefore(reportEnd)) {
        continue;
      }

      final classification = _classifyTransaction(
        tx,
        walletInsights,
        fallbackToWallet: countAllTransactionsAsSingleWallet,
      );
      if (!classification.belongsToKnownWallet) {
        continue;
      }

      final amount = tx.amountSatoshis.abs();
      final fee = tx.feeSatoshis.abs();
      if (classification.isInternalBetweenKnownWallets) {
        internalTransfers += amount;
        fees += fee;
        continue;
      }

      if (tx.isCredit || classification.destinationMatchesKnownWallet) {
        incoming += amount;
        continue;
      }

      if (tx.isDebit || classification.sourceMatchesKnownWallet) {
        outgoing += amount;
        fees += fee;
      }
    }

    final totalBalance = walletInsights.fold<int>(
      0,
      (sum, wallet) => sum + math.max(0, wallet.balanceSats),
    );
    final dominant = walletInsights.reduce((a, b) {
      if (b.balanceSats != a.balanceSats) {
        return b.balanceSats > a.balanceSats ? b : a;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase()) <= 0 ? a : b;
    });
    final distribution = [
      for (final wallet in walletInsights)
        StatementDistributionSegment(
          walletId: wallet.id,
          label: wallet.name,
          sats: wallet.balanceSats,
          visualSats: math.max(1, totalBalance > 0 ? wallet.balanceSats : 1),
          percent: totalBalance <= 0 ? 0 : wallet.balanceSats / totalBalance * 100,
        ),
    ];
    final rawAxisMax = buckets.fold<int>(
      0,
      (maxValue, bucket) => math.max(
        maxValue,
        bucket.values.fold<int>(
          0,
          (bucketMax, value) => math.max(bucketMax, value.sats),
        ),
      ),
    );

    return StatementReport(
      wallets: walletInsights,
      buckets: buckets,
      distribution: distribution,
      incomingSats: incoming,
      outgoingSats: outgoing,
      feeSats: fees,
      internalTransferSats: internalTransfers,
      axisMaxSats: _niceAxisMax(rawAxisMax),
      totalBalanceSats: totalBalance,
      dominantWalletName: dominant.name,
      isPartial: transactions.length >= partialHistoryThreshold,
    );
  }

  static List<StatementWalletInsight> _walletInsights(
    List<Wallet> source, {
    required String emptyWalletName,
  }) {
    final wallets = source.where((wallet) => wallet.isActive).toList();
    final displayWallets = wallets.isNotEmpty ? wallets : List<Wallet>.from(source);
    displayWallets.sort((a, b) {
      final balance = b.balance.compareTo(a.balance);
      if (balance != 0) return balance;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    if (displayWallets.isEmpty) {
      return [
        StatementWalletInsight(
          id: 'empty',
          name: emptyWalletName,
          matchKeys: const {},
          balanceSats: 0,
        ),
      ];
    }

    return [
      for (final wallet in displayWallets)
        StatementWalletInsight(
          id: wallet.id,
          name: wallet.name,
          matchKeys: _walletMatchKeys(wallet),
          balanceSats: _btcToSats(wallet.balance),
        ),
    ];
  }

  static Set<String> _walletMatchKeys(Wallet wallet) {
    return {
      wallet.id,
      wallet.name,
      wallet.address,
      wallet.cardHolderName,
      wallet.cardNumberSuffix,
    }
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  static List<({DateTime start, DateTime end, String label})> _bucketRanges({
    required List<Wallet> wallets,
    required StatementReportPeriod period,
    required DateTime now,
    required String locale,
  }) {
    final localNow = now.toLocal();
    final createdAt = wallets.isEmpty
        ? DateTime(localNow.year, localNow.month)
        : wallets
            .map((wallet) => wallet.createdAt.toLocal())
            .reduce((a, b) => a.isBefore(b) ? a : b);

    switch (period) {
      case StatementReportPeriod.weekly:
        final currentWeek = _weekStart(localNow);
        final firstWeek = _weekStart(createdAt);
        final ytdWeek = _weekStart(DateTime(localNow.year));
        final start = firstWeek.isAfter(ytdWeek) ? firstWeek : ytdWeek;
        final ranges = <({DateTime start, DateTime end, String label})>[];
        for (var week = start;
            !week.isAfter(currentWeek);
            week = week.add(const Duration(days: 7))) {
          ranges.add((
            start: week,
            end: week.add(const Duration(days: 7)),
            label: DateFormat.MMMd(locale).format(week),
          ));
        }
        return ranges.isEmpty
            ? [
                (
                  start: currentWeek,
                  end: currentWeek.add(const Duration(days: 7)),
                  label: DateFormat.MMMd(locale).format(currentWeek),
                )
              ]
            : ranges;
      case StatementReportPeriod.annual:
        final currentMonth = DateTime(localNow.year, localNow.month);
        final firstMonth = DateTime(createdAt.year, createdAt.month);
        final start = _maxDate(
          firstMonth,
          DateTime(currentMonth.year, currentMonth.month - 11),
        );
        return _monthRanges(start, currentMonth, locale);
      case StatementReportPeriod.monthly:
        final currentMonth = DateTime(localNow.year, localNow.month);
        final firstMonth = DateTime(createdAt.year, createdAt.month);
        final start = _maxDate(
          firstMonth,
          DateTime(currentMonth.year, currentMonth.month - 5),
        );
        return _monthRanges(start, currentMonth, locale);
    }
  }

  static List<({DateTime start, DateTime end, String label})> _monthRanges(
    DateTime start,
    DateTime currentMonth,
    String locale,
  ) {
    final ranges = <({DateTime start, DateTime end, String label})>[];
    for (var month = DateTime(start.year, start.month);
        !month.isAfter(currentMonth);
        month = DateTime(month.year, month.month + 1)) {
      ranges.add((
        start: month,
        end: DateTime(month.year, month.month + 1),
        label: DateFormat.MMM(locale).format(month),
      ));
    }
    return ranges;
  }

  static int _walletVolumeForRange(
    StatementWalletInsight wallet,
    List<Transaction> transactions, {
    required DateTime start,
    required DateTime end,
    required bool fallbackToWallet,
  }) {
    var total = 0;
    for (final tx in transactions) {
      final local = tx.timestamp.toLocal();
      if (local.isBefore(start) || !local.isBefore(end)) continue;
      final delta = _walletDelta(
        wallet,
        tx,
        fallbackToWallet: fallbackToWallet,
      );
      total += delta.abs();
    }
    return total;
  }

  static int _walletDelta(
    StatementWalletInsight wallet,
    Transaction tx, {
    required bool fallbackToWallet,
  }) {
    final amount = tx.amountSatoshis.abs();
    final debitAmount = amount + tx.feeSatoshis.abs();
    final walletMatches = _matchesWallet(wallet, [tx.walletId]);
    final sourceMatches = _matchesWallet(wallet, [
      tx.sourceWalletId,
      tx.fromAddress,
    ]);
    final destinationMatches = _matchesWallet(wallet, [
      tx.destinationWalletId,
      tx.toAddress,
    ]);
    final matched = walletMatches || sourceMatches || destinationMatches;

    if (!matched && !fallbackToWallet) return 0;
    if (tx.isInternal) {
      if (sourceMatches && !destinationMatches) return -debitAmount;
      if (destinationMatches && !sourceMatches) return amount;
    }
    if (tx.isCredit &&
        (destinationMatches || walletMatches || fallbackToWallet)) {
      return amount;
    }
    if (tx.isDebit && (sourceMatches || walletMatches || fallbackToWallet)) {
      return -debitAmount;
    }
    return 0;
  }

  static _TransactionClassification _classifyTransaction(
    Transaction tx,
    List<StatementWalletInsight> wallets, {
    required bool fallbackToWallet,
  }) {
    if (fallbackToWallet) {
      return const _TransactionClassification(
        belongsToKnownWallet: true,
        sourceMatchesKnownWallet: true,
        destinationMatchesKnownWallet: true,
        isInternalBetweenKnownWallets: false,
      );
    }

    var walletMatches = false;
    var sourceMatches = false;
    var destinationMatches = false;
    for (final wallet in wallets) {
      walletMatches = walletMatches || _matchesWallet(wallet, [tx.walletId]);
      sourceMatches = sourceMatches ||
          _matchesWallet(wallet, [tx.sourceWalletId, tx.fromAddress]);
      destinationMatches = destinationMatches ||
          _matchesWallet(wallet, [tx.destinationWalletId, tx.toAddress]);
    }
    return _TransactionClassification(
      belongsToKnownWallet: walletMatches || sourceMatches || destinationMatches,
      sourceMatchesKnownWallet: sourceMatches || (tx.isDebit && walletMatches),
      destinationMatchesKnownWallet:
          destinationMatches || (tx.isCredit && walletMatches),
      isInternalBetweenKnownWallets:
          tx.isInternal && sourceMatches && destinationMatches,
    );
  }

  static bool _matchesWallet(
    StatementWalletInsight wallet,
    List<String?> candidates,
  ) {
    for (final candidate in candidates) {
      final normalized = candidate?.trim().toLowerCase();
      if (normalized == null || normalized.isEmpty) continue;
      if (wallet.matchKeys.contains(normalized)) return true;
    }
    return false;
  }

  static DateTime _weekStart(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day - local.weekday + 1);
  }

  static DateTime _maxDate(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

  static int _btcToSats(double value) => (value * _satsPerBtc).round();

  static int _niceAxisMax(int raw) {
    if (raw <= 0) return 1000;
    final magnitude = math.pow(10, raw.toString().length - 1).toInt();
    final normalized = raw / magnitude;
    final multiplier = normalized <= 1
        ? 1
        : normalized <= 2
            ? 2
            : normalized <= 5
                ? 5
                : 10;
    return multiplier * magnitude;
  }
}

class _TransactionClassification {
  final bool belongsToKnownWallet;
  final bool sourceMatchesKnownWallet;
  final bool destinationMatchesKnownWallet;
  final bool isInternalBetweenKnownWallets;

  const _TransactionClassification({
    required this.belongsToKnownWallet,
    required this.sourceMatchesKnownWallet,
    required this.destinationMatchesKnownWallet,
    required this.isInternalBetweenKnownWallets,
  });
}
