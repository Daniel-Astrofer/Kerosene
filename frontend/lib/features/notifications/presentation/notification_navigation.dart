import 'package:flutter/material.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/features/notifications/domain/entities/session_notification_item.dart';

class NotificationNavigation {
  static Future<void> openFromContext(
    BuildContext context,
    SessionNotificationItem notification,
  ) {
    return openWithNavigator(notification, Navigator.of(context));
  }

  static Future<void> openWithNavigator(
    SessionNotificationItem notification,
    NavigatorState navigator,
  ) async {
    final route = notification.deeplink?.trim();
    if (route == null || route.isEmpty) {
      return;
    }

    final context = navigator.context;
    if (_shouldShowProfessionalDialog(notification)) {
      final shouldOpenRoute = await showDialog<bool>(
            context: context,
            barrierColor: Colors.black.withValues(alpha: 0.68),
            builder: (_) => _ProfessionalNotificationDialog(
              notification: notification,
              routeLabel: _routeLabelFor(notification),
            ),
          ) ??
          false;

      if (!shouldOpenRoute || !navigator.mounted) {
        return;
      }
    }

    try {
      await navigator.pushNamed(route);
    } catch (error) {
      debugPrint('Could not open notification deeplink "$route": $error');
    }
  }

  static bool _shouldShowProfessionalDialog(
    SessionNotificationItem notification,
  ) {
    return _isTransaction(notification) ||
        _isLoginOrSecurity(notification) ||
        _isPaymentLink(notification) ||
        _isRealBitcoinMarketAlert(notification) ||
        _isColdWalletNotification(notification);
  }

  static bool _isTransaction(SessionNotificationItem notification) {
    return const {
      SessionNotificationItem.kindTransferReceived,
      SessionNotificationItem.kindTransferSent,
      SessionNotificationItem.kindDepositDetected,
      SessionNotificationItem.kindDepositConfirmed,
      SessionNotificationItem.kindPaymentSent,
    }.contains(notification.kind);
  }

  static bool _isLoginOrSecurity(SessionNotificationItem notification) {
    return notification.kind.startsWith('security_') ||
        notification.entityType == 'security' ||
        notification.entityType == 'login';
  }

  static bool _isPaymentLink(SessionNotificationItem notification) {
    return const {
          SessionNotificationItem.kindPaymentRequestCreated,
          SessionNotificationItem.kindPaymentRequestPaid,
        }.contains(notification.kind) ||
        notification.entityType == 'payment_link' ||
        notification.entityType == 'paymentRequest';
  }

  static bool _isRealBitcoinMarketAlert(SessionNotificationItem notification) {
    if (notification.kind != SessionNotificationItem.kindMarketAlert) {
      return false;
    }
    return _firstMetadataValue(notification, const [
          'priceUsd',
          'btcPriceUsd',
          'lastPriceUsd',
        ]) !=
        null;
  }

  static bool _isColdWalletNotification(SessionNotificationItem notification) {
    final haystack = [
      notification.kind,
      notification.entityType ?? '',
      notification.title,
      notification.body,
      ...notification.metadata.entries
          .map((entry) => '${entry.key}:${entry.value}'),
    ].join(' ').toLowerCase();

    return haystack.contains('cold_wallet') ||
        haystack.contains('cold wallet') ||
        haystack.contains('watch-only') ||
        haystack.contains('watch only') ||
        haystack.contains('xpub') ||
        haystack.contains('descriptor');
  }

  static String _routeLabelFor(SessionNotificationItem notification) {
    if (_isLoginOrSecurity(notification)) return 'Ver segurança';
    if (_isPaymentLink(notification)) return 'Ver link';
    if (_isRealBitcoinMarketAlert(notification)) return 'Ver mercado';
    if (_isColdWalletNotification(notification)) return 'Ver carteira';
    return 'Ver detalhes';
  }

  static String? _firstMetadataValue(
    SessionNotificationItem notification,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = notification.metadata[key]?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}

class _ProfessionalNotificationDialog extends StatelessWidget {
  final SessionNotificationItem notification;
  final String routeLabel;

  const _ProfessionalNotificationDialog({
    required this.notification,
    required this.routeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spec = _DialogSpec.from(notification);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          decoration: BoxDecoration(
            color: KeroseneBrandTokens.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.42),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        spec.accent.withValues(alpha: 0.22),
                        Colors.white.withValues(alpha: 0.035),
                      ],
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: spec.accent.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: spec.accent.withValues(alpha: 0.32),
                          ),
                        ),
                        child: Icon(spec.icon, color: spec.accent, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              spec.eyebrow,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.62),
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              notification.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.08,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        notification.body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.76),
                          height: 1.42,
                        ),
                      ),
                      if (spec.rows.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        ...spec.rows.map(
                          (row) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child:
                                _DetailRow(label: row.label, value: row.value),
                          ),
                        ),
                      ],
                      if (spec.note != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.055),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Text(
                            spec.note!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.68),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withValues(alpha: 0.72),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Agora não'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(routeLabel),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.46),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _DialogSpec {
  final String eyebrow;
  final IconData icon;
  final Color accent;
  final List<_DialogRow> rows;
  final String? note;

  const _DialogSpec({
    required this.eyebrow,
    required this.icon,
    required this.accent,
    this.rows = const [],
    this.note,
  });

  factory _DialogSpec.from(SessionNotificationItem notification) {
    if (NotificationNavigation._isLoginOrSecurity(notification)) {
      return _DialogSpec(
        eyebrow: 'SEGURANÇA',
        icon: KeroseneIcons.shield,
        accent: KeroseneBrandTokens.info,
        rows: _securityRows(notification),
        note:
            'Confira se essa atividade foi feita por você. Se não reconhecer, revise seus acessos e proteja a conta.',
      );
    }

    if (NotificationNavigation._isPaymentLink(notification)) {
      return _DialogSpec(
        eyebrow: 'LINK DE PAGAMENTO',
        icon: KeroseneIcons.qr,
        accent: KeroseneBrandTokens.lightning,
        rows: _paymentLinkRows(notification),
      );
    }

    if (NotificationNavigation._isRealBitcoinMarketAlert(notification)) {
      return _DialogSpec(
        eyebrow: 'MERCADO BITCOIN',
        icon: KeroseneIcons.activity,
        accent: KeroseneBrandTokens.bitcoin,
        rows: _marketRows(notification),
        note:
            'Alerta gerado somente a partir do ticker recebido pelo app. Sem valores estimados ou simulados.',
      );
    }

    if (NotificationNavigation._isColdWalletNotification(notification)) {
      return _DialogSpec(
        eyebrow: 'CARTEIRA MONITORADA',
        icon: KeroseneIcons.wallet,
        accent: KeroseneBrandTokens.success,
        rows: _coldWalletRows(notification),
        note:
            'Carteiras cold/watch-only são acompanhadas apenas quando o evento contém material público ou metadata compatível.',
      );
    }

    return _DialogSpec(
      eyebrow: 'TRANSAÇÃO',
      icon: _transactionIcon(notification),
      accent: _transactionAccent(notification),
      rows: _transactionRows(notification),
    );
  }

  static List<_DialogRow> _transactionRows(
      SessionNotificationItem notification) {
    return _compactRows([
      _rowFromKeys(
          notification, 'Valor', const ['amountBtc', 'amount', 'btcAmount']),
      _rowFromKeys(notification, 'Carteira',
          const ['walletName', 'wallet', 'accountName']),
      _rowFromKeys(
          notification, 'Origem', const ['sender', 'from', 'payerName']),
      _rowFromKeys(
          notification, 'Destino', const ['receiver', 'to', 'payeeName']),
      _entityRow(notification),
    ]);
  }

  static List<_DialogRow> _paymentLinkRows(
      SessionNotificationItem notification) {
    return _compactRows([
      _rowFromKeys(
          notification, 'Valor', const ['amountBtc', 'amount', 'btcAmount']),
      _rowFromKeys(
          notification, 'Pagador', const ['payerName', 'payer', 'sender']),
      _rowFromKeys(notification, 'Carteira',
          const ['walletName', 'wallet', 'accountName']),
      _rowFromKeys(notification, 'Link',
          const ['paymentLinkId', 'paymentRequestId', 'linkId']),
      _entityRow(notification),
    ]);
  }

  static List<_DialogRow> _securityRows(SessionNotificationItem notification) {
    return _compactRows([
      _rowFromKeys(notification, 'Dispositivo',
          const ['deviceName', 'device', 'userAgent']),
      _rowFromKeys(notification, 'Local',
          const ['location', 'city', 'region', 'country']),
      _rowFromKeys(
          notification, 'IP', const ['ip', 'ipAddress', 'remoteAddress']),
      _rowFromKeys(notification, 'Horário', const ['occurredAt', 'createdAt']),
    ]);
  }

  static List<_DialogRow> _marketRows(SessionNotificationItem notification) {
    return _compactRows([
      _rowFromKeys(notification, 'Preço',
          const ['priceUsd', 'btcPriceUsd', 'lastPriceUsd']),
      _rowFromKeys(notification, '24h',
          const ['dailyChangePercent', 'change24hPercent', 'changePercent24h']),
      _rowFromKeys(notification, 'Faixa', const ['thresholdPercent']),
      _rowFromKeys(notification, 'Fonte', const ['source']),
    ]);
  }

  static List<_DialogRow> _coldWalletRows(
      SessionNotificationItem notification) {
    return _compactRows([
      _rowFromKeys(notification, 'Carteira',
          const ['walletName', 'wallet', 'accountName']),
      _rowFromKeys(notification, 'Modo',
          const ['walletMode', 'walletKind', 'custody', 'type']),
      _rowFromKeys(notification, 'Rede', const ['network', 'bitcoinNetwork']),
      _rowFromKeys(notification, 'Material',
          const ['publicMaterialType', 'descriptorType']),
      _entityRow(notification),
    ]);
  }

  static IconData _transactionIcon(SessionNotificationItem notification) {
    if (notification.kind == SessionNotificationItem.kindTransferReceived ||
        notification.kind == SessionNotificationItem.kindDepositDetected ||
        notification.kind == SessionNotificationItem.kindDepositConfirmed) {
      return KeroseneIcons.receive;
    }
    return KeroseneIcons.send;
  }

  static Color _transactionAccent(SessionNotificationItem notification) {
    if (notification.severity == SessionNotificationItem.severityWarning) {
      return KeroseneBrandTokens.warning;
    }
    if (notification.severity == SessionNotificationItem.severityError) {
      return KeroseneBrandTokens.error;
    }
    return KeroseneBrandTokens.success;
  }

  static _DialogRow? _rowFromKeys(
    SessionNotificationItem notification,
    String label,
    List<String> keys,
  ) {
    final value =
        NotificationNavigation._firstMetadataValue(notification, keys);
    if (value == null) return null;
    return _DialogRow(label, _formatValue(label, value));
  }

  static _DialogRow? _entityRow(SessionNotificationItem notification) {
    final id = notification.entityId?.trim();
    if (id == null || id.isEmpty) return null;
    final type = notification.entityType?.trim();
    final label = type == null || type.isEmpty ? 'ID' : type;
    return _DialogRow(label, id);
  }

  static List<_DialogRow> _compactRows(List<_DialogRow?> rows) {
    final seen = <String>{};
    return rows.whereType<_DialogRow>().where((row) {
      final key = '${row.label}:${row.value}';
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList(growable: false);
  }

  static String _formatValue(String label, String raw) {
    final value = raw.trim();
    final lowerLabel = label.toLowerCase();
    if (lowerLabel.contains('preço')) {
      final parsed = double.tryParse(value.replaceAll(',', '.'));
      if (parsed != null) return 'US\$ ${parsed.toStringAsFixed(2)}';
    }
    if (lowerLabel == '24h' || lowerLabel.contains('faixa')) {
      final parsed = double.tryParse(value.replaceAll(',', '.'));
      if (parsed != null) {
        final sign = parsed > 0 ? '+' : '';
        return '$sign${parsed.toStringAsFixed(2)}%';
      }
    }
    return value;
  }
}

class _DialogRow {
  final String label;
  final String value;

  const _DialogRow(this.label, this.value);
}
