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
  final TextEditingController _walletNameController = TextEditingController();
  bool _busy = false;
  int? _selectedCustodyIndex;
  late final Set<BitcoinAccountCustody> _initialUnavailableCustodies;

  @override
  void initState() {
    super.initState();
    _initialUnavailableCustodies = _activeCustodies(
      ref.read(bitcoinAccountsProvider).asData?.value ??
          const <BitcoinAccount>[],
    );
  }

  @override
  void dispose() {
    _walletNameController.dispose();
    super.dispose();
  }

  void _onCustodyContinue() {
    if (_selectedCustodyIndex == null) {
      AppNotice.showWarning(
        context,
        title: 'Selecione a custódia',
        message: 'Escolha como essa carteira será custodiada antes de seguir.',
      );
      return;
    }
    HapticFeedback.selectionClick();
    _continueFromCustody();
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
    if (!_availableCustodyOptions
        .any((option) => option.index == _selectedCustodyIndex)) {
      AppNotice.showWarning(
        context,
        title: 'Custódia indisponível',
        message: 'Essa custódia já possui uma carteira ativa.',
      );
      return;
    }
    setState(() => _step = _InternalAccountStep.details);
  }

  void _continueFromDetails() {
    if (_busy) return;
    if (_walletNameController.text.trim().isEmpty) {
      AppNotice.showWarning(
        context,
        title: context.tr.createWalletNameRequired,
        message: 'Digite o nome que essa carteira deve receber.',
      );
      return;
    }
    unawaited(_createInternalAccount());
  }

  Future<void> _createInternalAccount() async {
    if (_busy) return;

    setState(() => _busy = true);
    try {
      await ref.read(bitcoinAccountsProvider.notifier).createWallet(
            label: _walletNameController.text.trim(),
            custody: _selectedCustody,
          );
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      AppNotice.showSuccess(
        context,
        title: context.tr.bitcoinAccountsCreateCardTitle,
        message: 'Carteira criada com sucesso.',
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
                _step == _InternalAccountStep.details ? 14 : 24,
                16,
                _step == _InternalAccountStep.details ? 2 : 8,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: _goBack,
                  icon: Icon(
                    KeroseneIcons.back,
                    color: colors.text,
                    size: 24,
                  ),
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: KeroseneMotion.short,
                child: switch (_step) {
                  _InternalAccountStep.custody => const SizedBox.shrink(),
                  _InternalAccountStep.details => _buildDetailsStep(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustodySelectionScaffold(_BitcoinAccountsColors colors) {
    final options = _availableCustodyOptions;

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
                        if (options.isEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
                            child: _MutedPanel(
                              text:
                                  'As carteiras disponíveis já foram criadas.',
                            ),
                          )
                        else
                          for (final option in options)
                            _CustodySelectionTile(
                              selected: _selectedCustodyIndex == option.index,
                              icon: option.icon,
                              title: option.title,
                              subtitle: option.subtitle,
                              onTap: () => setState(
                                  () => _selectedCustodyIndex = option.index),
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
                onPressed: options.isEmpty ? null : _onCustodyContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BitcoinAccountCustody get _selectedCustody {
    return switch (_selectedCustodyIndex) {
      1 => BitcoinAccountCustody.custodialOnchain,
      _ => BitcoinAccountCustody.custodialOnchain,
    };
  }

  List<_CustodyCreationOption> get _availableCustodyOptions {
    final currentAccounts = ref.watch(bitcoinAccountsProvider).asData?.value;
    final unavailableCustodies = currentAccounts == null
        ? _initialUnavailableCustodies
        : {
            ..._initialUnavailableCustodies,
            ..._activeCustodies(currentAccounts),
          };

    return [
      if (!unavailableCustodies
          .contains(BitcoinAccountCustody.custodialOnchain))
        _CustodyCreationOption(
          index: 1,
          icon: KeroseneIcons.shield,
          title: context.tr.bitcoinAccountsCustodyOnchainTitle,
          subtitle: context.tr.bitcoinAccountsCustodyOnchainSubtitle,
        ),
    ];
  }

  String get _selectedCustodyLabel {
    return switch (_selectedCustodyIndex) {
      1 => context.tr.bitcoinAccountsCustodyOnchainTitle,
      _ => context.tr.bitcoinAccountsCustodyOnchainTitle,
    };
  }

  Set<BitcoinAccountCustody> _activeCustodies(List<BitcoinAccount> accounts) {
    final custodies = <BitcoinAccountCustody>{};
    for (final account in accounts) {
      if (!account.isActive) {
        continue;
      }
      if (account.isInternal && !account.isCustodialOnchain) {
        custodies.add(BitcoinAccountCustody.internal);
      } else if (account.isCustodialOnchain) {
        custodies.add(BitcoinAccountCustody.custodialOnchain);
      } else if (account.isWatchOnly) {
        custodies.add(BitcoinAccountCustody.watchOnly);
      }
    }
    return custodies;
  }

  Widget _buildDetailsStep() {
    final colors = _BitcoinAccountsColors.of(context);
    final title = 'Como essa carteira deve se chamar?';
    final confirmationMessage =
        'Você escolheu $_selectedCustodyLabel. A carteira só será criada depois de confirmar este nome.';
    final createButtonLabel = _busy ? 'Criando...' : 'Criar carteira';

    return _CreationStepFrame(
      key: const ValueKey('details'),
      footer: _CreationPrimaryButton(
        label: createButtonLabel,
        onPressed: _busy ? null : _continueFromDetails,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CreationTitle(
            title,
          ),
          const SizedBox(height: 16),
          Text(
            confirmationMessage,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              color: colors.mutedText,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.45,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _walletNameController,
            enabled: !_busy,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _continueFromDetails(),
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              color: colors.text,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
            decoration: InputDecoration(
              labelText: 'Nome da carteira',
              hintText: context.tr.createWalletNameHint,
              filled: true,
              fillColor: colors.surfaceAlt,
              labelStyle: TextStyle(
                fontFamily: AppTypography.fontFamily,
                color: colors.mutedText,
                fontSize: 14,
                letterSpacing: 0,
              ),
              hintStyle: TextStyle(
                fontFamily: AppTypography.fontFamily,
                color: colors.faintText,
                fontSize: 15,
                letterSpacing: 0,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: colors.controlRadius,
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: colors.controlRadius,
                borderSide: BorderSide(color: colors.text),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: colors.controlRadius,
                borderSide: BorderSide(color: colors.border),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
            ),
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
      style: AppTypography.newsreader(
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
            disabledBackgroundColor: AppColors.hexFF2A2A2A,
            disabledForegroundColor: AppColors.hexFF777777,
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
                    KeroseneIcons.back,
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
                              style: AppTypography.newsreader(
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

enum _InternalAccountStep { custody, details }

class _CustodyCreationOption {
  final int index;
  final IconData icon;
  final String title;
  final String subtitle;

  const _CustodyCreationOption({
    required this.index,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

String _friendlyStatus(BuildContext context, String status) {
  return switch (status.trim().toUpperCase()) {
    'ACTIVE' => context.tr.bitcoinAccountsStatusActive,
    'PENDING' => context.tr.bitcoinAccountsStatusPending,
    'DISABLED' => context.tr.bitcoinAccountsStatusDisabled,
    _ => context.tr.bitcoinAccountsStatusReady,
  };
}
