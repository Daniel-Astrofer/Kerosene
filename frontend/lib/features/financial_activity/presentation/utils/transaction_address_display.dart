import 'package:kerosene/features/financial_activity/domain/entities/transaction.dart';

const Set<String> _genericTransactionAddressLabels = {
  'rede bitcoin',
  'bitcoin network',
  'minha carteira',
  'my wallet',
  'wallet',
  'carteira',
  'carteira kerosene',
  'carteira global',
};

bool isMeaningfulTransactionAddress(String? value) {
  final normalized = value?.trim() ?? '';
  if (normalized.isEmpty) {
    return false;
  }

  return !_genericTransactionAddressLabels.contains(normalized.toLowerCase());
}

bool _isOutgoingTransaction(Transaction transaction) => transaction.isDebit;

String _firstMeaningful(Iterable<String?> values) {
  for (final value in values) {
    final normalized = value?.trim() ?? '';
    if (isMeaningfulTransactionAddress(normalized)) {
      return normalized;
    }
  }
  return '';
}

String resolveTransactionSender(Transaction transaction) {
  return _firstMeaningful([
    transaction.senderDisplayName,
    transaction.fromAddress,
    transaction.externalReference,
    transaction.blockchainTxid,
    transaction.id,
  ]);
}

String resolveTransactionRecipient(Transaction transaction) {
  return _firstMeaningful([
    transaction.receiverDisplayName,
    transaction.toAddress,
    transaction.externalReference,
    transaction.blockchainTxid,
    transaction.id,
  ]);
}

String resolvePrimaryTransactionAddress(Transaction transaction) {
  return _isOutgoingTransaction(transaction)
      ? resolveTransactionRecipient(transaction)
      : resolveTransactionSender(transaction);
}

String? resolveSecondaryTransactionAddress(Transaction transaction) {
  final primary = resolvePrimaryTransactionAddress(transaction);
  final fromAddress = transaction.fromAddress.trim();
  final toAddress = transaction.toAddress.trim();

  if (_isOutgoingTransaction(transaction)) {
    if (isMeaningfulTransactionAddress(fromAddress) && fromAddress != primary) {
      return fromAddress;
    }
    return null;
  }

  if (isMeaningfulTransactionAddress(fromAddress) && fromAddress != primary) {
    return fromAddress;
  }
  if (isMeaningfulTransactionAddress(toAddress) && toAddress != primary) {
    return toAddress;
  }
  return null;
}

String resolvePrimaryTransactionAddressLabel(Transaction transaction) {
  return _isOutgoingTransaction(transaction) ? 'Destino' : 'Origem';
}

String resolveSecondaryTransactionAddressLabel(Transaction transaction) {
  final secondary = resolveSecondaryTransactionAddress(transaction);
  if (secondary == null) {
    return 'Endereço';
  }

  if (_isOutgoingTransaction(transaction)) {
    return 'Origem';
  }

  if (secondary == transaction.fromAddress.trim()) {
    return 'Origem';
  }

  return 'Endereço';
}

int transactionAddressInformationScore(Transaction transaction) {
  var score = 0;

  if (isMeaningfulTransactionAddress(transaction.toAddress)) {
    score += 3;
  }
  if (isMeaningfulTransactionAddress(transaction.fromAddress)) {
    score += 2;
  }

  return score;
}
