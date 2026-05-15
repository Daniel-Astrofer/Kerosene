import 'dart:async';
import 'dart:math';

import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:teste/core/presentation/widgets/app_notice.dart';
import 'package:teste/core/presentation/widgets/app_primary_navigation.dart';
import 'package:teste/core/presentation/widgets/bitcoin_address_blocks.dart';
import 'package:teste/core/responsive/kerosene_responsive.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/theme/monochrome_theme.dart';
import 'package:teste/features/bitcoin_accounts/data/bitcoin_accounts_service.dart';
import 'package:teste/features/bitcoin_accounts/data/cold_wallet_public_material.dart';
import 'package:teste/features/bitcoin_accounts/presentation/bitcoin_accounts_provider.dart';
import 'package:teste/l10n/l10n_extension.dart';

class BitcoinAccountsScreen extends ConsumerWidget {
  const BitcoinAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(bitcoinAccountsProvider);
    final bottom = AppPrimaryNavigationBar.scaffoldBottomClearance(context);
    final responsive = context.responsive;

    return Scaffold(
      backgroundColor: monoBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              color: monoTextColor,
              backgroundColor: monoSurfaceColor,
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
                          _Header(
                            title: context.l10n.bitcoinAccountsTitle,
                            subtitle: context.l10n.bitcoinAccountsSubtitle,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          accounts.when(
                            loading: () => const _AccountsSkeleton(),
                            error: (_, __) => _StatePanel(
                              icon: LucideIcons.alertTriangle,
                              title: context.l10n.bitcoinAccountsErrorTitle,
                              message: context.l10n.bitcoinAccountsErrorMessage,
                              actionLabel: context.l10n.tryAgain,
                              onAction: () => ref
                                  .read(bitcoinAccountsProvider.notifier)
                                  .refresh(),
                            ),
                            data: (items) => _AccountsContent(accounts: items),
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
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;

  const _Header({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _IconFrame(icon: LucideIcons.bitcoin),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: monoTextColor,
                      fontSize: responsive.compactFontSize(
                        tiny: 22,
                        compact: 24,
                        regular: 25,
                      ),
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: monoMutedTextColor,
                height: 1.4,
              ),
        ),
      ],
    );
  }
}

class _AccountsContent extends ConsumerWidget {
  final List<BitcoinAccount> accounts;

  const _AccountsContent({required this.accounts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final internal = accounts.where((account) => account.isInternal).toList();
    final watchOnly = accounts.where((account) => account.isWatchOnly).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final shouldStack = constraints.maxWidth < 360;
            final buttons = [
              _ActionButton(
                icon: LucideIcons.snowflake,
                label: context.l10n.bitcoinAccountsCreateColdWallet,
                onTap: () => _openColdWalletFlow(context),
              ),
              _ActionButton(
                icon: LucideIcons.creditCard,
                label: context.l10n.bitcoinAccountsNewKeroseneCard,
                onTap: () => _showCreateInternalCard(context, ref),
              ),
            ];

            if (shouldStack) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buttons[0],
                  const SizedBox(height: AppSpacing.sm),
                  buttons[1],
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: buttons[0]),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: buttons[1]),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        if (accounts.isEmpty)
          _StatePanel(
            icon: LucideIcons.walletCards,
            title: context.l10n.bitcoinAccountsEmptyTitle,
            message: context.l10n.bitcoinAccountsEmptyMessage,
            actionLabel: context.l10n.bitcoinAccountsCreateColdWallet,
            onAction: () => _openColdWalletFlow(context),
          )
        else ...[
          _SectionTitle(context.l10n.bitcoinAccountsKeroseneCardSection),
          if (internal.isEmpty)
            _MutedPanel(text: context.l10n.bitcoinAccountsNoKeroseneCard)
          else
            for (final account in internal)
              _BitcoinAccountCard(
                account: account,
                onReceive: () => _showReceiveSheet(context, account),
              ),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(context.l10n.bitcoinAccountsColdWalletSection),
          if (watchOnly.isEmpty)
            _MutedPanel(text: context.l10n.bitcoinAccountsNoColdWallet)
          else
            for (final account in watchOnly)
              _BitcoinAccountCard(account: account),
        ],
      ],
    );
  }

  void _openColdWalletFlow(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _ColdWalletCreationScreen(),
      ),
    );
  }
}

class _BitcoinAccountCard extends StatelessWidget {
  final BitcoinAccount account;
  final VoidCallback? onReceive;

  const _BitcoinAccountCard({required this.account, this.onReceive});

  @override
  Widget build(BuildContext context) {
    final isInternal = account.isInternal;
    final balance =
        isInternal ? account.balanceAvailableSats : account.observedBalanceSats;
    final note = isInternal
        ? context.l10n.bitcoinAccountsKeroseneCardNote
        : context.l10n.bitcoinAccountsColdWalletNote;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(16),
      decoration: monochromePanelDecoration(
        color: isInternal ? monoSurfaceAltColor : monoSurfaceColor,
        borderColor: monoBorderColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _Pill(
                      text: isInternal
                          ? context.l10n.bitcoinAccountsKeroseneCardBadge
                          : context.l10n.bitcoinAccountsColdWalletBadge,
                    ),
                    _Pill(text: _friendlyStatus(context, account.status)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                isInternal ? LucideIcons.creditCard : LucideIcons.eye,
                color: monoMutedTextColor,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            account.label.trim().isEmpty
                ? context.l10n.bitcoinAccountsUnnamedAccount
                : account.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: monoTextColor,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isInternal
                ? context.l10n.bitcoinAccountsAvailableBalance
                : context.l10n.bitcoinAccountsObservedBalance,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: monoMutedTextColor,
                  letterSpacing: 0,
                ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatSats(balance),
              maxLines: 1,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: monoTextColor,
                    fontFamily: AppTypography.numericFontFamily,
                    fontSize: context.responsive.compactFontSize(
                      tiny: 24,
                      compact: 26,
                      regular: 28,
                    ),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            note,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: monoMutedTextColor,
                  height: 1.35,
                ),
          ),
          if (isInternal &&
              (account.balancePendingSats > 0 ||
                  account.balanceLockedSats > 0 ||
                  account.balanceAutoHoldSats > 0)) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (account.balancePendingSats > 0)
                  _MiniMetric(
                    context.l10n.bitcoinAccountsPendingBalance,
                    account.balancePendingSats,
                  ),
                if (account.balanceLockedSats > 0)
                  _MiniMetric(
                    context.l10n.bitcoinAccountsReservedBalance,
                    account.balanceLockedSats,
                  ),
                if (account.balanceAutoHoldSats > 0)
                  _MiniMetric(
                    context.l10n.bitcoinAccountsReviewBalance,
                    account.balanceAutoHoldSats,
                  ),
              ],
            ),
          ],
          if (onReceive != null) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: monochromeFilledButtonStyle(),
                onPressed: onReceive,
                icon: const Icon(LucideIcons.qrCode, size: 18),
                label: Text(context.l10n.bitcoinAccountsReceiveBtc),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final int sats;

  const _MiniMetric(this.label, this.sats);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: monoSurfaceRaisedColor,
        border: Border.all(color: monoBorderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          '$label · ${_formatSats(sats)}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: monoMutedTextColor,
                letterSpacing: 0,
              ),
        ),
      ),
    );
  }
}

class _ColdWalletCreationScreen extends ConsumerStatefulWidget {
  const _ColdWalletCreationScreen();

  @override
  ConsumerState<_ColdWalletCreationScreen> createState() =>
      _ColdWalletCreationScreenState();
}

class _ColdWalletCreationScreenState
    extends ConsumerState<_ColdWalletCreationScreen> {
  final TextEditingController _labelController = TextEditingController(
    text: 'Cold Wallet',
  );
  final TextEditingController _extraWordController = TextEditingController();
  final List<TextEditingController> _verificationControllers = [];
  final _deriver = const ColdWalletPublicMaterialDeriver();

  _ColdWalletLevel _level = _ColdWalletLevel.recommended;
  _ColdWalletStep _step = _ColdWalletStep.prepare;
  ColdWalletPublicMaterial? _publicMaterial;
  List<int> _verificationIndexes = const [];
  String _mnemonic = '';
  bool _paperReady = false;
  bool _privatePlace = false;
  bool _offlineReady = false;
  bool _noPhotos = false;
  bool _showWords = false;
  bool _busy = false;

  bool get _canGenerate =>
      _labelController.text.trim().isNotEmpty &&
      _paperReady &&
      _privatePlace &&
      _offlineReady &&
      _noPhotos;

  List<String> get _words =>
      _mnemonic.trim().isEmpty ? const [] : _mnemonic.split(' ');

  @override
  void dispose() {
    _labelController.dispose();
    _extraWordController.dispose();
    for (final controller in _verificationControllers) {
      controller.dispose();
    }
    _mnemonic = '';
    super.dispose();
  }

  void _generateColdWallet() {
    if (!_canGenerate) {
      return;
    }
    final strength = _level.wordCount == 12 ? 128 : 256;
    final mnemonic = bip39.generateMnemonic(strength: strength);
    final publicMaterial = _deriver.derive(
      mnemonic: mnemonic,
      extraWord: _level.usesExtraWord ? _extraWordController.text : '',
    );
    setState(() {
      _mnemonic = mnemonic;
      _publicMaterial = publicMaterial;
      _showWords = false;
      _step = _ColdWalletStep.backup;
    });
    HapticFeedback.mediumImpact();
  }

  void _startVerification() {
    final words = _words;
    final indexes = <int>{
      0,
      words.length ~/ 2,
      max(0, words.length - 1),
    }.toList()
      ..sort();
    for (final controller in _verificationControllers) {
      controller.dispose();
    }
    _verificationControllers
      ..clear()
      ..addAll(List.generate(indexes.length, (_) => TextEditingController()));
    setState(() {
      _verificationIndexes = indexes;
      _step = _ColdWalletStep.verify;
      _showWords = false;
    });
  }

  bool _verificationMatches() {
    final words = _words;
    if (words.isEmpty ||
        _verificationControllers.length != _verificationIndexes.length) {
      return false;
    }
    for (var index = 0; index < _verificationIndexes.length; index++) {
      final wordIndex = _verificationIndexes[index];
      final typed = _verificationControllers[index].text.trim().toLowerCase();
      if (typed != words[wordIndex].toLowerCase()) {
        return false;
      }
    }
    return true;
  }

  Future<void> _importWatchOnly() async {
    final material = _publicMaterial;
    if (material == null || !_verificationMatches()) {
      AppNotice.showWarning(
        context,
        title: context.l10n.coldWalletVerifyFailedTitle,
        message: context.l10n.coldWalletVerifyFailedMessage,
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final notifier = ref.read(bitcoinAccountsProvider.notifier);
      await notifier.importColdWallet(
        label: _labelController.text.trim(),
        xpub: material.xpub,
        fingerprint: material.fingerprint,
        derivationPath: material.derivationPath,
        scriptPolicy: material.scriptPolicy,
      );
      final state = ref.read(bitcoinAccountsProvider);
      if (state.hasError) {
        throw state.error ?? Exception('Import failed');
      }
      _mnemonic = '';
      _extraWordController.clear();
      if (!mounted) return;
      AppNotice.showSuccess(
        context,
        title: context.l10n.coldWalletImportedTitle,
        message: context.l10n.coldWalletImportedMessage,
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      AppNotice.showError(
        context,
        title: context.l10n.coldWalletImportErrorTitle,
        message: context.l10n.coldWalletImportErrorMessage,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Scaffold(
      backgroundColor: monoBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                responsive.horizontalPadding,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _busy ? null : () => Navigator.maybePop(context),
                    icon: const Icon(
                      LucideIcons.chevronLeft,
                      color: monoTextColor,
                      size: 18,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      context.l10n.coldWalletCreateTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: monoTextColor,
                            fontSize: responsive.compactFontSize(
                              tiny: 19,
                              compact: 21,
                              regular: 22,
                            ),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  responsive.horizontalPadding,
                  AppSpacing.sm,
                  responsive.horizontalPadding,
                  AppSpacing.lg,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: responsive.mobileContentMaxWidth,
                    ),
                    child: switch (_step) {
                      _ColdWalletStep.prepare => _buildPrepare(),
                      _ColdWalletStep.backup => _buildBackup(),
                      _ColdWalletStep.verify => _buildVerify(),
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrepare() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MutedPanel(text: context.l10n.coldWalletCreateSubtitle),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _labelController,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: monoTextColor),
          decoration: monochromeInputDecoration(
            label: context.l10n.coldWalletNameLabel,
            hintText: context.l10n.coldWalletNameHint,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionTitle(context.l10n.coldWalletSecurityLevelTitle),
        for (final level in _ColdWalletLevel.values)
          _ColdWalletLevelTile(
            level: level,
            selected: _level == level,
            onTap: () => setState(() => _level = level),
          ),
        if (_level.usesExtraWord) ...[
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _extraWordController,
            obscureText: true,
            style: const TextStyle(color: monoTextColor),
            decoration: monochromeInputDecoration(
              label: context.l10n.coldWalletExtraWordLabel,
              hintText: context.l10n.coldWalletExtraWordHint,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _MutedPanel(text: context.l10n.coldWalletExtraWordWarning),
        ],
        const SizedBox(height: AppSpacing.lg),
        _SectionTitle(context.l10n.coldWalletChecklistTitle),
        _ChecklistTile(
          value: _paperReady,
          text: context.l10n.coldWalletChecklistPaper,
          onChanged: (value) => setState(() => _paperReady = value),
        ),
        _ChecklistTile(
          value: _privatePlace,
          text: context.l10n.coldWalletChecklistPrivate,
          onChanged: (value) => setState(() => _privatePlace = value),
        ),
        _ChecklistTile(
          value: _offlineReady,
          text: context.l10n.coldWalletChecklistOffline,
          onChanged: (value) => setState(() => _offlineReady = value),
        ),
        _ChecklistTile(
          value: _noPhotos,
          text: context.l10n.coldWalletChecklistNoPhotos,
          onChanged: (value) => setState(() => _noPhotos = value),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          style: monochromeFilledButtonStyle(),
          onPressed: _canGenerate ? _generateColdWallet : null,
          icon: const Icon(LucideIcons.keyRound, size: 18),
          label: Text(context.l10n.coldWalletGenerateAction),
        ),
      ],
    );
  }

  Widget _buildBackup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MutedPanel(text: context.l10n.coldWalletBackupSubtitle),
        const SizedBox(height: AppSpacing.lg),
        DecoratedBox(
          decoration: monochromePanelDecoration(color: monoSurfaceAltColor),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _IconFrame(icon: LucideIcons.eyeOff),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        context.l10n.coldWalletBackupTitle,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: monoTextColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (_showWords)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _words
                        .asMap()
                        .entries
                        .map(
                          (entry) => _SeedWordBadge(
                            index: entry.key + 1,
                            word: entry.value,
                          ),
                        )
                        .toList(),
                  )
                else
                  _MutedPanel(text: context.l10n.coldWalletWordsHidden),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  style: monochromeOutlinedButtonStyle(),
                  onPressed: () => setState(() => _showWords = !_showWords),
                  icon: Icon(_showWords ? LucideIcons.eyeOff : LucideIcons.eye),
                  label: Text(
                    _showWords
                        ? context.l10n.coldWalletHideWords
                        : context.l10n.coldWalletShowWords,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          style: monochromeFilledButtonStyle(),
          onPressed: _showWords ? _startVerification : null,
          icon: const Icon(LucideIcons.checkCircle, size: 18),
          label: Text(context.l10n.coldWalletBackupDoneAction),
        ),
      ],
    );
  }

  Widget _buildVerify() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MutedPanel(text: context.l10n.coldWalletVerifySubtitle),
        const SizedBox(height: AppSpacing.lg),
        for (var index = 0; index < _verificationIndexes.length; index++) ...[
          TextField(
            controller: _verificationControllers[index],
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: monoTextColor),
            decoration: monochromeInputDecoration(
              label: context.l10n.coldWalletVerifyWordLabel(
                _verificationIndexes[index] + 1,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        FilledButton.icon(
          style: monochromeFilledButtonStyle(),
          onPressed: _busy || !_verificationMatches() ? null : _importWatchOnly,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.shieldCheck, size: 18),
          label: Text(
            _busy
                ? context.l10n.coldWalletImportingAction
                : context.l10n.coldWalletImportAction,
          ),
        ),
      ],
    );
  }
}

class _ColdWalletLevelTile extends StatelessWidget {
  final _ColdWalletLevel level;
  final bool selected;
  final VoidCallback onTap;

  const _ColdWalletLevelTile({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? monoSurfaceRaisedColor : monoSurfaceColor,
            border: Border.all(
              color: selected ? monoTextColor : monoBorderColor,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected ? LucideIcons.checkCircle : LucideIcons.circle,
                color: selected ? monoTextColor : monoMutedTextColor,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.title(context),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: monoTextColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      level.body(context),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: monoMutedTextColor,
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  final bool value;
  final String text;
  final ValueChanged<bool> onChanged;

  const _ChecklistTile({
    required this.value,
    required this.text,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (next) => onChanged(next ?? false),
      activeColor: monoTextColor,
      checkColor: Colors.black,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      title: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: monoMutedTextColor,
              height: 1.35,
            ),
      ),
    );
  }
}

class _SeedWordBadge extends StatelessWidget {
  final int index;
  final String word;

  const _SeedWordBadge({required this.index, required this.word});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: monoBackgroundColor,
        border: Border.all(color: monoBorderStrongColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              index.toString().padLeft(2, '0'),
              style: AppTypography.technicalMono(
                textStyle: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: monoFaintTextColor),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              word,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: monoTextColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showCreateInternalCard(BuildContext context, WidgetRef ref) {
  final controller = TextEditingController(text: 'Kerosene BTC Card');
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: monoSurfaceColor,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: monoRadius),
    builder: (context) => _SheetScaffold(
      title: context.l10n.bitcoinAccountsCreateCardTitle,
      child: Column(
        children: [
          TextField(
            controller: controller,
            style: const TextStyle(color: monoTextColor),
            decoration: monochromeInputDecoration(
              label: context.l10n.bitcoinAccountsCardNameLabel,
              hintText: context.l10n.bitcoinAccountsCardNameHint,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _MutedPanel(text: context.l10n.bitcoinAccountsCreateCardNotice),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: monochromeFilledButtonStyle(),
              onPressed: () async {
                await ref
                    .read(bitcoinAccountsProvider.notifier)
                    .createInternalCard(controller.text.trim());
                if (!context.mounted) return;
                final state = ref.read(bitcoinAccountsProvider);
                if (state.hasError) {
                  AppNotice.showError(
                    context,
                    title: context.l10n.bitcoinAccountsCreateCardErrorTitle,
                    message: context.l10n.bitcoinAccountsCreateCardErrorMessage,
                  );
                  return;
                }
                Navigator.pop(context);
              },
              child: Text(context.l10n.bitcoinAccountsCreateCardAction),
            ),
          ),
        ],
      ),
    ),
  );
}

void _showReceiveSheet(BuildContext context, BitcoinAccount account) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: monoSurfaceColor,
    shape: const RoundedRectangleBorder(borderRadius: monoRadius),
    builder: (context) => _ReceiveSheet(account: account),
  );
}

class _ReceiveSheet extends ConsumerStatefulWidget {
  final BitcoinAccount account;

  const _ReceiveSheet({required this.account});

  @override
  ConsumerState<_ReceiveSheet> createState() => _ReceiveSheetState();
}

class _ReceiveSheetState extends ConsumerState<_ReceiveSheet> {
  final TextEditingController _amount = TextEditingController();
  String _expiry = '1H';
  bool _oneTime = true;
  bool _busy = false;
  ReceivingRequestView? _result;
  Timer? _poller;

  @override
  void dispose() {
    _poller?.cancel();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: context.l10n.bitcoinReceiveTitle,
      child: _result == null ? _buildForm(context) : _buildLiveRequest(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _amount,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: monoTextColor),
          decoration: monochromeInputDecoration(
            label: context.l10n.bitcoinReceiveAmountOptional,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in const ['15M', '1H', '24H', 'PERMANENT'])
              ChoiceChip(
                label: Text(_expiryLabel(context, option)),
                selected: _expiry == option,
                onSelected: (_) => setState(() => _expiry = option),
              ),
          ],
        ),
        SwitchListTile.adaptive(
          value: _oneTime,
          onChanged: (value) => setState(() => _oneTime = value),
          contentPadding: EdgeInsets.zero,
          title: Text(
            context.l10n.bitcoinReceiveOneTime,
            style: const TextStyle(color: monoTextColor),
          ),
          subtitle: Text(
            context.l10n.bitcoinReceiveOneTimeSubtitle,
            style: const TextStyle(color: monoMutedTextColor),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: monochromeFilledButtonStyle(),
            onPressed: _busy ? null : _createReceiveRequest,
            icon: const Icon(LucideIcons.qrCode, size: 18),
            label: Text(
              _busy
                  ? context.l10n.bitcoinReceiveGenerating
                  : context.l10n.bitcoinReceiveGenerateAddress,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveRequest(BuildContext context) {
    final result = _result!;
    final qrSize =
        context.responsive.clampWidth(210).clamp(168.0, 210.0).toDouble();

    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: monoTextColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: QrImageView(
              data: result.bip21.trim().isNotEmpty
                  ? result.bip21
                  : 'bitcoin:${result.address}',
              version: QrVersions.auto,
              size: qrSize,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        BitcoinAddressBlocks(
          address: result.address,
          style: AppTypography.technicalMono(
            textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: monoTextColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pill(text: _receiveStatusLabel(context, result.status)),
            if (result.amountSats != null)
              _Pill(text: _formatSats(result.amountSats!)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _MutedPanel(text: _receiveStatusMessage(context, result)),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final shouldStack = constraints.maxWidth < 360;
            final buttons = [
              OutlinedButton.icon(
                style: monochromeOutlinedButtonStyle(),
                onPressed: _busy ? null : _copyAddress,
                icon: const Icon(LucideIcons.copy, size: 18),
                label: Text(context.l10n.copyAddress),
              ),
              OutlinedButton.icon(
                style: monochromeOutlinedButtonStyle(),
                onPressed: _busy ? null : () => _refreshStatus(silent: false),
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                label: Text(context.l10n.bitcoinReceiveRefresh),
              ),
            ];

            if (shouldStack) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buttons[0],
                  const SizedBox(height: AppSpacing.sm),
                  buttons[1],
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: buttons[0]),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: buttons[1]),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _createReceiveRequest() async {
    setState(() => _busy = true);
    try {
      final parsed = int.tryParse(_amount.text.trim());
      final service = ref.read(bitcoinAccountsServiceProvider);
      final created = await service.createReceiveRequest(
        accountId: widget.account.id,
        amountSats: parsed != null && parsed > 0 ? parsed : null,
        expiry: _expiry,
        oneTime: _oneTime,
      );
      if (!mounted) return;
      setState(() => _result = created);
      _startPolling();
    } catch (_) {
      if (!mounted) return;
      AppNotice.showError(
        context,
        title: context.l10n.bitcoinReceiveCreateErrorTitle,
        message: context.l10n.bitcoinReceiveCreateErrorMessage,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshStatus({required bool silent}) async {
    final current = _result;
    if (current == null || _busy) return;
    if (!silent) setState(() => _busy = true);
    try {
      final service = ref.read(bitcoinAccountsServiceProvider);
      final updated = await service.getReceiveStatus(current.id);
      if (!mounted) return;
      setState(() => _result = updated);
      if (_isTerminal(updated.status)) {
        _poller?.cancel();
      }
    } catch (_) {
      if (!silent && mounted) {
        AppNotice.showError(
          context,
          title: context.l10n.bitcoinReceiveStatusErrorTitle,
          message: context.l10n.bitcoinReceiveStatusErrorMessage,
        );
      }
    } finally {
      if (!silent && mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyAddress() async {
    final result = _result;
    if (result == null) return;
    await Clipboard.setData(ClipboardData(text: result.address));
    if (!mounted) return;
    AppNotice.showSuccess(
      context,
      title: context.l10n.bitcoinReceiveCopiedTitle,
      message: context.l10n.bitcoinReceiveCopiedMessage,
    );
  }

  void _startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshStatus(silent: true),
    );
  }

  bool _isTerminal(String status) =>
      status == 'PAID' || status == 'HIDDEN' || status == 'FAILED_SAFE';
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: monochromeOutlinedButtonStyle(minHeight: 54),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _SheetScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const _SheetScaffold({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          responsive.horizontalPadding,
          18,
          responsive.horizontalPadding,
          MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: responsive.sheetMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: monoTextColor,
                        fontSize: responsive.compactFontSize(
                          tiny: 18,
                          compact: 19,
                          regular: 20,
                        ),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: monoTextColor,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;

  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: monoSurfaceRaisedColor,
        border: Border.all(color: monoBorderStrongColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: monoMutedTextColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
        ),
      ),
    );
  }
}

class _MutedPanel extends StatelessWidget {
  final String text;

  const _MutedPanel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: monochromePanelDecoration(
        color: monoSurfaceAltColor,
        showShadow: false,
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: monoMutedTextColor, height: 1.4),
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _StatePanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: monochromePanelDecoration(),
      child: Column(
        children: [
          _IconFrame(icon: icon),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: monoTextColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: monoMutedTextColor,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            style: monochromeFilledButtonStyle(),
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _IconFrame extends StatelessWidget {
  final IconData icon;

  const _IconFrame({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: monoSurfaceRaisedColor,
        border: Border.all(color: monoBorderStrongColor),
      ),
      child: Icon(icon, color: monoTextColor, size: 19),
    );
  }
}

class _AccountsSkeleton extends StatelessWidget {
  const _AccountsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < 3; index++)
          Container(
            height: 150,
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: monochromePanelDecoration(),
          ),
      ],
    );
  }
}

enum _ColdWalletStep { prepare, backup, verify }

enum _ColdWalletLevel {
  essential,
  recommended,
  maximum;

  int get wordCount => this == essential ? 12 : 24;
  bool get usesExtraWord => this == maximum;

  String title(BuildContext context) {
    return switch (this) {
      essential => context.l10n.coldWalletLevelEssentialTitle,
      recommended => context.l10n.coldWalletLevelRecommendedTitle,
      maximum => context.l10n.coldWalletLevelMaximumTitle,
    };
  }

  String body(BuildContext context) {
    return switch (this) {
      essential => context.l10n.coldWalletLevelEssentialBody,
      recommended => context.l10n.coldWalletLevelRecommendedBody,
      maximum => context.l10n.coldWalletLevelMaximumBody,
    };
  }
}

String _friendlyStatus(BuildContext context, String status) {
  return switch (status.trim().toUpperCase()) {
    'ACTIVE' => context.l10n.bitcoinAccountsStatusActive,
    'PENDING' => context.l10n.bitcoinAccountsStatusPending,
    'DISABLED' => context.l10n.bitcoinAccountsStatusDisabled,
    _ => context.l10n.bitcoinAccountsStatusReady,
  };
}

String _expiryLabel(BuildContext context, String value) {
  return switch (value) {
    '15M' => context.l10n.receive15Min,
    '1H' => context.l10n.receive1Hour,
    '24H' => context.l10n.receive24Hours,
    'PERMANENT' => context.l10n.receiveNoExpiration,
    _ => value,
  };
}

String _receiveStatusLabel(BuildContext context, String status) {
  return switch (status) {
    'ACTIVE' => context.l10n.bitcoinReceiveStatusActive,
    'MEMPOOL_SEEN' => context.l10n.bitcoinReceiveStatusDetected,
    'CONFIRMING' => context.l10n.bitcoinReceiveStatusConfirming,
    'PAID' => context.l10n.bitcoinReceiveStatusPaid,
    'EXPIRED' => context.l10n.bitcoinReceiveStatusExpired,
    'EXPIRED_RECEIVED' => context.l10n.bitcoinReceiveStatusLate,
    'AUTO_RESOLUTION_PENDING' => context.l10n.bitcoinReceiveStatusReview,
    'USER_ACTION_REQUIRED' => context.l10n.bitcoinReceiveStatusAction,
    'FAILED_SAFE' => context.l10n.bitcoinReceiveStatusProtected,
    _ => context.l10n.bitcoinReceiveStatusWaiting,
  };
}

String _receiveStatusMessage(
  BuildContext context,
  ReceivingRequestView request,
) {
  return switch (request.status) {
    'ACTIVE' => context.l10n.bitcoinReceiveMessageActive,
    'MEMPOOL_SEEN' => context.l10n.bitcoinReceiveMessageDetected,
    'CONFIRMING' => context.l10n.bitcoinReceiveMessageConfirming,
    'PAID' => context.l10n.bitcoinReceiveMessagePaid,
    'EXPIRED' => context.l10n.bitcoinReceiveMessageExpired,
    'EXPIRED_RECEIVED' => context.l10n.bitcoinReceiveMessageLate,
    'AUTO_RESOLUTION_PENDING' => context.l10n.bitcoinReceiveMessageReview,
    'USER_ACTION_REQUIRED' => context.l10n.bitcoinReceiveMessageAction,
    'FAILED_SAFE' => context.l10n.bitcoinReceiveMessageProtected,
    _ => context.l10n.bitcoinReceiveMessageWaiting,
  };
}

String _formatSats(int sats) {
  final btc = sats / 100000000;
  return '${btc.toStringAsFixed(8)} BTC';
}
