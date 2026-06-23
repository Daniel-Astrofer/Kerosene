part of '../bitcoin_accounts_screen.dart';

class ColdWalletCreationScreen extends ConsumerStatefulWidget {
  final String? initialStepName;

  const ColdWalletCreationScreen({super.key, this.initialStepName});

  @override
  ConsumerState<ColdWalletCreationScreen> createState() =>
      _ColdWalletCreationScreenState();
}

class _ColdWalletCreationScreenState
    extends ConsumerState<ColdWalletCreationScreen> {
  final TextEditingController _walletNameController = TextEditingController();
  final TextEditingController _extraWordController = TextEditingController();
  final List<TextEditingController> _verificationControllers = [];
  final _deriver = const ColdWalletPublicMaterialDeriver();

  _ColdWalletLevel _level = _ColdWalletLevel.recommended;
  late _ColdWalletStep _step;

  @override
  void initState() {
    super.initState();
    if (widget.initialStepName == 'prepare') {
      _step = _ColdWalletStep.prepare;
      _walletNameController.text = 'Carteira fria';
    } else {
      _step = _ColdWalletStep.purpose;
    }
  }

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
      _walletNameController.text.trim().isNotEmpty &&
      _paperReady &&
      _privatePlace &&
      _offlineReady &&
      _noPhotos;

  String get _walletLabel {
    final typed = _walletNameController.text.trim();
    return typed.isEmpty ? 'Cold Wallet' : typed;
  }

  int _activeColdWalletCountFrom(List<BitcoinAccount> accounts) {
    return accounts
        .where((account) => account.isActive && account.isWatchOnly)
        .length;
  }

  List<String> get _words =>
      _mnemonic.trim().isEmpty ? const [] : _mnemonic.split(' ');

  @override
  void dispose() {
    _walletNameController.dispose();
    _extraWordController.dispose();
    for (final controller in _verificationControllers) {
      controller.dispose();
    }
    _mnemonic = '';
    super.dispose();
  }

  void _goBack() {
    if (_busy) return;
    switch (_step) {
      case _ColdWalletStep.purpose:
        Navigator.maybePop(context);
        return;
      case _ColdWalletStep.prepare:
        setState(() => _step = _ColdWalletStep.purpose);
        return;
      case _ColdWalletStep.backup:
        _discardGeneratedMaterial();
        setState(() => _step = _ColdWalletStep.prepare);
        return;
      case _ColdWalletStep.verify:
        setState(() => _step = _ColdWalletStep.backup);
        return;
    }
  }

  void _continueFromPurpose() {
    if (_busy) return;
    final accounts = ref.read(bitcoinAccountsProvider).asData?.value ??
        const <BitcoinAccount>[];
    if (_activeColdWalletCountFrom(accounts) >= maxActiveColdWallets) {
      AppNotice.showWarning(
        context,
        title: 'Carteira fria indisponivel',
        message: 'Voce pode criar no maximo duas carteiras frias.',
      );
      return;
    }
    if (_walletNameController.text.trim().isEmpty) {
      AppNotice.showWarning(
        context,
        title: context.tr.createWalletNameRequired,
        message: 'Digite o nome que essa carteira fria deve receber.',
      );
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _step = _ColdWalletStep.prepare);
  }

  void _discardGeneratedMaterial() {
    _mnemonic = '';
    _publicMaterial = null;
    _showWords = false;
    _verificationIndexes = const [];
    for (final controller in _verificationControllers) {
      controller.dispose();
    }
    _verificationControllers.clear();
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
        title: context.tr.coldWalletVerifyFailedTitle,
        message: context.tr.coldWalletVerifyFailedMessage,
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final notifier = ref.read(bitcoinAccountsProvider.notifier);
      await notifier.importColdWallet(
        label: _walletLabel,
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
        title: context.tr.coldWalletImportedTitle,
        message: context.tr.coldWalletImportedMessage,
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      AppNotice.showError(
        context,
        title: context.tr.coldWalletImportErrorTitle,
        message: context.tr.coldWalletImportErrorMessage,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_step == _ColdWalletStep.purpose) {
      return _buildPurposeScaffold();
    }

    final responsive = context.responsive;
    final colors = BitcoinAccountsColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
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
                    onPressed: _busy ? null : _goBack,
                    icon: Icon(
                      KeroseneIcons.chevronLeft,
                      color: colors.text,
                      size: 18,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      context.tr.coldWalletCreateTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: colors.text,
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
                      _ColdWalletStep.purpose => const SizedBox.shrink(),
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

  Widget _buildPurposeScaffold() {
    final colors = BitcoinAccountsColors.of(context);
    final accounts = ref.watch(bitcoinAccountsProvider).asData?.value ??
        const <BitcoinAccount>[];
    final coldWalletLimitReached =
        _activeColdWalletCountFrom(accounts) >= maxActiveColdWallets;
    const introLabel =
        'A Kerosene guardara apenas o material publico para acompanhar saldo e UTXOs.';
    const title = 'Nomeie sua carteira fria';

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: colors.isLight ? colors.background : Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CreationTitle(title),
                    const SizedBox(height: 16),
                    Text(
                      introLabel,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        color: colors.mutedText,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 1.45,
                        letterSpacing: 0,
                      ),
                    ),
                    if (coldWalletLimitReached) ...[
                      const SizedBox(height: 16),
                      const _MutedPanel(
                        text:
                            'Voce ja possui duas carteiras frias ativas. Arquive uma delas para criar outra.',
                      ),
                    ],
                    const SizedBox(height: 32),
                    TextField(
                      controller: _walletNameController,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _continueFromPurpose(),
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        color: colors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Nome da carteira',
                        hintText: context.tr.coldWalletNameLabel,
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                MediaQuery.viewInsetsOf(context).bottom > 0 ? 20 : 40,
              ),
              child: _CreationPrimaryButton(
                label: 'Continuar',
                onPressed: coldWalletLimitReached ? null : _continueFromPurpose,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrepare() {
    final colors = BitcoinAccountsColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(context.tr.coldWalletSecurityLevelTitle),
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
            style: TextStyle(color: colors.text),
            decoration: colors.inputDecoration(
              label: context.tr.coldWalletExtraWordLabel,
              hintText: context.tr.coldWalletExtraWordHint,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _MutedPanel(text: context.tr.coldWalletExtraWordWarning),
        ],
        const SizedBox(height: AppSpacing.lg),
        _SectionTitle(context.tr.coldWalletChecklistTitle),
        _ChecklistTile(
          value: _paperReady,
          text: context.tr.coldWalletChecklistPaper,
          onChanged: (value) => setState(() => _paperReady = value),
        ),
        _ChecklistTile(
          value: _privatePlace,
          text: context.tr.coldWalletChecklistPrivate,
          onChanged: (value) => setState(() => _privatePlace = value),
        ),
        _ChecklistTile(
          value: _offlineReady,
          text: context.tr.coldWalletChecklistOffline,
          onChanged: (value) => setState(() => _offlineReady = value),
        ),
        _ChecklistTile(
          value: _noPhotos,
          text: context.tr.coldWalletChecklistNoPhotos,
          onChanged: (value) => setState(() => _noPhotos = value),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          style: colors.filledButtonStyle(),
          onPressed: _canGenerate ? _generateColdWallet : null,
          icon: const Icon(KeroseneIcons.passkey, size: 18),
          label: Text(context.tr.coldWalletGenerateAction),
        ),
      ],
    );
  }

  Widget _buildBackup() {
    final colors = BitcoinAccountsColors.of(context);
    final visibleWords = _words.asMap().entries.map(
          (entry) => _SeedWordBadge(
            index: entry.key + 1,
            word: entry.value,
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: colors.panelDecoration(color: colors.surface),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _IconFrame(
                        icon: _showWords
                            ? KeroseneIcons.eye
                            : KeroseneIcons.eyeOff),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr.coldWalletBackupTitle,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: colors.text,
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _level.title(context),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colors.mutedText,
                                      height: 1.35,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.tr.coldWalletBackupSubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.mutedText,
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_showWords)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: visibleWords.toList(),
                  )
                else
                  _MutedPanel(text: context.tr.coldWalletWordsHidden),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  style: colors.outlinedButtonStyle(),
                  onPressed: () => setState(() => _showWords = !_showWords),
                  icon: Icon(
                      _showWords ? KeroseneIcons.eyeOff : KeroseneIcons.eye),
                  label: Text(
                    _showWords
                        ? context.tr.coldWalletHideWords
                        : context.tr.coldWalletShowWords,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          style: colors.filledButtonStyle(),
          onPressed: _showWords ? _startVerification : null,
          icon: const Icon(KeroseneIcons.success, size: 18),
          label: Text(context.tr.coldWalletBackupDoneAction),
        ),
      ],
    );
  }

  Widget _buildVerify() {
    final colors = BitcoinAccountsColors.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge(_verificationControllers),
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MutedPanel(text: context.tr.coldWalletVerifySubtitle),
            const SizedBox(height: AppSpacing.lg),
            for (var index = 0;
                index < _verificationIndexes.length;
                index++) ...[
              TextField(
                controller: _verificationControllers[index],
                style: TextStyle(color: colors.text),
                decoration: colors.inputDecoration(
                  label: context.tr.coldWalletVerifyWordLabel(
                    _verificationIndexes[index] + 1,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            FilledButton.icon(
              style: colors.filledButtonStyle(),
              onPressed:
                  _busy || !_verificationMatches() ? null : _importWatchOnly,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(KeroseneIcons.security, size: 18),
              label: Text(
                _busy
                    ? context.tr.coldWalletImportingAction
                    : context.tr.coldWalletImportAction,
              ),
            ),
          ],
        ); // end of Column
      },
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
    final colors = BitcoinAccountsColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: selected ? colors.text : Colors.transparent,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected ? KeroseneIcons.success : KeroseneIcons.circle,
                  color: selected ? colors.text : colors.mutedText,
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
                              color: colors.text,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        level.body(context),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.mutedText,
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
    final colors = BitcoinAccountsColors.of(context);

    return InkWell(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colors.divider),
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: (next) => onChanged(next ?? false),
              activeColor: colors.text,
              checkColor: colors.filledButtonForeground,
              side: BorderSide(color: colors.borderStrong),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.mutedText,
                      height: 1.35,
                    ),
              ),
            ),
          ],
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
    final colors = BitcoinAccountsColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: colors.isLight ? BorderRadius.circular(10) : monoRadius,
        border: Border.all(color: colors.borderStrong),
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
                ).textTheme.labelSmall?.copyWith(color: colors.faintText),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              word,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
