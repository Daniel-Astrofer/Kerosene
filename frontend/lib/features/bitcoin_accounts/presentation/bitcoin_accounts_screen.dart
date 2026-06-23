// ignore_for_file: unused_element

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/material.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/presentation/widgets/app_notice.dart';
import 'package:kerosene/core/presentation/widgets/app_primary_navigation.dart';
import 'package:kerosene/core/presentation/widgets/bitcoin_address_blocks.dart';
import 'package:kerosene/core/providers/network_status_provider.dart';
import 'package:kerosene/core/responsive/kerosene_responsive.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';
import 'package:kerosene/core/theme/monochrome_theme.dart';
import 'package:kerosene/features/bitcoin_accounts/data/bitcoin_accounts_service.dart';
import 'package:kerosene/features/bitcoin_accounts/data/cold_wallet_public_material.dart';
import 'package:kerosene/features/bitcoin_accounts/presentation/bitcoin_accounts_provider.dart';
import 'package:kerosene/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:kerosene/features/wallet/domain/entities/transaction.dart';

import 'bitcoin_accounts_empty_layout.dart';
import 'bitcoin_accounts_header.dart';
import 'bitcoin_accounts_presentation_support.dart';

part 'screens/cold_wallet_creation_screen.dart';
part 'screens/internal_account_creation_screen.dart';
part 'widgets/receive_sheet.dart';
part 'widgets/bottom_sheets.dart';

class BitcoinAccountsScreen extends ConsumerStatefulWidget {
  const BitcoinAccountsScreen({super.key});

  @override
  ConsumerState<BitcoinAccountsScreen> createState() =>
      _BitcoinAccountsScreenState();
}

class _BitcoinAccountsScreenState extends ConsumerState<BitcoinAccountsScreen> {
  int _selectedAccountIndex = 0;
  final Map<String, ReceivingRequestView> _receiveAddressOverrides = {};

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(bitcoinAccountsProvider);
    final bottom = AppPrimaryNavigationBar.scaffoldBottomClearance(context);
    final responsive = context.responsive;
    final colors = BitcoinAccountsColors.of(context);
    final isEmptyState = accounts.asData?.value.isEmpty == true;

    return Scaffold(
      backgroundColor: isEmptyState ? AppColors.hexFF000000 : colors.background,
      body: Stack(
        children: [
          SafeArea(
            child: isEmptyState
                ? BitcoinAccountsEmptyLayout(
                    bottomClearance: bottom,
                    onBack: _handleHeaderBack,
                    onCreateInternalAccount: _openInternalAccountFlow,
                    onRefresh: () =>
                        ref.read(bitcoinAccountsProvider.notifier).refresh(),
                  )
                : RefreshIndicator(
                    color: colors.text,
                    backgroundColor: colors.surface,
                    onRefresh: () =>
                        ref.read(bitcoinAccountsProvider.notifier).refresh(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        responsive.horizontalPadding,
                        responsive.isTinyPhone ? 14 : 18,
                        responsive.horizontalPadding,
                        bottom,
                      ),
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: responsive.mobileContentMaxWidth,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                BitcoinAccountsHeader(
                                  onBack: _handleHeaderBack,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                accounts.when(
                                  loading: () => const _AccountsSkeleton(),
                                  error: (_, __) => _StatePanel(
                                    icon: KeroseneIcons.error,
                                    title: context.tr.bitcoinAccountsErrorTitle,
                                    message:
                                        context.tr.bitcoinAccountsErrorMessage,
                                    actionLabel: context.tr.tryAgain,
                                    onAction: () => ref
                                        .read(bitcoinAccountsProvider.notifier)
                                        .refresh(),
                                  ),
                                  data: (items) => _AccountsContent(
                                    accounts: items,
                                    selectedAccountIndex: _selectedAccountIndex,
                                    receiveAddressOverrides:
                                        _receiveAddressOverrides,
                                    onAccountChanged: (index) => setState(() {
                                      _selectedAccountIndex = index;
                                    }),
                                    onReceiveAddressRotated: (request) {
                                      setState(() {
                                        _receiveAddressOverrides[
                                            request.accountId] = request;
                                      });
                                    },
                                    onCreateInternalAccount:
                                        _openInternalAccountFlow,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          AppPrimaryNavigationBar.overlay(
            currentDestination: AppPrimaryDestination.card,
          ),
        ],
      ),
    );
  }

  void _openInternalAccountFlow() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _InternalAccountCreationFlow(),
      ),
    );
  }

  void _handleHeaderBack() {
    AppPrimaryNavigationBar.backOrHome(context);
  }
}

class _AccountsContent extends ConsumerWidget {
  final List<BitcoinAccount> accounts;
  final int selectedAccountIndex;
  final Map<String, ReceivingRequestView> receiveAddressOverrides;
  final ValueChanged<int> onAccountChanged;
  final ValueChanged<ReceivingRequestView> onReceiveAddressRotated;
  final VoidCallback onCreateInternalAccount;

  const _AccountsContent({
    required this.accounts,
    required this.selectedAccountIndex,
    required this.receiveAddressOverrides,
    required this.onAccountChanged,
    required this.onReceiveAddressRotated,
    required this.onCreateInternalAccount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (accounts.isEmpty) {
      return _StatePanel(
        icon: KeroseneIcons.wallet,
        title: context.tr.bitcoinAccountsEmptyTitle,
        message: context.tr.bitcoinAccountsEmptyMessage,
        actionLabel: context.tr.bitcoinAccountsNewKeroseneCard,
        onAction: onCreateInternalAccount,
      );
    }

    final selectedIndex = selectedAccountIndex.clamp(0, accounts.length - 1);
    final selectedAccount = accounts[selectedIndex];
    final txAsync = ref.watch(transactionHistoryProvider);
    final requestsAsync = selectedAccount.isWatchOnly
        ? const AsyncValue<List<ReceivingRequestView>>.data(
            <ReceivingRequestView>[],
          )
        : ref.watch(bitcoinAccountReceiveRequestsProvider(selectedAccount.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FocusedAccountPager(
          accounts: accounts,
          selectedIndex: selectedIndex,
          onChanged: onAccountChanged,
          selectedReceiveRequest: receiveAddressOverrides[selectedAccount.id] ??
              firstBitcoinReceiveRequest(requestsAsync),
        ),
        const SizedBox(height: 18),
        _CreateWalletShortcut(onTap: onCreateInternalAccount),
        const SizedBox(height: 22),
        _FocusedAccountOptions(
          account: selectedAccount,
          requestsAsync: requestsAsync,
          receiveAddressOverride: receiveAddressOverrides[selectedAccount.id],
          onReceiveAddressRotated: onReceiveAddressRotated,
        ),
        const SizedBox(height: 28),
        _FocusedAccountHistory(
          account: selectedAccount,
          transactionsAsync: txAsync,
          requestsAsync: requestsAsync,
        ),
      ],
    );
  }
}

class _FocusedAccountPager extends StatelessWidget {
  final List<BitcoinAccount> accounts;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final ReceivingRequestView? selectedReceiveRequest;

  const _FocusedAccountPager({
    required this.accounts,
    required this.selectedIndex,
    required this.onChanged,
    this.selectedReceiveRequest,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: PageController(
              viewportFraction: 0.96,
              initialPage: selectedIndex,
            ),
            onPageChanged: (index) {
              HapticFeedback.selectionClick();
              onChanged(index);
            },
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _FocusedAccountCard(
                  account: accounts[index],
                  receiveRequest:
                      index == selectedIndex ? selectedReceiveRequest : null,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < accounts.length; index++)
              AnimatedContainer(
                duration: KeroseneMotion.fast,
                width: 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == selectedIndex
                      ? colors.text
                      : colors.text.withValues(alpha: 0.18),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _FocusedAccountCard extends StatelessWidget {
  final BitcoinAccount account;
  final ReceivingRequestView? receiveRequest;

  const _FocusedAccountCard({
    required this.account,
    this.receiveRequest,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);
    final label = account.label.trim().isEmpty
        ? context.tr.bitcoinAccountsUnnamedAccount
        : account.label.trim();
    final identifier = bitcoinAccountCardIdentifier(
      account,
      receiveRequest: receiveRequest,
    );
    final displayIdentifier = identifier.isEmpty ? account.id : identifier;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colors.border),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.hexFF222222,
            AppColors.hexFF111111,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.58),
            blurRadius: 28,
            spreadRadius: -14,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 28, 24, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Investimento'.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.inter(
                color: colors.mutedText,
                fontSize: 10,
                letterSpacing: 2.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.newsreader(
                color: colors.text,
                fontSize: 26,
                fontWeight: FontWeight.w500,
                height: 1.1,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              bitcoinAccountCustodyLabel(context, account).toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.inter(
                color: KeroseneBrandTokens.bitcoinOrange,
                fontSize: 12,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _shortText(displayIdentifier),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.technicalMono(
                      textStyle:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colors.mutedText,
                                fontSize: 13,
                                letterSpacing: -0.1,
                                fontWeight: FontWeight.w500,
                              ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _InlineCopyButton(
                  value: displayIdentifier,
                  semanticLabel: 'Copiar identificador da carteira',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineCopyButton extends StatelessWidget {
  final String value;
  final String semanticLabel;

  const _InlineCopyButton({
    required this.value,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        color: colors.text.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: value.trim().isEmpty
              ? null
              : () => _copyText(
                    context,
                    value,
                    title: 'Copiado',
                    message: 'Dado disponível na área de transferência.',
                  ),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(
              KeroseneIcons.copy,
              color: colors.text,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateWalletShortcut extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateWalletShortcut({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Column(
      children: [
        Material(
          color: colors.text,
          shape: const CircleBorder(),
          elevation: colors.isLight ? 1 : 0,
          shadowColor: Colors.black.withValues(alpha: 0.32),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: SizedBox(
              width: 56,
              height: 56,
              child: Icon(
                KeroseneIcons.plus,
                color: colors.background,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Criar carteira',
          style: AppTypography.inter(
            color: colors.text.withValues(alpha: 0.90),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _FocusedAccountOptions extends ConsumerStatefulWidget {
  final BitcoinAccount account;
  final AsyncValue<List<ReceivingRequestView>> requestsAsync;
  final ReceivingRequestView? receiveAddressOverride;
  final ValueChanged<ReceivingRequestView> onReceiveAddressRotated;

  const _FocusedAccountOptions({
    required this.account,
    required this.requestsAsync,
    required this.receiveAddressOverride,
    required this.onReceiveAddressRotated,
  });

  @override
  ConsumerState<_FocusedAccountOptions> createState() =>
      _FocusedAccountOptionsState();
}

class _FocusedAccountOptionsState
    extends ConsumerState<_FocusedAccountOptions> {
  String? _expandedKey;
  String? _busyAction;

  @override
  void didUpdateWidget(covariant _FocusedAccountOptions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.account.id != widget.account.id) {
      _expandedKey = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    final hasPublicMaterial = bitcoinAccountHasPublicMaterial(account);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AccountExpansionItem(
          title: 'STATUS DA CARTEIRA',
          expanded: _expandedKey == 'status',
          onTap: () => _toggle('status'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AccountDetailRows(
                rows: [
                  _AccountDetail(
                    'Status',
                    _friendlyStatus(context, account.status),
                  ),
                  _AccountDetail(
                    'Tipo',
                    bitcoinAccountTypeLabel(context, account),
                  ),
                  _AccountDetail(
                    'Custódia',
                    bitcoinAccountCustodyLabel(context, account),
                  ),
                  _AccountDetail(
                    'Saldo',
                    _formatSats(bitcoinAccountVisibleBalance(account)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _AccountOptionActionButton(
                label: _archiveActionLabel(account),
                icon: account.isWatchOnly
                    ? KeroseneIcons.archive
                    : KeroseneIcons.lock,
                busy: _busyAction == 'archive',
                destructive: true,
                onPressed: () => _archiveWallet(account),
              ),
            ],
          ),
        ),
        _AccountExpansionItem(
          title: 'ENDEREÇO DE RECEBIMENTO',
          expanded: _expandedKey == 'receive',
          onTap: () => _toggle('receive'),
          child: _ReceiveMaterialDetails(
            account: account,
            requestsAsync: widget.requestsAsync,
            receiveAddressOverride: widget.receiveAddressOverride,
            rotating: _busyAction == 'rotate',
            onRotate: account.isWatchOnly
                ? null
                : () => _rotateReceiveAddress(account),
          ),
        ),
        _AccountExpansionItem(
          title: 'NOME DA CARTEIRA',
          expanded: _expandedKey == 'name',
          onTap: () => _toggle('name'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AccountDetailRows(
                rows: [
                  _AccountDetail(
                    'Nome',
                    account.label.trim().isEmpty
                        ? context.tr.bitcoinAccountsUnnamedAccount
                        : account.label.trim(),
                  ),
                  _AccountDetail('ID da conta', account.id, copyable: true),
                  if ((account.cardId ?? '').trim().isNotEmpty)
                    _AccountDetail('Card ID', account.cardId!, copyable: true),
                  if ((account.coldWalletId ?? '').trim().isNotEmpty)
                    _AccountDetail(
                      'Cold wallet ID',
                      account.coldWalletId!,
                      copyable: true,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _AccountOptionActionButton(
                label: 'Trocar nome',
                icon: KeroseneIcons.edit,
                busy: _busyAction == 'rename',
                onPressed: () => _renameWallet(account),
              ),
            ],
          ),
        ),
        if (hasPublicMaterial)
          _AccountExpansionItem(
            title: 'MATERIAL PÚBLICO',
            expanded: _expandedKey == 'public',
            onTap: () => _toggle('public'),
            child: _AccountDetailRows(
              rows: [
                _AccountDetail(
                  'Fingerprint',
                  bitcoinAccountDisplayValue(account.xpubFingerprint),
                  copyable: (account.xpubFingerprint ?? '').trim().isNotEmpty,
                ),
                _AccountDetail(
                  'Derivação',
                  bitcoinAccountDisplayValue(account.derivationPath),
                  copyable: (account.derivationPath ?? '').trim().isNotEmpty,
                ),
                _AccountDetail(
                  'Script policy',
                  bitcoinAccountDisplayValue(account.scriptPolicy),
                  copyable: (account.scriptPolicy ?? '').trim().isNotEmpty,
                ),
              ],
            ),
          ),
        if (account.isWatchOnly)
          _ColdWalletBackendOptions(
            account: account,
            expandedKey: _expandedKey,
            onToggle: _toggle,
          ),
      ],
    );
  }

  void _toggle(String key) {
    HapticFeedback.selectionClick();
    setState(() => _expandedKey = _expandedKey == key ? null : key);
  }

  String _archiveActionLabel(BitcoinAccount account) {
    if (account.isWatchOnly) return 'Arquivar acompanhamento';
    if (account.isCustodialOnchain) return 'Bloquear carteira';
    return 'Bloquear cartão';
  }

  Future<void> _rotateReceiveAddress(BitcoinAccount account) async {
    setState(() => _busyAction = 'rotate');
    try {
      final rotated = await ref
          .read(bitcoinAccountsProvider.notifier)
          .rotateReceiveAddress(accountId: account.id);
      widget.onReceiveAddressRotated(rotated);
      ref.invalidate(bitcoinAccountReceiveRequestsProvider(account.id));
      if (!mounted) return;
      AppNotice.showSuccess(
        context,
        title: 'Endereço rotacionado',
        message: bitcoinAccountDisplayValue(rotated.address),
      );
    } catch (_) {
      if (!mounted) return;
      AppNotice.showError(
        context,
        title: 'Endereço não rotacionado',
        message: 'A Kerosene não conseguiu gerar um novo endereço agora.',
      );
    } finally {
      if (mounted) {
        setState(() => _busyAction = null);
      }
    }
  }

  Future<void> _renameWallet(BitcoinAccount account) async {
    final nextLabel = await _askWalletName(context, account);
    if (nextLabel == null) return;
    setState(() => _busyAction = 'rename');
    try {
      await ref.read(bitcoinAccountsProvider.notifier).renameWallet(
            accountId: account.id,
            label: nextLabel,
          );
      if (!mounted) return;
      AppNotice.showSuccess(
        context,
        title: 'Nome atualizado',
        message: nextLabel,
      );
    } catch (_) {
      if (!mounted) return;
      AppNotice.showError(
        context,
        title: 'Nome não atualizado',
        message: 'Revise o nome da carteira e tente novamente.',
      );
    } finally {
      if (mounted) {
        setState(() => _busyAction = null);
      }
    }
  }

  Future<void> _archiveWallet(BitcoinAccount account) async {
    final confirmed = await _confirmWalletArchive(context, account);
    if (!confirmed) return;
    setState(() => _busyAction = 'archive');
    try {
      await ref.read(bitcoinAccountsProvider.notifier).archiveWallet(
            accountId: account.id,
          );
      if (!mounted) return;
      AppNotice.showSuccess(
        context,
        title: account.isWatchOnly
            ? 'Acompanhamento arquivado'
            : 'Carteira bloqueada',
        message: account.isWatchOnly
            ? 'A carteira saiu da lista ativa.'
            : 'A carteira saiu da lista ativa de movimentação.',
      );
    } catch (_) {
      if (!mounted) return;
      AppNotice.showError(
        context,
        title: 'Ação não concluída',
        message: 'A carteira não pode ser alterada neste momento.',
      );
    } finally {
      if (mounted) {
        setState(() => _busyAction = null);
      }
    }
  }
}

class _ColdWalletBackendOptions extends ConsumerWidget {
  final BitcoinAccount account;
  final String? expandedKey;
  final ValueChanged<String> onToggle;

  const _ColdWalletBackendOptions({
    required this.account,
    required this.expandedKey,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coldWalletId = _coldWalletIdForAccount(account);
    final utxosAsync = ref.watch(bitcoinColdWalletUtxosProvider(coldWalletId));
    final psbtsAsync = ref.watch(bitcoinColdWalletPsbtsProvider(coldWalletId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AccountExpansionItem(
          title: 'UTXOS MONITORADOS',
          expanded: expandedKey == 'utxos',
          onTap: () => onToggle('utxos'),
          child: utxosAsync.when(
            loading: () => const _InlineLoadingState(),
            error: (_, __) => _MiniEmptyState(
              text: context.tr.bitcoinAdvancedUtxosUnavailableMessage,
            ),
            data: (utxos) => _UtxoPreviewList(utxos: utxos),
          ),
        ),
        _AccountExpansionItem(
          title: 'PSBT WORKFLOWS',
          expanded: expandedKey == 'psbts',
          onTap: () => onToggle('psbts'),
          child: psbtsAsync.when(
            loading: () => const _InlineLoadingState(),
            error: (_, __) => _MiniEmptyState(
              text: context.tr.bitcoinAdvancedPsbtsUnavailableMessage,
            ),
            data: (workflows) => _ReadOnlyPsbtWorkflowList(
              workflows: workflows,
              onCopyUnsigned: (workflow) => _copyText(
                context,
                workflow.unsignedPsbt,
                title: context.tr.bitcoinAdvancedPsbtCopiedTitle,
                message: context.tr.bitcoinAdvancedSignExternallyMessage,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyPsbtWorkflowList extends StatelessWidget {
  final List<PsbtWorkflowView> workflows;
  final ValueChanged<PsbtWorkflowView> onCopyUnsigned;

  const _ReadOnlyPsbtWorkflowList({
    required this.workflows,
    required this.onCopyUnsigned,
  });

  @override
  Widget build(BuildContext context) {
    if (workflows.isEmpty) {
      return _MiniEmptyState(text: context.tr.bitcoinAdvancedNoPsbts);
    }

    final visible = workflows.take(3).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < visible.length; index++)
          _ReadOnlyPsbtWorkflowRow(
            workflow: visible[index],
            showDivider: index != visible.length - 1,
            onCopyUnsigned: () => onCopyUnsigned(visible[index]),
          ),
        if (workflows.length > visible.length)
          _MiniHint(
            text: context.tr.bitcoinAdvancedHiddenPsbts(
              workflows.length - visible.length,
            ),
          ),
      ],
    );
  }
}

class _ReadOnlyPsbtWorkflowRow extends StatelessWidget {
  final PsbtWorkflowView workflow;
  final bool showDivider;
  final VoidCallback onCopyUnsigned;

  const _ReadOnlyPsbtWorkflowRow({
    required this.workflow,
    required this.showDivider,
    required this.onCopyUnsigned,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(color: KeroseneBrandTokens.borderSubtle),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _shortText(workflow.destinationAddress),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    color: KeroseneBrandTokens.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _Pill(text: _psbtStatusLabel(context, workflow.status)),
            ],
          ),
          const SizedBox(height: 8),
          _AccountDetailRows(
            rows: [
              _AccountDetail('Valor', _formatSats(workflow.amountSats)),
              _AccountDetail('Taxa', _formatSats(workflow.estimatedFeeSats)),
              if ((workflow.broadcastTxidRef ?? '').trim().isNotEmpty)
                _AccountDetail(
                  'Broadcast',
                  workflow.broadcastTxidRef!,
                  copyable: true,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              style: BitcoinAccountsColors.of(context)
                  .outlinedButtonStyle(minHeight: 38),
              onPressed: onCopyUnsigned,
              icon: const Icon(KeroseneIcons.copy, size: 15),
              label: Text(context.tr.bitcoinAdvancedCopyUnsignedAction),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiveMaterialDetails extends StatelessWidget {
  final BitcoinAccount account;
  final AsyncValue<List<ReceivingRequestView>> requestsAsync;
  final ReceivingRequestView? receiveAddressOverride;
  final VoidCallback? onRotate;
  final bool rotating;

  const _ReceiveMaterialDetails({
    required this.account,
    required this.requestsAsync,
    required this.receiveAddressOverride,
    this.onRotate,
    this.rotating = false,
  });

  @override
  Widget build(BuildContext context) {
    if (account.isWatchOnly) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AccountDetailRows(
            rows: [
              _AccountDetail(
                'Fingerprint',
                bitcoinAccountDisplayValue(account.xpubFingerprint),
                copyable: (account.xpubFingerprint ?? '').trim().isNotEmpty,
              ),
              _AccountDetail(
                'Cold wallet',
                _coldWalletIdForAccount(account),
                copyable: true,
              ),
              _AccountDetail(
                  'Status', _friendlyStatus(context, account.status)),
            ],
          ),
          const SizedBox(height: 12),
          const _AccountOptionNote(
            text: 'Carteiras watch-only não emitem endereço pelo app.',
          ),
        ],
      );
    }

    return requestsAsync.when(
      loading: () => const _InlineLoadingState(),
      error: (_, __) => _MiniEmptyState(
        text: context.tr.bitcoinReceiveRequestsLoadErrorMessage,
      ),
      data: (requests) {
        final request = receiveAddressOverride ??
            (requests.isEmpty ? null : requests.first);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AccountDetailRows(
              rows: [
                _AccountDetail(
                  'Endereço',
                  bitcoinAccountDisplayValue(request?.address),
                  copyable: (request?.address ?? '').trim().isNotEmpty,
                ),
                _AccountDetail(
                  'BIP21',
                  bitcoinAccountDisplayValue(request?.bip21),
                  copyable: (request?.bip21 ?? '').trim().isNotEmpty,
                ),
                _AccountDetail(
                  'Status',
                  request == null
                      ? _friendlyStatus(context, account.status)
                      : _receiveStatusLabel(context, request.status),
                ),
                if (request?.amountSats != null)
                  _AccountDetail('Valor', _formatSats(request!.amountSats!)),
                if (request != null)
                  _AccountDetail(
                    'Expiração',
                    request.expiry.isEmpty
                        ? context.tr.bitcoinReceiveRequestsNoExpiry
                        : request.expiry,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _AccountOptionActionButton(
              label: 'Rotacionar endereço',
              icon: KeroseneIcons.refresh,
              busy: rotating,
              onPressed: onRotate,
            ),
          ],
        );
      },
    );
  }
}

class _AccountOptionActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool busy;
  final bool destructive;

  const _AccountOptionActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.busy = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);
    return OutlinedButton.icon(
      style: colors.outlinedButtonStyle(
        minHeight: 42,
        foregroundColor: destructive
            ? KeroseneBrandTokens.error
            : KeroseneBrandTokens.textPrimary,
      ),
      onPressed: busy ? null : onPressed,
      icon: busy
          ? const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 15),
      label: Text(label),
    );
  }
}

class _AccountOptionNote extends StatelessWidget {
  final String text;

  const _AccountOptionNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.inter(
        color: KeroseneBrandTokens.textMuted,
        fontSize: 12,
        height: 1.35,
        letterSpacing: 0,
      ),
    );
  }
}

Future<String?> _askWalletName(
  BuildContext context,
  BitcoinAccount account,
) async {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return _WalletNameDialog(initialName: account.label.trim());
    },
  );
}

class _WalletNameDialog extends StatefulWidget {
  final String initialName;

  const _WalletNameDialog({required this.initialName});

  @override
  State<_WalletNameDialog> createState() => _WalletNameDialogState();
}

class _WalletNameDialogState extends State<_WalletNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Trocar nome'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 96,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(labelText: 'Nome da carteira'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(context.tr.save),
        ),
      ],
    );
  }
}

Future<bool> _confirmWalletArchive(
  BuildContext context,
  BitcoinAccount account,
) async {
  final title = account.isWatchOnly
      ? 'Arquivar acompanhamento'
      : account.isCustodialOnchain
          ? 'Bloquear carteira'
          : 'Bloquear cartão';
  final message = account.isWatchOnly
      ? 'Esta carteira deixará de aparecer como acompanhamento ativo.'
      : 'Esta carteira deixará de aparecer como ativa para movimentação.';
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.tr.confirm),
          ),
        ],
      );
    },
  );
  return confirmed == true;
}

class _AccountExpansionItem extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;

  const _AccountExpansionItem({
    required this.title,
    required this.expanded,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return AnimatedContainer(
      duration: KeroseneMotion.medium,
      curve: KeroseneMotion.standard,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Icon(
                      _accountOptionIcon(title),
                      color: colors.text,
                      size: 20,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          color: colors.text.withValues(alpha: 0.92),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      duration: KeroseneMotion.medium,
                      turns: expanded ? 0.5 : 0,
                      child: Icon(
                        KeroseneIcons.chevronDown,
                        color: colors.mutedText,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: KeroseneMotion.medium,
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

IconData _accountOptionIcon(String title) {
  return switch (title) {
    'STATUS DA CARTEIRA' => KeroseneIcons.security,
    'ENDEREÇO DE RECEBIMENTO' => KeroseneIcons.download,
    'NOME DA CARTEIRA' => KeroseneIcons.user,
    'MATERIAL PÚBLICO' => KeroseneIcons.settings,
    'UTXOS MONITORADOS' => KeroseneIcons.database,
    'PSBT WORKFLOWS' => KeroseneIcons.document,
    _ => KeroseneIcons.settings,
  };
}

class _AccountDetail {
  final String label;
  final String value;
  final bool copyable;

  const _AccountDetail(
    this.label,
    this.value, {
    this.copyable = false,
  });
}

class _AccountDetailRows extends StatelessWidget {
  final List<_AccountDetail> rows;

  const _AccountDetailRows({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < rows.length; index++)
          _AccountDetailRow(
            row: rows[index],
            showDivider: index != rows.length - 1,
          ),
      ],
    );
  }
}

class _AccountDetailRow extends StatelessWidget {
  final _AccountDetail row;
  final bool showDivider;

  const _AccountDetailRow({
    required this.row,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: KeroseneBrandTokens.borderSubtle,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.label,
              style: AppTypography.inter(
                color: KeroseneBrandTokens.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 2,
            child: Text(
              row.value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.technicalMono(
                textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: KeroseneBrandTokens.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
              ),
            ),
          ),
          if (row.copyable) ...[
            const SizedBox(width: 4),
            _InlineCopyButton(
              value: row.value,
              semanticLabel: 'Copiar ${row.label}',
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineLoadingState extends StatelessWidget {
  const _InlineLoadingState();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 48,
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _FocusedAccountHistory extends StatelessWidget {
  final BitcoinAccount account;
  final AsyncValue<List<Transaction>> transactionsAsync;
  final AsyncValue<List<ReceivingRequestView>> requestsAsync;

  const _FocusedAccountHistory({
    required this.account,
    required this.transactionsAsync,
    required this.requestsAsync,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);
    final requests =
        requestsAsync.asData?.value ?? const <ReceivingRequestView>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr.primaryNavHistory,
                style: AppTypography.newsreader(
                  color: colors.text,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ),
            Icon(
              KeroseneIcons.moveHorizontal,
              color: colors.mutedText,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Filtrar'.toUpperCase(),
              style: AppTypography.inter(
                color: colors.mutedText,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        transactionsAsync.when(
          loading: () => const _CompactLoadingPanel(),
          error: (_, __) => _BareHistoryMessage(
            text: context.tr.bitcoinAccountsErrorMessage,
          ),
          data: (transactions) {
            final rows = _transactionsForAccount(
              account: account,
              transactions: transactions,
              requests: requests,
            ).take(8).toList(growable: false);

            if (rows.isEmpty) {
              return const _BareHistoryMessage(
                text: 'Sem transações neste cartão.',
              );
            }

            return Column(
              children: [
                for (var index = 0; index < rows.length; index++)
                  _FocusedHistoryRow(
                    transaction: rows[index],
                    showDivider: index != rows.length - 1,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _BareHistoryMessage extends StatelessWidget {
  final String text;

  const _BareHistoryMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Text(
        text,
        style: AppTypography.inter(
          color: KeroseneBrandTokens.textMuted,
          fontSize: 13,
          height: 1.35,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _FocusedHistoryRow extends StatelessWidget {
  final Transaction transaction;
  final bool showDivider;

  const _FocusedHistoryRow({
    required this.transaction,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);
    final title = transaction.description?.trim().isNotEmpty == true
        ? transaction.description!.trim()
        : _transactionTitle(transaction);
    final detail = bitcoinAccountHistoryDetail(transaction);

    return Container(
      margin: EdgeInsets.only(bottom: showDivider ? 16 : 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.text.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  transaction.isInternal
                      ? KeroseneIcons.wallet
                      : KeroseneIcons.history,
                  color: colors.text,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        color: colors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.technicalMono(
                        textStyle:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: colors.mutedText,
                                  fontSize: 11,
                                  letterSpacing: 0,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                bitcoinAccountHistoryTimestampLabel(transaction.timestamp),
                textAlign: TextAlign.right,
                style: AppTypography.inter(
                  color: colors.mutedText,
                  fontSize: 10,
                  height: 1.25,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _signedSats(transaction),
            style: AppTypography.technicalMono(
              textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    letterSpacing: 0,
                  ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: _TransparentStatusPill(
              text: bitcoinAccountTransactionStatusLabel(
                  context, transaction.status),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransparentStatusPill extends StatelessWidget {
  final String text;

  const _TransparentStatusPill({required this.text});

  @override
  Widget build(BuildContext context) {
    const accent = KeroseneBrandTokens.bitcoinOrange;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: accent.withValues(alpha: 0.10),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          text.toUpperCase(),
          style: AppTypography.inter(
            color: accent,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _InternalCardPager extends StatelessWidget {
  final List<BitcoinAccount> accounts;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onTapCard;

  const _InternalCardPager({
    required this.accounts,
    required this.selectedIndex,
    required this.onChanged,
    required this.onTapCard,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Column(
      children: [
        SizedBox(
          height: 224,
          child: PageView.builder(
            controller: PageController(
              viewportFraction: 0.96,
              initialPage: selectedIndex,
            ),
            onPageChanged: onChanged,
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _InternalWalletCard(
                  account: accounts[index],
                  onTap: onTapCard,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < accounts.length; index++)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == selectedIndex
                      ? colors.selectedDot
                      : colors.idleDot,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _InternalWalletCard extends StatelessWidget {
  final BitcoinAccount account;
  final VoidCallback onTap;

  const _InternalWalletCard({required this.account, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = account.label.trim().isEmpty
        ? context.tr.bitcoinAccountsUnnamedAccount
        : account.label.trim();
    final typeDescription = account.walletTypeDescription.trim().isEmpty
        ? 'Carteira Global'
        : account.walletTypeDescription.trim();
    final colors = BitcoinAccountsColors.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 224,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.hexFF1E1B38, AppColors.hexFF141414],
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.cardShadow,
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.newsreader(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 21,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    Text(
                      _cardExpiryLabel(account),
                      style: AppTypography.newsreader(
                        color: Colors.white.withValues(alpha: 0.70),
                        fontSize: 18,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _Pill(text: typeDescription),
                ),
                const Spacer(),
                Text(
                  kKeroseneBrandLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.newsreader(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _shortCardIdentifier(account),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.technicalMono(
                          textStyle:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.50),
                                    fontSize: 11,
                                    letterSpacing: 1.2,
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _cardCode(account),
                      style: AppTypography.technicalMono(
                        textStyle:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.50),
                                  fontSize: 11,
                                  letterSpacing: 1.2,
                                ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InternalBalanceSection extends StatelessWidget {
  final BitcoinAccount account;

  const _InternalBalanceSection({required this.account});

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);
    final available = account.balanceAvailableSats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pill(text: context.tr.bitcoinAccountsKeroseneCardBadge),
            _Pill(text: _friendlyStatus(context, account.status)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                context.tr.bitcoinAccountsAvailableBalance,
                style: AppTypography.inter(
                  color: colors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ),
            Text(
              _formatSats(available),
              style: AppTypography.inter(
                color: colors.text,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          context.tr.bitcoinAccountsKeroseneCardNote,
          style: AppTypography.inter(
            color: colors.mutedText,
            fontSize: 13,
            height: 1.35,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _ReceiveRequestsSection extends ConsumerWidget {
  final AsyncValue<List<ReceivingRequestView>> requestsAsync;
  final VoidCallback onRetry;

  const _ReceiveRequestsSection({
    required this.requestsAsync,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(networkStatusProvider);

    return _TransactionsPanel(
      title: context.tr.bitcoinReceiveRequestsTitle,
      children: requestsAsync.when(
        loading: () => const [
          _DarkSkeletonRow(),
          _DarkSkeletonRow(),
        ],
        error: (_, __) => [
          _DarkActionMessage(
            icon: KeroseneIcons.error,
            title: isOnline
                ? context.tr.bitcoinReceiveRequestsLoadErrorTitle
                : context.tr.bitcoinReceiveRequestsOfflineTitle,
            message: isOnline
                ? context.tr.bitcoinReceiveRequestsLoadErrorMessage
                : context.tr.bitcoinReceiveRequestsOfflineMessage,
            actionLabel: context.tr.retry,
            onAction: onRetry,
          ),
        ],
        data: (requests) {
          if (requests.isEmpty) {
            return [
              _DarkActionMessage(
                icon: KeroseneIcons.inbox,
                title: context.tr.bitcoinReceiveRequestsEmptyTitle,
                message: context.tr.bitcoinReceiveRequestsEmptyMessage,
              ),
            ];
          }

          final visible = requests.take(5).toList(growable: false);
          return [
            for (var index = 0; index < visible.length; index++)
              _ReceiveRequestRow(
                request: visible[index],
                showDivider: index != visible.length - 1,
              ),
          ];
        },
      ),
    );
  }
}

class _ReceiveRequestRow extends StatelessWidget {
  final ReceivingRequestView request;
  final bool showDivider;

  const _ReceiveRequestRow({
    required this.request,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);
    final title = request.amountSats == null
        ? context.tr.bitcoinReceiveRequestsFlexibleAmount
        : _formatSats(request.amountSats!);
    final subtitle = request.address.isEmpty
        ? request.id
        : '${_shortText(request.address)} | ${request.expiry.isEmpty ? context.tr.bitcoinReceiveRequestsNoExpiry : request.expiry}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: colors.rowDivider,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    color: colors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.technicalMono(
                    textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.mutedText,
                          fontSize: 12,
                          letterSpacing: 0,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _Pill(text: _receiveStatusLabel(context, request.status)),
        ],
      ),
    );
  }
}

class _InternalTransactionsSection extends StatelessWidget {
  final BitcoinAccount account;
  final AsyncValue<List<Transaction>> transactionsAsync;
  final AsyncValue<List<ReceivingRequestView>> requestsAsync;

  const _InternalTransactionsSection({
    required this.account,
    required this.transactionsAsync,
    required this.requestsAsync,
  });

  @override
  Widget build(BuildContext context) {
    return requestsAsync.when(
      loading: () => const _CompactLoadingPanel(),
      error: (_, __) => _TransactionsPanel(
        title: 'Transactions',
        children: [
          _DarkListMessage(text: context.tr.bitcoinAccountsErrorMessage),
        ],
      ),
      data: (requests) => transactionsAsync.when(
        loading: () => const _CompactLoadingPanel(),
        error: (_, __) => _TransactionsPanel(
          title: 'Transactions',
          children: [
            _DarkListMessage(text: context.tr.bitcoinAccountsErrorMessage),
          ],
        ),
        data: (transactions) {
          final rows = _transactionsForAccount(
            account: account,
            transactions: transactions,
            requests: requests,
          ).take(3).toList(growable: false);

          return _TransactionsPanel(
            title: 'Transactions',
            children: rows.isEmpty
                ? [_DarkListMessage(text: 'Sem transações desta carteira.')]
                : [
                    for (var index = 0; index < rows.length; index++)
                      _TransactionSummaryRow(
                        transaction: rows[index],
                        showDivider: index != rows.length - 1,
                      ),
                  ],
          );
        },
      ),
    );
  }
}

class _TransactionsPanel extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _TransactionsPanel({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: AppTypography.newsreader(
            color: colors.text,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceRaised,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

class _TransactionSummaryRow extends StatelessWidget {
  final Transaction transaction;
  final bool showDivider;

  const _TransactionSummaryRow({
    required this.transaction,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);
    final title = transaction.description?.trim().isNotEmpty == true
        ? transaction.description!.trim()
        : _transactionTitle(transaction);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: colors.rowDivider,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    color: colors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _relativeTransactionDate(transaction.timestamp),
                  style: AppTypography.inter(
                    color: colors.mutedText,
                    fontSize: 13,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _signedSats(transaction),
            style: AppTypography.inter(
              color: colors.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkListMessage extends StatelessWidget {
  final String text;

  const _DarkListMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        style: AppTypography.inter(
          color: colors.mutedText,
          fontSize: 13,
          height: 1.35,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _DarkActionMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _DarkActionMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.mutedText, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.inter(
                    color: colors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: AppTypography.inter(
                    color: colors.mutedText,
                    fontSize: 13,
                    height: 1.35,
                    letterSpacing: 0,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: onAction,
                    icon: const Icon(KeroseneIcons.refresh, size: 15),
                    label: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkSkeletonRow extends StatelessWidget {
  const _DarkSkeletonRow();

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Container(
      height: 58,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.skeleton,
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

class _CompactLoadingPanel extends StatelessWidget {
  const _CompactLoadingPanel();

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return SizedBox(
      height: 88,
      child: Center(
        child: CircularProgressIndicator(color: colors.text, strokeWidth: 2),
      ),
    );
  }
}

class _ColdWalletSection extends StatelessWidget {
  final List<BitcoinAccount> accounts;

  const _ColdWalletSection({required this.accounts});

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr.bitcoinAccountsColdWalletSection,
                style: AppTypography.newsreader(
                  color: colors.text,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (accounts.isEmpty)
          _MutedPanel(text: context.tr.bitcoinAccountsNoColdWallet)
        else ...[
          for (final account in accounts) _ColdWalletTile(account: account),
        ],
      ],
    );
  }
}

class _ColdWalletTile extends StatelessWidget {
  final BitcoinAccount account;

  const _ColdWalletTile({required this.account});

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);
    final label = account.label.trim().isEmpty
        ? context.tr.bitcoinAccountsUnnamedAccount
        : account.label.trim();
    final typeDescription = account.walletTypeDescription.trim().isEmpty
        ? context.tr.bitcoinAccountsColdWalletBadge
        : account.walletTypeDescription.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(KeroseneIcons.coldWallet, color: colors.text, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Pill(text: typeDescription),
                        _Pill(text: context.tr.bitcoinAccountsReviewBalance),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        color: colors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr.bitcoinAccountsObservedBalance,
                      style: AppTypography.inter(
                        color: colors.mutedText,
                        fontSize: 12,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatSats(account.observedBalanceSats),
                      style: AppTypography.inter(
                        color: colors.mutedText,
                        fontSize: 13,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr.bitcoinAccountsColdWalletNote,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        color: colors.mutedText,
                        fontSize: 12,
                        height: 1.35,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                account.xpubFingerprint ?? account.coldWalletId ?? '',
                style: AppTypography.technicalMono(
                  textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.mutedText,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                ),
              ),
            ],
          ),
          _ColdWalletAdvancedPanel(account: account),
        ],
      ),
    );
  }
}

class _ColdWalletAdvancedPanel extends ConsumerWidget {
  final BitcoinAccount account;

  const _ColdWalletAdvancedPanel({required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: _MutedPanel(
        text: context.tr.bitcoinAdvancedPsbtsUnavailableMessage,
      ),
    );
  }
}

class _AdvancedSubsection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _AdvancedSubsection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return DecoratedBox(
      decoration: colors.panelDecoration(
        color: colors.surface,
        showShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: colors.text, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.inter(
                      color: colors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _UtxoPreviewList extends StatelessWidget {
  final List<ColdWalletUtxoView> utxos;

  const _UtxoPreviewList({required this.utxos});

  @override
  Widget build(BuildContext context) {
    if (utxos.isEmpty) {
      return _MiniEmptyState(
        text: context.tr.bitcoinAdvancedNoUtxos,
      );
    }

    final visible = utxos.take(4).toList(growable: false);
    final spendable = utxos.where((utxo) => utxo.isSpendable).fold<int>(
          0,
          (total, utxo) => total + utxo.amountSats,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MiniMetricRow(
          label: context.tr.bitcoinAdvancedSpendableForPsbt,
          value: _formatSats(spendable),
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < visible.length; index++)
          _UtxoRow(
            utxo: visible[index],
            showDivider: index != visible.length - 1,
          ),
        if (utxos.length > visible.length)
          _MiniHint(
            text: context.tr.bitcoinAdvancedHiddenUtxos(
              utxos.length - visible.length,
            ),
          ),
      ],
    );
  }
}

class _UtxoRow extends StatelessWidget {
  final ColdWalletUtxoView utxo;
  final bool showDivider;

  const _UtxoRow({
    required this.utxo,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);
    final outpointLabel = '${utxo.txidRef}:${utxo.vout}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: colors.rowDivider,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              outpointLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.technicalMono(
                textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.mutedText,
                      fontSize: 11,
                      letterSpacing: 0,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatSats(utxo.amountSats),
            style: AppTypography.inter(
              color: colors.text,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(width: 8),
          _Pill(text: _utxoStatusLabel(context, utxo.status)),
        ],
      ),
    );
  }
}

class _PsbtPreviewList extends StatelessWidget {
  final List<PsbtWorkflowView> workflows;
  final ValueChanged<PsbtWorkflowView> onSubmitSigned;
  final ValueChanged<PsbtWorkflowView> onCopyUnsigned;

  const _PsbtPreviewList({
    required this.workflows,
    required this.onSubmitSigned,
    required this.onCopyUnsigned,
  });

  @override
  Widget build(BuildContext context) {
    if (workflows.isEmpty) {
      return _MiniEmptyState(
        text: context.tr.bitcoinAdvancedNoPsbts,
      );
    }

    final visible = workflows.take(3).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < visible.length; index++)
          _PsbtWorkflowRow(
            workflow: visible[index],
            showDivider: index != visible.length - 1,
            onCopyUnsigned: () => onCopyUnsigned(visible[index]),
            onSubmitSigned: visible[index].awaitsSignature
                ? () => onSubmitSigned(visible[index])
                : null,
          ),
        if (workflows.length > visible.length)
          _MiniHint(
            text: context.tr.bitcoinAdvancedHiddenPsbts(
              workflows.length - visible.length,
            ),
          ),
      ],
    );
  }
}

class _PsbtWorkflowRow extends StatelessWidget {
  final PsbtWorkflowView workflow;
  final bool showDivider;
  final VoidCallback onCopyUnsigned;
  final VoidCallback? onSubmitSigned;

  const _PsbtWorkflowRow({
    required this.workflow,
    required this.showDivider,
    required this.onCopyUnsigned,
    this.onSubmitSigned,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: colors.rowDivider,
                ),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _shortText(workflow.destinationAddress),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    color: colors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _Pill(text: _psbtStatusLabel(context, workflow.status)),
            ],
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(text: _formatSats(workflow.amountSats)),
              _Pill(
                text:
                    '${context.tr.bitcoinAdvancedFeePrefix} ${_formatSats(workflow.estimatedFeeSats)}',
              ),
              if ((workflow.broadcastTxidRef ?? '').isNotEmpty)
                _Pill(text: workflow.broadcastTxidRef!),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                style: colors.outlinedButtonStyle(minHeight: 38),
                onPressed: onCopyUnsigned,
                icon: const Icon(KeroseneIcons.copy, size: 15),
                label: Text(context.tr.bitcoinAdvancedCopyUnsignedAction),
              ),
              if (onSubmitSigned != null)
                OutlinedButton.icon(
                  style: colors.outlinedButtonStyle(minHeight: 38),
                  onPressed: onSubmitSigned,
                  icon: const Icon(KeroseneIcons.send, size: 15),
                  label: Text(context.tr.bitcoinAdvancedSubmitSignatureAction),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaxEventsSection extends ConsumerWidget {
  const _TaxEventsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(kfeTaxEventsProvider);
    return _TransactionsPanel(
      title: context.tr.bitcoinTaxReportsTitle,
      children: eventsAsync.when(
        loading: () => const [
          _DarkSkeletonRow(),
          _DarkSkeletonRow(),
        ],
        error: (_, __) => [
          _DarkActionMessage(
            icon: KeroseneIcons.error,
            title: context.tr.taxEventsUnavailableTitle,
            message: context.tr.taxEventsUnavailableMessage,
            actionLabel: context.tr.retry,
            onAction: () => ref.invalidate(kfeTaxEventsProvider),
          ),
        ],
        data: (events) {
          if (events.isEmpty) {
            return [
              _DarkActionMessage(
                icon: KeroseneIcons.history,
                title: context.tr.bitcoinTaxNoEventsTitle,
                message: context.tr.bitcoinTaxNoEventsMessage,
              ),
              _TaxExportActions(),
            ];
          }

          final visible = events.take(4).toList(growable: false);
          return [
            for (var index = 0; index < visible.length; index++)
              _TaxEventRow(
                event: visible[index],
                showDivider: index != visible.length - 1,
              ),
            if (events.length > visible.length)
              _DarkListMessage(
                text: context.tr.bitcoinTaxHiddenEvents(
                  events.length - visible.length,
                ),
              ),
            _TaxExportActions(),
          ];
        },
      ),
    );
  }
}

class _TaxEventRow extends ConsumerWidget {
  final TaxEventView event;
  final bool showDivider;

  const _TaxEventRow({
    required this.event,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = BitcoinAccountsColors.of(context);
    final transferLabel =
        '${_formatSats(event.quantitySats)} | ${event.sourceRef.isEmpty ? event.asset : event.sourceRef}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: colors.rowDivider,
                ),
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(KeroseneIcons.history, color: colors.mutedText, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _taxEventTypeLabel(context, event.eventType),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    color: colors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  transferLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.technicalMono(
                    textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.mutedText,
                          fontSize: 12,
                          letterSpacing: 0,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: context.tr.bitcoinTaxClassifyTooltip,
            color: colors.surfaceRaised,
            icon: Icon(
              KeroseneIcons.chevronDown,
              color: colors.text,
              size: 18,
            ),
            onSelected: (classification) async {
              try {
                final service = ref.read(bitcoinAccountsServiceProvider);
                await service.classifyTaxEvent(
                  eventId: event.id,
                  classification: classification,
                );
                ref.invalidate(kfeTaxEventsProvider);
                if (!context.mounted) return;
                AppNotice.showSuccess(
                  context,
                  title: context.tr.bitcoinTaxClassificationUpdatedTitle,
                  message: _taxClassificationLabel(context, classification),
                );
              } catch (_) {
                if (!context.mounted) return;
                AppNotice.showError(
                  context,
                  title: context.tr.bitcoinTaxClassificationNotSavedTitle,
                  message: context.tr.bitcoinTaxRetryLaterMessage,
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'SELF_TRANSFER',
                child: Text(context.tr.bitcoinTaxClassSelfTransfer),
              ),
              PopupMenuItem(
                value: 'THIRD_PARTY_DEPOSIT',
                child: Text(context.tr.bitcoinTaxClassThirdPartyDeposit),
              ),
              PopupMenuItem(
                value: 'SPEND',
                child: Text(context.tr.bitcoinTaxClassSpend),
              ),
              PopupMenuItem(
                value: 'FEE',
                child: Text(context.tr.bitcoinTaxClassFee),
              ),
              PopupMenuItem(
                value: 'UNKNOWN',
                child: Text(context.tr.bitcoinTaxClassUnknown),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaxExportActions extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: () => _exportTaxEvents(context, ref, 'json'),
            icon: const Icon(KeroseneIcons.download, size: 15),
            label: Text(context.tr.bitcoinTaxExportJsonAction),
          ),
          OutlinedButton.icon(
            onPressed: () => _exportTaxEvents(context, ref, 'csv'),
            icon: const Icon(KeroseneIcons.download, size: 15),
            label: Text(context.tr.bitcoinTaxExportCsvAction),
          ),
        ],
      ),
    );
  }

  Future<void> _exportTaxEvents(
    BuildContext context,
    WidgetRef ref,
    String format,
  ) async {
    try {
      final service = ref.read(bitcoinAccountsServiceProvider);
      final exported = await service.exportTaxEvents(format: format);
      final content = exported.content ??
          const JsonEncoder.withIndent('  ').convert(
            exported.toJson(),
          );
      await Clipboard.setData(ClipboardData(text: content));
      if (!context.mounted) return;
      AppNotice.showSuccess(
        context,
        title: context.tr.bitcoinTaxReportCopiedTitle,
        message: exported.filename,
      );
    } catch (_) {
      if (!context.mounted) return;
      AppNotice.showError(
        context,
        title: context.tr.bitcoinTaxExportUnavailableTitle,
        message: context.tr.bitcoinTaxExportUnavailableMessage,
      );
    }
  }
}

class _MiniLoadingRows extends StatelessWidget {
  const _MiniLoadingRows();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _DarkSkeletonRow(),
        _DarkSkeletonRow(),
      ],
    );
  }
}

class _MiniActionState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _MiniActionState({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return _DarkActionMessage(
      icon: icon,
      title: title,
      message: message,
      actionLabel: context.tr.retry,
      onAction: onRetry,
    );
  }
}

class _MiniEmptyState extends StatelessWidget {
  final String text;

  const _MiniEmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return _MiniHint(text: text);
  }
}

class _MiniHint extends StatelessWidget {
  final String text;

  const _MiniHint({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: AppTypography.inter(
          color: colors.mutedText,
          fontSize: 12,
          height: 1.35,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _MiniMetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetricRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.inter(
              color: colors.mutedText,
              fontSize: 12,
              letterSpacing: 0,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.inter(
            color: colors.text,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _InternalAccountManagementView extends StatefulWidget {
  final BitcoinAccount account;
  final VoidCallback onReceive;

  const _InternalAccountManagementView({
    required this.account,
    required this.onReceive,
  });

  @override
  State<_InternalAccountManagementView> createState() =>
      _InternalAccountManagementViewState();
}

class _InternalAccountManagementViewState
    extends State<_InternalAccountManagementView> {
  String? _expandedKey = 'balance';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InternalWalletCard(account: widget.account, onTap: () {}),
        const SizedBox(height: 18),
        _ManagementItem(
          title: 'Saldo disponível',
          expanded: _expandedKey == 'balance',
          onTap: () => _toggle('balance'),
          rows: [
            ('Disponível', _formatSats(widget.account.balanceAvailableSats)),
          ],
        ),
        _ManagementItem(
          title: 'Endereço de recebimento',
          expanded: _expandedKey == 'receive',
          onTap: () {
            _toggle('receive');
            widget.onReceive();
          },
          rows: const [
            ('Ação', 'Gerar ou visualizar endereço'),
          ],
        ),
        _ManagementItem(
          title: 'Data de validade',
          expanded: _expandedKey == 'expiry',
          onTap: () => _toggle('expiry'),
          rows: [
            ('Validade', _cardExpiryLabel(widget.account)),
          ],
        ),
      ],
    );
  }

  void _toggle(String key) {
    HapticFeedback.selectionClick();
    setState(() => _expandedKey = _expandedKey == key ? null : key);
  }
}

class _ManagementItem extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onTap;
  final List<(String, String)> rows;

  const _ManagementItem({
    required this.title,
    required this.expanded,
    required this.onTap,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return AnimatedContainer(
      duration: KeroseneMotion.medium,
      curve: KeroseneMotion.standard,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 18,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.inter(
                          color: colors.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      duration: KeroseneMotion.medium,
                      turns: expanded ? 0.5 : 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colors.background,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          KeroseneIcons.chevronDown,
                          color: colors.text,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
              child: Column(
                children: [
                  Divider(color: colors.rowDivider),
                  for (final row in rows)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              row.$1,
                              style: AppTypography.inter(
                                color: colors.mutedText,
                                fontSize: 13,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          Text(
                            row.$2,
                            style: AppTypography.inter(
                              color: colors.mutedText,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: KeroseneMotion.medium,
            sizeCurve: KeroseneMotion.standard,
          ),
        ],
      ),
    );
  }
}
