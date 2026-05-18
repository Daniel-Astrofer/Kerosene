import 'package:teste/features/wallet/domain/entities/transaction.dart';

const Set<String> _genericTransactionAddressLabels = {
  'rede bitcoin',
  'bitcoin network',
  'minha carteira',
  'my wallet',
  'wallet',
};

bool isMeaningfulTransactionAddress(String? value) {
  final normalized = value?.trim() ?? '';
  if (normalized.isEmpty) {
    return false;
  }

  return !_genericTransactionAddressLabels.contains(normalized.toLowerCase());
}

bool _isOutgoingTransaction(Transaction transaction) {
  return transaction.type == TransactionType.send ||
      transaction.type == TransactionType.withdrawal;
}

String resolvePrimaryTransactionAddress(Transaction transaction) {
  final fromAddress = transaction.fromAddress.trim();
  final toAddress = transaction.toAddress.trim();
  final hasFromAddress = isMeaningfulTransactionAddress(fromAddress);
  final hasToAddress = isMeaningfulTransactionAddress(toAddress);

  if (_isOutgoingTransaction(transaction)) {
    if (hasToAddress) {
      return toAddress;
    }
    if (toAddress.isNotEmpty) {
      return toAddress;
    }
    if (hasFromAddress) {
      return fromAddress;
    }
    return fromAddress;
  }

  if (hasToAddress) {
    return toAddress;
  }
  if (hasFromAddress) {
    return fromAddress;
  }
  if (toAddress.isNotEmpty) {
    return toAddress;
  }
  return fromAddress;
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
  final primary = resolvePrimaryTransactionAddress(transaction);

  if (_isOutgoingTransaction(transaction)) {
    return 'Destino';
  }

  if (primary == transaction.toAddress.trim()) {
    return 'Endereço de recebimento';
  }

  return 'Origem';
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
