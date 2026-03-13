import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../features/wallet/domain/entities/transaction.dart';

extension TransactionStatusExtension on TransactionStatus {
  String localized(BuildContext context) {
    switch (this) {
      case TransactionStatus.pending:
        return AppLocalizations.of(context)!.pending;
      case TransactionStatus.confirming:
        return AppLocalizations.of(context)!.confirming;
      case TransactionStatus.confirmed:
        return AppLocalizations.of(context)!.confirmed;
      case TransactionStatus.failed:
        return AppLocalizations.of(context)!.failed;
    }
  }
}

extension TransactionTypeExtension on TransactionType {
  String localized(BuildContext context) {
    switch (this) {
      case TransactionType.send:
        return AppLocalizations.of(context)!.typeSend;
      case TransactionType.receive:
        return AppLocalizations.of(context)!.typeReceive;
      case TransactionType.swap:
        return AppLocalizations.of(context)!.typeSwap;
      case TransactionType.fee:
        return AppLocalizations.of(context)!.typeFee;
      case TransactionType.withdrawal:
        return 'Withdrawal';
      case TransactionType.deposit:
        return 'Deposit';
    }
  }
}
