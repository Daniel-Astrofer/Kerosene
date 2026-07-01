class AdminCopy {
  const AdminCopy._();

  static const String refresh = 'Atualizar';
  static const String revoke = 'Revogar acesso';
  static const String filter = 'Filtrar';
  static const String emptyState = 'Nenhum registro disponível no momento.';
  static const String unavailable = 'Informação indisponível no momento.';
  static const String loadIssue =
      'Não foi possível carregar este painel agora.';
  static const String actionIssue =
      'Não foi possível concluir esta ação agora.';
  static const String rootUnavailable =
      'Raiz de integridade indisponível no momento.';
  static const String auditEmpty = 'Nenhum evento de auditoria disponível.';

  static const String noNotifications =
      'Nenhuma notificação disponível no momento.';
  static const String noOnchainActions =
      'Nenhuma transação on-chain requer ação agora.';
  static const String noAuditCheckpoints =
      'Nenhum checkpoint de auditoria disponível.';
  static const String merkleRootUnavailable =
      'Não foi possível carregar a raiz Merkle agora.';
  static const String integrityDataUnavailable =
      'Não foi possível carregar os dados de integridade agora.';
  static const String integrityStateUnavailable =
      'Não foi possível carregar o estado de integridade agora.';
  static const String lightningMonitorUnavailable =
      'Não foi possível carregar o monitor Lightning agora.';
  static const String blockchainMonitorUnavailable =
      'Não foi possível carregar o monitor on-chain agora.';
  static const String auditRootsUnavailable =
      'Não foi possível carregar as raízes de auditoria agora.';
  static const String priceDataUnavailable =
      'Não foi possível carregar os dados de preço agora.';

  static const String brandInitial = 'K';
  static const String notificationsInboxTitle = 'Inbox de notificações';
  static const String ledgerIntegrityUnavailable =
      'Dados de integridade do ledger indisponíveis no momento.';

  static const String channelDistributionTitle = 'Distribuição por canal';
  static const String latestMerkleRootTitle = 'Última raiz Merkle';
  static const String sovereigntyStatusTitle = 'Estado de soberania';
  static const String auditHistoryTitle = 'Histórico de auditoria';

  static const String revocationRequiresStepUp =
      'A revogação exige uma confirmação adicional de acesso.';
  static const String ledgerNoPayloadPolicy =
      'Ledger sem payload: o servidor comprova consistência sem atuar como extrato permanente do usuário.';
  static const String hashAuditSummary =
      'Auditoria hash sequencial, sem histórico financeiro legível.';
  static const String readableRowsRetentionPolicy =
      'Linhas legíveis de transação funcionam como buffer efêmero de sincronização mobile por até 24h. Este terminal exibe provas e estado agregado, não extratos de usuário.';
  static String auditRootTimelineEntry(
          Object? createdAt, Object? ledgerCount) =>
      'criado ${createdAt ?? 'desconhecido'} | ledgers ${ledgerCount ?? 0}';

  static const String syncInProgress = 'Sincronização em andamento';
  static const String syncNow = 'Sincronizar agora';
  static const String blockchainSyncStarted =
      'Sincronização on-chain solicitada.';
  static const String blockchainSyncIssue =
      'Não foi possível solicitar a sincronização on-chain agora.';

  static String emptyDevices(String platform) =>
      'Nenhum dispositivo $platform disponível no momento.';

  static String loadFailure(String area) =>
      'Não foi possível carregar $area agora.';
}
