import 'package:kerosene/features/financial_accounts/domain/entities/bitcoin_account_models.dart';

export 'package:kerosene/features/financial_accounts/domain/entities/bitcoin_account_models.dart';

enum BitcoinAccountCustody {
  internal,
  custodialOnchain,
  watchOnly,
}

extension BitcoinAccountCustodyPayload on BitcoinAccountCustody {
  String get kfeKind {
    return switch (this) {
      BitcoinAccountCustody.internal => 'INTERNAL',
      BitcoinAccountCustody.custodialOnchain => 'CUSTODIAL_ONCHAIN',
      BitcoinAccountCustody.watchOnly => 'WATCH_ONLY',
    };
  }
}

abstract class BitcoinAccountsService {
  Future<List<BitcoinAccount>> listAccounts();

  Future<BitcoinAccount> createWallet({
    required String label,
    required BitcoinAccountCustody custody,
  });

  Future<BitcoinAccount> createInternalCard({
    required String label,
  });

  Future<BitcoinAccount> importColdWallet({
    required String label,
    required String xpub,
    required String fingerprint,
    required String derivationPath,
    required String scriptPolicy,
  });

  Future<ReceivingRequestView> createReceiveRequest({
    required String accountId,
    int? amountSats,
    required String expiry,
    required bool oneTime,
  });

  Future<ReceivingRequestView> rotateReceiveAddress(String accountId);

  Future<BitcoinAccount> renameWallet({
    required String accountId,
    required String label,
  });

  Future<BitcoinAccount> archiveWallet(String accountId);

  Future<List<ReceivingRequestView>> listReceiveRequestsForAccount(
    String accountId,
  );

  Future<ReceivingRequestView> getReceiveStatus(String requestId);

  Future<List<ColdWalletUtxoView>> listColdWalletUtxos(String coldWalletId);

  Future<List<PsbtWorkflowView>> listColdWalletPsbt(String coldWalletId);

  Future<PsbtWorkflowView> createColdWalletPsbt({
    required String coldWalletId,
    required String destinationAddress,
    required int amountSats,
    int? feeRate,
    List<String> selectedUtxoIds = const [],
  });

  Future<PsbtWorkflowView> getPsbtWorkflow(String workflowId);

  Future<PsbtWorkflowView> submitSignedPsbt({
    required String workflowId,
    required String signedPsbt,
    required bool broadcast,
  });

  Future<List<TaxEventView>> listTaxEvents();

  Future<TaxEventsExportView> exportTaxEvents({required String format});

  Future<TaxEventView> classifyTaxEvent({
    required String eventId,
    required String classification,
  });
}
