part of 'home_screen.dart';

class _SendMethodScreen extends StatefulWidget {
  final List<_QuickActionData> actions;

  const _SendMethodScreen({required this.actions});

  @override
  State<_SendMethodScreen> createState() => _SendMethodScreenState();
}

class _SendMethodScreenState extends State<_SendMethodScreen> {
  static const Color _screenBackground = Color(0xFF000000);
  static const Color _mutedTextColor = Color(0xFFA0A0A0);

  _HomeActionIconKind? _selectedKind;

  List<_QuickActionData> get _transferActions {
    final actionsByKind = {
      for (final action in widget.actions) action.kind: action,
    };
    const orderedKinds = [
      _HomeActionIconKind.internalTransfer,
      _HomeActionIconKind.payLightning,
      _HomeActionIconKind.sendOnChain,
    ];

    return [
      for (final kind in orderedKinds)
        if (actionsByKind[kind] != null) actionsByKind[kind]!,
    ];
  }

  void _selectAction(_QuickActionData action) {
    HapticFeedback.selectionClick();
    setState(() => _selectedKind = action.kind);

    Future<void>.delayed(const Duration(milliseconds: 140), () {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      action.onTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isNarrow = mediaQuery.size.width < 360;
    final horizontalPadding = isNarrow ? 20.0 : 24.0;
    final transferActions = _transferActions;

    return Scaffold(
      backgroundColor: _screenBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                8,
                horizontalPadding,
                0,
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: context.tr.authBackAction,
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.white.withValues(alpha: 0.72),
                      minimumSize: const Size.square(44),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(LucideIcons.arrowLeft, size: 24),
                  ),
                  const Spacer(),
                  const SizedBox(width: 44, height: 44),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16,
                  horizontalPadding,
                  28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _localizedTransferTitle(context),
                          style: GoogleFonts.ibmPlexSerif(
                            textStyle: Theme.of(context).textTheme.displaySmall,
                            color: Colors.white,
                            fontSize: isNarrow ? 38 : 42,
                            fontWeight: FontWeight.w300,
                            height: 1.02,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _localizedTransferSubtitle(context),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: _mutedTextColor,
                                    fontSize: 14,
                                    height: 1.35,
                                    letterSpacing: 0,
                                  ),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var index = 0;
                                index < transferActions.length;
                                index++) ...[
                              if (index > 0) const SizedBox(width: 8),
                              Expanded(
                                child: _SendMethodOptionButton(
                                  action: transferActions[index],
                                  label: _localizedTransferOptionLabel(
                                    context,
                                    transferActions[index].kind,
                                  ),
                                  selected: _selectedKind ==
                                      transferActions[index].kind,
                                  showFeeBadge: transferActions[index].kind ==
                                      _HomeActionIconKind.internalTransfer,
                                  feeLabel: _localizedTransferFeeLabel(context),
                                  onTap: () =>
                                      _selectAction(transferActions[index]),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 48),
                        Text(
                          _localizedLearnMoreTitle(context),
                          style: GoogleFonts.ibmPlexSerif(
                            textStyle: Theme.of(context).textTheme.titleLarge,
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w300,
                            height: 1.05,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SendEducationCard(
                          title: _localizedEducationTitle(context),
                          body: _localizedEducationBody(context),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            AppNotice.showInfo(
                              context,
                              title: _localizedEducationTitle(context),
                              message: _localizedEducationBody(context),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 120,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _localizedTransferTitle(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'en' => 'Transfer',
      'es' => 'Transferir',
      _ => 'Transferir',
    };
  }

  String _localizedTransferSubtitle(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'en' => 'Choose how you want to send your funds.',
      'es' => 'Elige cómo quieres enviar tus fondos.',
      _ => 'Escolha como deseja enviar seus fundos.',
    };
  }

  String _localizedTransferOptionLabel(
    BuildContext context,
    _HomeActionIconKind kind,
  ) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return switch (kind) {
      _HomeActionIconKind.internalTransfer => switch (languageCode) {
          'en' => 'Internal\nTransfer',
          'es' => 'Transferencia\nInterna',
          _ => 'Transferência\nInterna',
        },
      _HomeActionIconKind.payLightning => switch (languageCode) {
          'en' => 'Lightning\nTransfer',
          'es' => 'Transferencia\nLightning',
          _ => 'Transferência\nLightning',
        },
      _HomeActionIconKind.sendOnChain => switch (languageCode) {
          'en' => 'On-chain\nTransfer',
          'es' => 'Transferencia\nOn-chain',
          _ => 'Transferência\nOn-chain',
        },
      _ => '',
    };
  }

  String _localizedTransferFeeLabel(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'en' => '0 fees',
      'es' => '0 comisiones',
      _ => '0 taxas',
    };
  }

  String _localizedLearnMoreTitle(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'en' => 'Learn more',
      'es' => 'Saber más',
      _ => 'Saiba mais',
    };
  }

  String _localizedEducationTitle(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'en' => 'How do transactions work?',
      'es' => '¿Cómo funcionan las transacciones?',
      _ => 'Como funcionam as transações?',
    };
  }

  String _localizedEducationBody(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'en' =>
        'Understand the differences between networks and choose the best option to protect your wealth.',
      'es' =>
        'Entiende las diferencias entre las redes y elige la mejor opción para proteger tu patrimonio.',
      _ =>
        'Entenda as diferenças entre as redes e escolha a melhor opção para proteger seu patrimônio.',
    };
  }
}

class _SendMethodOptionButton extends StatelessWidget {
  final _QuickActionData action;
  final String label;
  final bool selected;
  final bool showFeeBadge;
  final String feeLabel;
  final VoidCallback onTap;

  const _SendMethodOptionButton({
    required this.action,
    required this.label,
    required this.selected,
    required this.showFeeBadge,
    required this.feeLabel,
    required this.onTap,
  });

  static const Color _panelColor = Color(0xFF111111);
  static const Color _borderColor = Color(0xFF222222);
  static const Color _feeTextColor = Color(0xFF34D399);

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 360;
    final labelSize = isNarrow ? 11.0 : 12.0;

    return Semantics(
      button: true,
      selected: selected,
      label: label.replaceAll('\n', ' '),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SizedBox(
              height: 124,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutCubic,
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.10)
                          : _panelColor,
                      border: Border.all(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.54)
                            : _borderColor,
                      ),
                    ),
                    child: Center(
                      child: _HomeActionIcon(
                        kind: action.kind,
                        iconColor: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontSize: labelSize,
                          fontWeight: FontWeight.w300,
                          height: 1.12,
                          letterSpacing: 0,
                        ),
                  ),
                  if (showFeeBadge) ...[
                    const SizedBox(height: 7),
                    Text(
                      feeLabel.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _feeTextColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w300,
                            height: 1,
                            letterSpacing: 0.4,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SendEducationCard extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onTap;

  const _SendEducationCard({
    required this.title,
    required this.body,
    required this.onTap,
  });

  static const Color _panelColor = Color(0xFF111111);
  static const Color _borderColor = Color(0xFF222222);
  static const Color _mutedTextColor = Color(0xFFA0A0A0);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            color: _panelColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 64,
                    height: 64,
                    color: Colors.black,
                    child: Image.asset(
                      'assets/logo/kerosene-logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          LucideIcons.bitcoin,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              height: 1.2,
                              letterSpacing: 0,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _mutedTextColor,
                              fontSize: 12,
                              height: 1.35,
                              letterSpacing: 0,
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
