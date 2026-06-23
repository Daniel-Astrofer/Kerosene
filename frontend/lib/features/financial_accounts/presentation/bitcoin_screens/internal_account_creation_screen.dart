// ignore_for_file: use_key_in_widget_constructors, unused_import, unused_element

import '../bitcoin_accounts_dependencies.dart';
import '../bitcoin_accounts_screen.dart';
import '../bitcoin_widgets/bottom_sheets.dart';

class InternalAccountCreationFlow extends ConsumerStatefulWidget {
  const InternalAccountCreationFlow();

  @override
  ConsumerState<InternalAccountCreationFlow> createState() =>
      InternalAccountCreationFlowState();
}

class InternalAccountCreationFlowState
    extends ConsumerState<InternalAccountCreationFlow> {
  InternalAccountStep step = InternalAccountStep.custody;
  final TextEditingController walletNameController = TextEditingController();
  bool busy = false;
  int? selectedCustodyIndex;
  late final Set<BitcoinAccountCustody> initialUnavailableCustodies;

  @override
  void initState() {
    super.initState();
    initialUnavailableCustodies = activeCustodies(
      ref.read(bitcoinAccountsProvider).asData?.value ??
          const <BitcoinAccount>[],
    );
  }

  @override
  void dispose() {
    walletNameController.dispose();
    super.dispose();
  }

  void onCustodyContinue() {
    if (selectedCustodyIndex == null) {
      AppNotice.showWarning(
        context,
        title: 'Selecione a custódia',
        message: 'Escolha como essa carteira será custodiada antes de seguir.',
      );
      return;
    }
    HapticFeedback.selectionClick();
    continueFromCustody();
  }

  void goBack() {
    if (busy) return;
    if (step == InternalAccountStep.custody) {
      Navigator.maybePop(context);
      return;
    }
    setState(() {
      step = InternalAccountStep.custody;
    });
  }

  void continueFromCustody() {
    if (busy) return;
    if (!availableCustodyOptions
        .any((option) => option.index == selectedCustodyIndex)) {
      AppNotice.showWarning(
        context,
        title: 'Custódia indisponível',
        message: 'Essa custódia já possui uma carteira ativa.',
      );
      return;
    }
    setState(() => step = InternalAccountStep.details);
  }

  void continueFromDetails() {
    if (busy) return;
    if (walletNameController.text.trim().isEmpty) {
      AppNotice.showWarning(
        context,
        title: context.tr.createWalletNameRequired,
        message: 'Digite o nome que essa carteira deve receber.',
      );
      return;
    }
    unawaited(createInternalAccount());
  }

  Future<void> createInternalAccount() async {
    if (busy) return;

    setState(() => busy = true);
    try {
      await ref.read(bitcoinAccountsProvider.notifier).createWallet(
            label: walletNameController.text.trim(),
            custody: selectedCustody,
          );
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      AppNotice.showSuccess(
        context,
        title: context.tr.bitcoinAccountsCreateCardTitle,
        message: 'Carteira criada com sucesso.',
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      AppNotice.showError(
        context,
        title: context.tr.bitcoinAccountsCreateCardErrorTitle,
        message: context.tr.bitcoinAccountsCreateCardErrorMessage,
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    if (step == InternalAccountStep.custody) {
      return buildCustodySelectionScaffold(colors);
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
                step == InternalAccountStep.details ? 14 : 24,
                16,
                step == InternalAccountStep.details ? 2 : 8,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: goBack,
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
                child: switch (step) {
                  InternalAccountStep.custody => const SizedBox.shrink(),
                  InternalAccountStep.details => buildDetailsStep(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCustodySelectionScaffold(BitcoinAccountsColors colors) {
    final options = availableCustodyOptions;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: colors.isLight ? colors.background : Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                CustodySelectionTopBar(
                  title: context.tr.createWalletTitle,
                  colors: colors,
                  onBack: goBack,
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
                            child: MutedPanel(
                              text:
                                  'As carteiras disponíveis já foram criadas.',
                            ),
                          )
                        else
                          for (final option in options)
                            CustodySelectionTile(
                              selected: selectedCustodyIndex == option.index,
                              icon: option.icon,
                              title: option.title,
                              subtitle: option.subtitle,
                              onTap: () => setState(
                                  () => selectedCustodyIndex = option.index),
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
              child: CreationPrimaryButton(
                label: 'Continuar',
                onPressed: options.isEmpty ? null : onCustodyContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BitcoinAccountCustody get selectedCustody {
    return switch (selectedCustodyIndex) {
      1 => BitcoinAccountCustody.custodialOnchain,
      _ => BitcoinAccountCustody.custodialOnchain,
    };
  }

  List<CustodyCreationOption> get availableCustodyOptions {
    final currentAccounts = ref.watch(bitcoinAccountsProvider).asData?.value;
    final unavailableCustodies = currentAccounts == null
        ? initialUnavailableCustodies
        : {
            ...initialUnavailableCustodies,
            ...activeCustodies(currentAccounts),
          };

    return [
      if (!unavailableCustodies
          .contains(BitcoinAccountCustody.custodialOnchain))
        CustodyCreationOption(
          index: 1,
          icon: KeroseneIcons.shield,
          title: context.tr.bitcoinAccountsCustodyOnchainTitle,
          subtitle: context.tr.bitcoinAccountsCustodyOnchainSubtitle,
        ),
    ];
  }

  String get selectedCustodyLabel {
    return switch (selectedCustodyIndex) {
      1 => context.tr.bitcoinAccountsCustodyOnchainTitle,
      _ => context.tr.bitcoinAccountsCustodyOnchainTitle,
    };
  }

  Set<BitcoinAccountCustody> activeCustodies(List<BitcoinAccount> accounts) {
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

  Widget buildDetailsStep() {
    final colors = BitcoinAccountsColors.of(context);
    final title = 'Como essa carteira deve se chamar?';
    final confirmationMessage =
        'Você escolheu $selectedCustodyLabel. A carteira só será criada depois de confirmar este nome.';
    final createButtonLabel = busy ? 'Criando...' : 'Criar carteira';

    return CreationStepFrame(
      key: const ValueKey('details'),
      footer: CreationPrimaryButton(
        label: createButtonLabel,
        onPressed: busy ? null : continueFromDetails,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CreationTitle(
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
          WalletCreationLineTextField(
            controller: walletNameController,
            enabled: !busy,
            label: 'Nome da carteira',
            hintText: context.tr.createWalletNameHint,
            onSubmitted: (_) => continueFromDetails(),
          ),
        ],
      ),
    );
  }
}

class WalletCreationLineTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String label;
  final String hintText;
  final ValueChanged<String>? onSubmitted;
  final bool obscureText;
  final int minLines;
  final int maxLines;

  const WalletCreationLineTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.enabled = true,
    this.onSubmitted,
    this.obscureText = false,
    this.minLines = 1,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);
    final lineColor = enabled ? colors.border : colors.divider;

    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      minLines: minLines,
      maxLines: maxLines,
      textInputAction:
          maxLines > 1 ? TextInputAction.newline : TextInputAction.done,
      onSubmitted: onSubmitted,
      cursorColor: colors.text,
      style: AppTypography.inter(
        color: colors.text,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1.45,
        letterSpacing: 0,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: AppTypography.inter(
          color: colors.mutedText,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.2,
          letterSpacing: 0,
        ),
        hintStyle: AppTypography.inter(
          color: colors.faintText,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          height: 1.45,
          letterSpacing: 0,
        ),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: lineColor),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.text, width: 1.35),
        ),
        disabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.divider),
        ),
        filled: false,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.only(bottom: 10),
        isDense: true,
      ),
    );
  }
}

class CreationStepFrame extends StatelessWidget {
  final Widget child;
  final Widget footer;

  const CreationStepFrame({
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

class CreationTitle extends StatelessWidget {
  final String text;

  const CreationTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

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

class CreationPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const CreationPrimaryButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);
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

class CustodySelectionTopBar extends StatelessWidget {
  final String title;
  final BitcoinAccountsColors colors;
  final VoidCallback onBack;

  const CustodySelectionTopBar({
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

class CustodySelectionTile extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const CustodySelectionTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);
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

enum InternalAccountStep { custody, details }

class CustodyCreationOption {
  final int index;
  final IconData icon;
  final String title;
  final String subtitle;

  const CustodyCreationOption({
    required this.index,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

String friendlyStatus(BuildContext context, String status) {
  return switch (status.trim().toUpperCase()) {
    'ACTIVE' => context.tr.bitcoinAccountsStatusActive,
    'CREATING' => 'Criando',
    'PENDING' => context.tr.bitcoinAccountsStatusPending,
    'DISABLED' => context.tr.bitcoinAccountsStatusDisabled,
    'BLOCKED' => 'Bloqueada',
    'FROZEN' => 'Congelada',
    'ARCHIVED' => 'Arquivada',
    'ROTATING_ADDRESS' => 'Rotacionando endereço',
    'KEYGEN_FAILED' => 'Falha na criação da chave',
    'QUORUM_BLOCKED' => 'Bloqueada por quórum',
    'SUSPENDED' => 'Suspensa',
    'READY' => context.tr.bitcoinAccountsStatusReady,
    final raw when raw.isNotEmpty => raw
        .toLowerCase()
        .split('_')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' '),
    _ => context.tr.bitcoinAccountsStatusReady,
  };
}
