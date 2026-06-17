part of '../bitcoin_accounts_screen.dart';

class _InternalAccountCreationFlow extends ConsumerStatefulWidget {
  const _InternalAccountCreationFlow();

  @override
  ConsumerState<_InternalAccountCreationFlow> createState() =>
      _InternalAccountCreationFlowState();
}

class _InternalAccountCreationFlowState
    extends ConsumerState<_InternalAccountCreationFlow> {
  _InternalAccountStep _step = _InternalAccountStep.custody;
  _WalletPurpose? _purpose;
  bool _busy = false;
  int _selectedCustodyIndex = 1;

  void _onCustodyContinue() {
    HapticFeedback.selectionClick();
    if (_selectedCustodyIndex == 2) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const ColdWalletCreationScreen(),
        ),
      );
    } else {
      _continueFromCustody();
    }
  }

  void _goBack() {
    if (_busy) return;
    if (_step == _InternalAccountStep.custody) {
      Navigator.maybePop(context);
      return;
    }
    setState(() {
      _step = _InternalAccountStep.custody;
    });
  }

  void _continueFromCustody() {
    if (_busy) return;
    setState(() => _step = _InternalAccountStep.purpose);
  }

  void _continueFromPurpose() {
    if (_busy) return;
    if (_purpose == null) {
      AppNotice.showWarning(
        context,
        title: 'Selecione a finalidade',
        message: 'Escolha para que essa conta interna será usada.',
      );
      return;
    }
    unawaited(_createInternalAccount());
  }

  Future<void> _createInternalAccount() async {
    if (_busy) return;

    setState(() => _busy = true);
    try {
      await ref.read(bitcoinAccountsProvider.notifier).createInternalCard(
            label: _purpose?.label ?? 'Kerosene BTC Card',
          );
      final state = ref.read(bitcoinAccountsProvider);
      if (state.hasError) {
        throw state.error ?? Exception('Create internal account failed');
      }
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      AppNotice.showSuccess(
        context,
        title: context.tr.bitcoinAccountsCreateCardTitle,
        message: 'Carteira interna criada com sucesso.',
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      AppNotice.showError(
        context,
        title: context.tr.bitcoinAccountsCreateCardErrorTitle,
        message: context.tr.bitcoinAccountsCreateCardErrorMessage,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _BitcoinAccountsColors.of(context);

    if (_step == _InternalAccountStep.custody) {
      return _buildCustodySelectionScaffold(colors);
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: colors.isLight ? colors.background : Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                _step == _InternalAccountStep.purpose ? 14 : 24,
                16,
                _step == _InternalAccountStep.purpose ? 2 : 8,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: _goBack,
                  icon: Icon(
                    LucideIcons.arrowLeft,
                    color: colors.text,
                    size: 24,
                  ),
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: switch (_step) {
                  _InternalAccountStep.custody => const SizedBox.shrink(),
                  _InternalAccountStep.purpose => _buildPurposeStep(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustodySelectionScaffold(_BitcoinAccountsColors colors) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: colors.isLight ? colors.background : Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _CustodySelectionTopBar(
                  title: context.tr.createWalletTitle,
                  colors: colors,
                  onBack: _goBack,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 88),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CustodySelectionTile(
                          selected: _selectedCustodyIndex == 0,
                          icon: LucideIcons.walletCards,
                          title: context.tr.bitcoinAccountsCustodyInternalTitle,
                          subtitle:
                              context.tr.bitcoinAccountsCustodyInternalSubtitle,
                          onTap: () =>
                              setState(() => _selectedCustodyIndex = 0),
                        ),
                        _CustodySelectionTile(
                          selected: _selectedCustodyIndex == 1,
                          icon: LucideIcons.shield,
                          title: context.tr.bitcoinAccountsCustodyOnchainTitle,
                          subtitle:
                              context.tr.bitcoinAccountsCustodyOnchainSubtitle,
                          onTap: () =>
                              setState(() => _selectedCustodyIndex = 1),
                        ),
                        _CustodySelectionTile(
                          selected: _selectedCustodyIndex == 2,
                          icon: LucideIcons.eye,
                          title:
                              context.tr.bitcoinAccountsCustodyWatchOnlyTitle,
                          subtitle: context
                              .tr.bitcoinAccountsCustodyWatchOnlySubtitle,
                          onTap: () =>
                              setState(() => _selectedCustodyIndex = 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: _CreationPrimaryButton(
                label: 'Continuar',
                onPressed: _onCustodyContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurposeStep() {
    return _CreationStepFrame(
      key: const ValueKey('purpose'),
      footer: _CreationPrimaryButton(
        label: _busy ? 'Gerando...' : 'Gerar Carteira',
        onPressed: _busy ? null : _continueFromPurpose,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CreationTitle(
            'Para Que Finalidade Deseja Derivar essa Carteira?',
          ),
          const SizedBox(height: 40),
          for (final purpose in _walletPurposeOptions)
            _PurposeTile(
              purpose: purpose,
              selected: _purpose == purpose,
              onTap: () => setState(() => _purpose = purpose),
            ),
        ],
      ),
    );
  }
}

class _CreationStepFrame extends StatelessWidget {
  final Widget child;
  final Widget footer;

  const _CreationStepFrame({
    super.key,
    required this.child,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: child,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.viewInsetsOf(context).bottom > 0 ? 20 : 40,
          ),
          child: footer,
        ),
      ],
    );
  }
}

class _CreationTitle extends StatelessWidget {
  final String text;

  const _CreationTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = _BitcoinAccountsColors.of(context);

    return Text(
      text,
      style: GoogleFonts.ibmPlexSerif(
        color: colors.text,
        fontSize: 40,
        fontWeight: FontWeight.w500,
        height: 1.05,
        letterSpacing: 0,
      ),
    );
  }
}

class _CreationPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _CreationPrimaryButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _BitcoinAccountsColors.of(context);
    final style = colors.isLight
        ? colors.filledButtonStyle(minHeight: 56)
        : FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            disabledBackgroundColor: const Color(0xFF2A2A2A),
            disabledForegroundColor: const Color(0xFF777777),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: 0,
            ),
          );

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        style: style,
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

class _CustodySelectionTopBar extends StatelessWidget {
  final String title;
  final _BitcoinAccountsColors colors;
  final VoidCallback onBack;

  const _CustodySelectionTopBar({
    required this.title,
    required this.colors,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.isLight ? colors.background : Colors.black,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  visualDensity: VisualDensity.compact,
                  onPressed: onBack,
                  icon: Icon(
                    LucideIcons.arrowLeft,
                    color: colors.text,
                    size: 24,
                  ),
                ),
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  color: colors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: 0,
                ),
              ),
              const Align(
                alignment: Alignment.centerRight,
                child: SizedBox(width: 48, height: 48),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustodySelectionTile extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CustodySelectionTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _BitcoinAccountsColors.of(context);
    final background = selected ? Colors.white : colors.surfaceAlt;
    final foreground = selected ? Colors.black : colors.text;
    final secondary =
        selected ? Colors.black.withValues(alpha: 0.78) : colors.mutedText;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: background,
          child: InkWell(
            onTap: onTap,
            splashColor: foreground.withValues(alpha: 0.08),
            highlightColor: foreground.withValues(alpha: 0.04),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.border)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 190;
                  final iconSize = compact ? 36.0 : 48.0;
                  final titleSize = compact ? 20.0 : 24.0;
                  final verticalGap = compact ? 8.0 : 12.0;

                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: compact ? AppSpacing.md : AppSpacing.lg,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 390),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              color: secondary,
                              size: iconSize,
                            ),
                            SizedBox(height: verticalGap),
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.ibmPlexSerif(
                                color: foreground,
                                fontSize: titleSize,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              subtitle,
                              maxLines: compact ? 2 : 3,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                color: secondary,
                                fontSize: compact ? 13 : 14,
                                fontWeight: FontWeight.w400,
                                height: 1.35,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PurposeTile extends StatelessWidget {
  final _WalletPurpose purpose;
  final bool selected;
  final VoidCallback onTap;

  const _PurposeTile({
    required this.purpose,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _BitcoinAccountsColors.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: colors.divider),
            ),
          ),
          child: Row(
            children: [
              _CreationCircleIcon(icon: purpose.icon),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  purpose.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    color: colors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    height: 1,
                    letterSpacing: 0,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: selected ? colors.text : colors.surfaceRaised,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  selected ? LucideIcons.check : LucideIcons.chevronRight,
                  color: selected
                      ? colors.filledButtonForeground
                      : colors.mutedText,
                  size: selected ? 16 : 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreationCircleIcon extends StatelessWidget {
  final IconData icon;

  const _CreationCircleIcon({
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _BitcoinAccountsColors.of(context);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: colors.text, size: 20),
    );
  }
}

class _WalletPurpose {
  final String label;
  final IconData icon;

  const _WalletPurpose(this.label, this.icon);
}

const _walletPurposeOptions = [
  _WalletPurpose('Investimento', LucideIcons.trendingUp),
  _WalletPurpose('Dia a dia', LucideIcons.calendarDays),
  _WalletPurpose('Veiculo', LucideIcons.car),
  _WalletPurpose('Futuros gastos', LucideIcons.receipt),
];

enum _InternalAccountStep { custody, purpose }

String _friendlyStatus(BuildContext context, String status) {
  return switch (status.trim().toUpperCase()) {
    'ACTIVE' => context.tr.bitcoinAccountsStatusActive,
    'PENDING' => context.tr.bitcoinAccountsStatusPending,
    'DISABLED' => context.tr.bitcoinAccountsStatusDisabled,
    _ => context.tr.bitcoinAccountsStatusReady,
  };
}

void _showReceiveSheet(BuildContext context, BitcoinAccount account) {
  final colors = _BitcoinAccountsColors.of(context);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: colors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: colors.isLight
          ? const BorderRadius.vertical(top: Radius.circular(24))
          : monoRadius,
    ),
    builder: (context) => _ReceiveSheet(account: account),
  );
}

void _showCreatePsbtSheet(BuildContext context, BitcoinAccount account) {
  final colors = _BitcoinAccountsColors.of(context);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: colors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: colors.isLight
          ? const BorderRadius.vertical(top: Radius.circular(24))
          : monoRadius,
    ),
    builder: (context) => _CreatePsbtSheet(account: account),
  );
}

void _showSubmitPsbtSheet(
  BuildContext context,
  BitcoinAccount account,
  PsbtWorkflowView workflow,
) {
  final colors = _BitcoinAccountsColors.of(context);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: colors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: colors.isLight
          ? const BorderRadius.vertical(top: Radius.circular(24))
          : monoRadius,
    ),
    builder: (context) => _SubmitPsbtSheet(
      account: account,
      workflow: workflow,
    ),
  );
}
