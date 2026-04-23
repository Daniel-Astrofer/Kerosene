import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teste/core/presentation/widgets/app_notice.dart';
import 'package:teste/core/providers/currency_provider.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/features/mining/presentation/mining_explorer.dart';
import 'package:teste/features/mining/presentation/screens/mining_screen.dart';
import 'package:teste/features/transactions/domain/entities/payment_link.dart';
import 'package:teste/features/transactions/presentation/widgets/financial_status_badge.dart';
import 'package:teste/features/transactions/presentation/widgets/transaction_visuals.dart';
import 'package:teste/features/wallet/domain/entities/transaction.dart';

String _financialCopy(
  BuildContext context, {
  required String pt,
  required String en,
  required String es,
}) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'en':
      return en;
    case 'es':
      return es;
    default:
      return pt;
  }
}

class FinancialActivityDetailsSheet extends ConsumerWidget {
  final Transaction? transaction;
  final PaymentLink? paymentLink;

  const FinancialActivityDetailsSheet({
    super.key,
    this.transaction,
    this.paymentLink,
  }) : assert(transaction != null || paymentLink != null);

  static Future<void> show(
    BuildContext context, {
    Transaction? transaction,
    PaymentLink? paymentLink,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (_) => FinancialActivityDetailsSheet(
        transaction: transaction,
        paymentLink: paymentLink,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateTitle =
        _financialCopy(context, pt: 'Data', en: 'Date', es: 'Fecha');
    final advancedDetailsTitle = _financialCopy(
      context,
      pt: 'Ver dados completos',
      en: 'See full details',
      es: 'Ver datos completos',
    );
    final contextTitle =
        _financialCopy(context, pt: 'Contexto', en: 'Context', es: 'Contexto');
    final statusMeta = paymentLink != null
        ? FinancialStatusBadge.paymentLink(paymentLink!.status)
        : FinancialStatusBadge.transaction(transaction!.status);
    final amountBtc = paymentLink?.amountBtc ?? transaction!.amountBTC;
    final selectedCurrency = ref.watch(currencyProvider);
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);
    final primaryAmount = MoneyDisplay.formatAmountFromBtc(
      btcAmount: amountBtc,
      currency: selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final secondaryAmount = selectedCurrency == Currency.btc
        ? null
        : MoneyDisplay.format(
            amount: amountBtc,
            currency: Currency.btc,
          );
    final createdAt =
        paymentLink?.createdAt ?? paymentLink?.paidAt ?? transaction?.timestamp;
    final hasAdvancedDetails =
        (_secondaryAddress != null && _secondaryAddress!.trim().isNotEmpty) ||
            (_referenceId != null && _referenceId!.trim().isNotEmpty) ||
            (_description != null && _description!.trim().isNotEmpty);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.only(top: 48),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF131F2E),
              Color(0xFF000000),
              Color(0xFF0A1119),
            ],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _SummaryHero(
                statusMeta: statusMeta,
                headline: _headline,
                contextLabel: _contextLabel,
                supportingText: _summaryMessage,
                primaryAmount: primaryAmount,
                secondaryAmount: secondaryAmount,
                createdAt: createdAt,
              ),
              const SizedBox(height: 20),
              if (_primaryAddress != null)
                _CopyablePanel(
                  title: _primaryAddressLabel,
                  value: _primaryAddress!,
                ),
              if (createdAt != null) ...[
                const SizedBox(height: 12),
                _DetailPanel(
                  title: dateTitle,
                  child: Text(
                    DateFormat('dd/MM/yyyy • HH:mm').format(createdAt),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
              if (hasAdvancedDetails) ...[
                const SizedBox(height: 12),
                _DisclosurePanel(
                  title: advancedDetailsTitle,
                  children: [
                    if (_secondaryAddress != null) ...[
                      _CopyablePanel(
                        title: _secondaryAddressLabel,
                        value: _secondaryAddress!,
                        compact: true,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_referenceId != null) ...[
                      _CopyablePanel(
                        title: _referenceLabel,
                        value: _referenceId!,
                        compact: true,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_description != null && _description!.trim().isNotEmpty)
                      _DetailPanel(
                        title: contextTitle,
                        compact: true,
                        child: Text(
                          _description!,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.86),
                                    height: 1.45,
                                  ),
                        ),
                      ),
                  ],
                ),
              ],
              if (transaction != null) ...[
                const SizedBox(height: 12),
                _NetworkExplorerButton(transaction: transaction!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String get _headline {
    if (paymentLink != null) {
      if (paymentLink!.isOnboardingVoucher) {
        return 'Voucher de onboarding';
      }
      return 'Pagamento por link';
    }

    return TransactionVisualSpec.fromTransaction(transaction!).label;
  }

  String get _contextLabel {
    if (paymentLink != null) {
      if (paymentLink!.isOnboardingVoucher) {
        return 'Voucher de onboarding';
      }
      return 'Pagamento por link';
    }
    if (transaction!.type == TransactionType.withdrawal) {
      return 'Saque para fora';
    }
    return transaction!.isInternal ? 'Movimentação interna' : 'Rede Bitcoin';
  }

  String? get _primaryAddress {
    if (paymentLink != null) {
      return paymentLink!.depositAddress;
    }
    return transaction!.toAddress;
  }

  String get _primaryAddressLabel {
    if (paymentLink != null) {
      return 'Endereço de depósito';
    }
    if (transaction!.type == TransactionType.withdrawal ||
        transaction!.type == TransactionType.send) {
      return 'Destino';
    }
    return 'Recebedor';
  }

  String? get _secondaryAddress {
    if (paymentLink != null) {
      return null;
    }
    return transaction!.fromAddress;
  }

  String get _secondaryAddressLabel {
    if (transaction!.type == TransactionType.withdrawal ||
        transaction!.type == TransactionType.send) {
      return 'Origem';
    }
    return 'Remetente';
  }

  String? get _referenceId {
    if (paymentLink != null) {
      return paymentLink!.txid ?? paymentLink!.id;
    }
    return transaction!.blockchainTxid ?? transaction!.id;
  }

  String get _referenceLabel {
    if (paymentLink?.txid != null || transaction?.blockchainTxid != null) {
      return 'TXID';
    }
    return 'Referência';
  }

  String? get _description {
    if (paymentLink != null) {
      return paymentLink!.description;
    }
    return transaction!.description;
  }

  String get _summaryMessage {
    if (paymentLink != null) {
      if (paymentLink!.isVerifyingOnboarding) {
        return 'Estamos conferindo este pagamento para liberar a próxima etapa automaticamente.';
      }
      if (paymentLink!.isPaid || paymentLink!.isCompleted) {
        return 'Pagamento recebido. Se houver uma próxima etapa, ela já pode ser liberada.';
      }
      if (paymentLink!.isExpired) {
        return 'Este link expirou e não aceita novos pagamentos.';
      }
      return 'Compartilhe o endereço abaixo quando quiser receber sem sair desta tela.';
    }

    switch (transaction!.status) {
      case TransactionStatus.pending:
      case TransactionStatus.confirming:
        return 'Esta movimentação ainda está em andamento. O status muda automaticamente assim que houver atualização.';
      case TransactionStatus.confirmed:
        return 'Movimentação concluída com sucesso e pronta para conferência.';
      case TransactionStatus.failed:
        return 'Não foi possível concluir esta movimentação. Revise os detalhes antes de tentar novamente.';
    }
  }
}

class _ContextChip extends StatelessWidget {
  final String label;

  const _ContextChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1219),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.74),
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _NetworkExplorerButton extends StatelessWidget {
  final Transaction transaction;

  const _NetworkExplorerButton({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final explorer = MiningExplorerDescriptor.fromTransaction(transaction);
    final accent = explorer.rail == MiningExplorerRail.lightning
        ? const Color(0xFFFBBF24)
        : const Color(0xFF67B5FF);

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          final navigator = Navigator.of(context);
          final route = MaterialPageRoute<void>(
            builder: (_) => MiningScreen(initialTransaction: transaction),
          );

          navigator.pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (navigator.mounted) {
              navigator.push(route);
            }
          });
        },
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF0D151F),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: accent.withValues(alpha: 0.26)),
          ),
        ),
        icon: Icon(
          explorer.rail == MiningExplorerRail.lightning
              ? Icons.bolt_rounded
              : Icons.open_in_new_rounded,
          color: accent,
        ),
        label: Text(
          'Abrir ${explorer.buttonLabel}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  final String title;
  final Widget child;
  final bool compact;

  const _DetailPanel({
    required this.title,
    required this.child,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF111A24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.54),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _CopyablePanel extends StatelessWidget {
  final String title;
  final String value;
  final bool compact;

  const _CopyablePanel({
    required this.title,
    required this.value,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final copiedMessage = _financialCopy(
      context,
      pt: 'Informação copiada para a área de transferência.',
      en: 'Information copied to the clipboard.',
      es: 'Informacion copiada al portapapeles.',
    );
    return _DetailPanel(
      title: title,
      compact: compact,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SelectableText(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              await HapticFeedback.selectionClick();
              if (!context.mounted) {
                return;
              }
              AppNotice.showSuccess(context, message: copiedMessage);
            },
            icon: const Icon(Icons.copy_rounded),
            color: Colors.white,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.06),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryHero extends StatelessWidget {
  final FinancialStatusMeta statusMeta;
  final String headline;
  final String contextLabel;
  final String supportingText;
  final String primaryAmount;
  final String? secondaryAmount;
  final DateTime? createdAt;

  const _SummaryHero({
    required this.statusMeta,
    required this.headline,
    required this.contextLabel,
    required this.supportingText,
    required this.primaryAmount,
    required this.secondaryAmount,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF111B28),
            const Color(0xFF0B1219),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusMeta.color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FinancialStatusBadge(meta: statusMeta),
              _ContextChip(label: contextLabel),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            headline,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            supportingText,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.74),
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 18),
          Text(
            primaryAmount,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
          ),
          if (secondaryAmount != null) ...[
            const SizedBox(height: 8),
            Text(
              secondaryAmount!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
          if (createdAt != null) ...[
            const SizedBox(height: 10),
            Text(
              DateFormat('dd/MM/yyyy • HH:mm').format(createdAt!),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DisclosurePanel extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DisclosurePanel({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111A24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: Colors.white,
          collapsedIconColor: Colors.white,
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          subtitle: Text(
            'Mostramos só o essencial primeiro.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.54),
                ),
          ),
          children: children,
        ),
      ),
    );
  }
}
