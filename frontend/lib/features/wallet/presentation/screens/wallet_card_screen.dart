import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/app_primary_navigation.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:teste/features/wallet/presentation/state/wallet_state.dart';

const Color _walletCardScreenBackground = Color(0xFF080A0D);
const Color _walletCardPanelBackground = Color(0xFF101419);
const Color _walletCardPanelBorder = Color(0xFF1B2027);
const Color _walletCardText = Color(0xFFF4F6F8);
const Color _walletCardMutedText = Color(0xFF9BA4AE);
const Color _walletCardFaintText = Color(0xFF6C7681);

const List<_CardShowcaseSpec> _cardShowcases = [
  _CardShowcaseSpec(
    id: 'blue',
    title: 'Azul',
    tierLabel: 'ENTRY LEVEL',
    description:
        'Cartão inicial para usuários novos. É o nível padrão da conta.',
    qualification: 'Disponível automaticamente para contas novas.',
    depositRate: 0.009,
    withdrawalRate: 0.009,
    miningRate: 0.003,
    walletCardType: WalletCardType.bronze,
    fillColor: Color(0xFF182843),
    borderColor: Color(0xFF344863),
    textColor: Color(0xFFF8FAFF),
    mutedTextColor: Color(0xFFB8C6D8),
  ),
  _CardShowcaseSpec(
    id: 'gray',
    title: 'Cinza',
    tierLabel: 'INTERMEDIÁRIO',
    description:
        'Upgrade intermediário com taxas menores para depósitos, saques e mineração.',
    qualification:
        'Movimentação acima de 1500 por mês e pelo menos 6 meses de conta.',
    depositRate: 0.008,
    withdrawalRate: 0.008,
    miningRate: 0.002,
    walletCardType: WalletCardType.white,
    fillColor: Color(0xFFC6CBD1),
    borderColor: Color(0xFFE8ECEF),
    textColor: Color(0xFF101418),
    mutedTextColor: Color(0xFF3E4650),
  ),
  _CardShowcaseSpec(
    id: 'black',
    title: 'Black',
    tierLabel: 'HIGH TIER',
    description:
        'Menor custo da plataforma para contas com maior tempo e maior volume.',
    qualification:
        'Movimentação acima de 4000 por mês e pelo menos 1 ano de conta.',
    depositRate: 0.007,
    withdrawalRate: 0.007,
    miningRate: 0.001,
    walletCardType: WalletCardType.black,
    fillColor: Color(0xFF101216),
    borderColor: Color(0xFF2D333B),
    textColor: Color(0xFFF4F6F8),
    mutedTextColor: Color(0xFFC8CDD3),
  ),
  _CardShowcaseSpec.hidden(),
];

class WalletCardScreen extends ConsumerStatefulWidget {
  const WalletCardScreen({super.key});

  @override
  ConsumerState<WalletCardScreen> createState() => _WalletCardScreenState();
}

class _WalletCardScreenState extends ConsumerState<WalletCardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (ref.read(walletProvider) is WalletInitial) {
        ref.read(walletProvider.notifier).refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final navigationClearance =
        AppPrimaryNavigationBar.scaffoldBottomClearance(context);

    final content = switch (walletState) {
      WalletLoading() || WalletInitial() => const Center(
          child: CircularProgressIndicator(color: Color(0xFF8FA0B2)),
        ),
      WalletError(:final message) => _SolidMessage(
          icon: LucideIcons.alertCircle,
          title: 'Cartão indisponível',
          message: message,
        ),
      WalletLoaded() => _buildLoadedContent(walletState),
    };

    return Scaffold(
      backgroundColor: _walletCardScreenBackground,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                navigationClearance,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: content,
                ),
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

  Widget _buildLoadedContent(WalletLoaded loaded) {
    final wallet = loaded.selectedWallet ??
        (loaded.wallets.isNotEmpty ? loaded.wallets.first : null);

    if (wallet == null) {
      return const _SolidMessage(
        icon: LucideIcons.creditCard,
        title: 'Nenhum cartão ativo',
        message: 'Crie uma carteira para habilitar o cartão da conta.',
      );
    }

    return _WalletCardCarouselExperience(
      key: ValueKey(
        '${wallet.id}:${wallet.cardType.name}:${wallet.cardSequence}:${wallet.cardRotationStatus}',
      ),
      wallet: wallet,
    );
  }
}

class _WalletCardCarouselExperience extends StatefulWidget {
  final Wallet wallet;

  const _WalletCardCarouselExperience({
    super.key,
    required this.wallet,
  });

  @override
  State<_WalletCardCarouselExperience> createState() =>
      _WalletCardCarouselExperienceState();
}

class _WalletCardCarouselExperienceState
    extends State<_WalletCardCarouselExperience> {
  late final PageController _pageController;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _indexForWalletCardType(widget.wallet.cardType);
    _pageController = PageController(
      viewportFraction: 0.84,
      initialPage: _selectedIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentCard = _cardShowcases[_selectedIndex];
    final activeCard = _showcaseForWalletCardType(widget.wallet.cardType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Cartões da conta',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: _walletCardText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Deslize para ver os cartões, as taxas e os requisitos da conta ${widget.wallet.name}.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: _walletCardMutedText,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _InfoChip(
              label: 'Atual',
              value: activeCard.title,
            ),
            const _InfoChip(
              label: 'Upgrade',
              value: 'Automático',
            ),
            _InfoChip(
              label: 'Validade',
              value: _expiryLabel(widget.wallet.cardExpiresAt),
            ),
            _InfoChip(
              label: 'Rotação',
              value: _rotationLabel(widget.wallet),
            ),
            if (widget.wallet.hasPreviousCard)
              _InfoChip(
                label: 'Anterior',
                value: '****${widget.wallet.previousCardNumberSuffix}',
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          height: 230,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _cardShowcases.length,
            onPageChanged: (index) {
              setState(() => _selectedIndex = index);
            },
            itemBuilder: (context, index) {
              final spec = _cardShowcases[index];
              final isSelected = index == _selectedIndex;
              final isCurrent = spec.walletCardType == widget.wallet.cardType;

              return AnimatedScale(
                scale: isSelected ? 1.0 : 0.94,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _ShowcaseCard(
                    spec: spec,
                    wallet: widget.wallet,
                    isCurrent: isCurrent,
                    isSelected: isSelected,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _CarouselIndicator(
          itemCount: _cardShowcases.length,
          currentIndex: _selectedIndex,
        ),
        const SizedBox(height: AppSpacing.xl),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: currentCard.isHidden
              ? const SizedBox(
                  key: ValueKey('hidden-card'),
                  height: 8,
                )
              : _CardDescriptionPanel(
                  key: ValueKey(currentCard.id),
                  spec: currentCard,
                  isCurrent:
                      currentCard.walletCardType == widget.wallet.cardType,
                ),
        ),
        if (widget.wallet.cardLastRotatedAt != null ||
            widget.wallet.hasPreviousCard) ...[
          const SizedBox(height: AppSpacing.lg),
          _RotationTimelinePanel(wallet: widget.wallet),
        ],
        const SizedBox(height: AppSpacing.xl),
        const _UpgradeRulesPanel(),
      ],
    );
  }

  int _indexForWalletCardType(WalletCardType cardType) {
    return switch (cardType) {
      WalletCardType.bronze => 0,
      WalletCardType.white => 1,
      WalletCardType.black => 2,
    };
  }

  _CardShowcaseSpec _showcaseForWalletCardType(WalletCardType cardType) {
    return _cardShowcases.firstWhere(
      (spec) => spec.walletCardType == cardType,
      orElse: () => _cardShowcases.first,
    );
  }

  String _rotationLabel(Wallet wallet) {
    if (wallet.isCardRotating) {
      return 'Em rotação';
    }
    if (wallet.isCardExpiring) {
      return 'Expirando';
    }
    return 'Ativo';
  }

  String _expiryLabel(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Nao informado';
    }
    return '${dateTime.month.toString().padLeft(2, '0')}/${(dateTime.year % 100).toString().padLeft(2, '0')}';
  }
}

class _ShowcaseCard extends StatelessWidget {
  final _CardShowcaseSpec spec;
  final Wallet wallet;
  final bool isCurrent;
  final bool isSelected;

  const _ShowcaseCard({
    required this.spec,
    required this.wallet,
    required this.isCurrent,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(
              spec.fillColor,
              Colors.white,
              spec.id == 'gray' ? 0.16 : 0.04,
            )!,
            spec.fillColor,
            Color.lerp(spec.fillColor, Colors.black, 0.28)!,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: spec.borderColor,
          width: isSelected ? 1.3 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isSelected ? 0.24 : 0.14),
            blurRadius: isSelected ? 22 : 14,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ShowcaseCardTexturePainter(
                  lineColor: spec.textColor.withValues(alpha: 0.16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: spec.isHidden
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.lock,
                            size: 34,
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'BLOQUEADO',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'KEROSENE',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: spec.textColor,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const Spacer(),
                            if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: spec.textColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        spec.textColor.withValues(alpha: 0.16),
                                  ),
                                ),
                                child: Text(
                                  'ATUAL',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: spec.textColor,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _ShowcaseChip(
                              fillColor: spec.id == 'gray'
                                  ? const Color(0xFFD0B875)
                                  : const Color(0xFFCBD3DA),
                              lineColor: Colors.black.withValues(alpha: 0.22),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.contactless,
                              color: spec.textColor.withValues(alpha: 0.70),
                              size: 24,
                            ),
                            const Spacer(),
                            Text(
                              spec.title.toUpperCase(),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: spec.mutedTextColor,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _displayNumber(),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: spec.textColor,
                            fontFamily: 'JetBrainsMono',
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.7,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: _ShowcaseCardField(
                                label: 'CARD HOLDER',
                                value: (isCurrent
                                        ? wallet.effectiveCardHolderName
                                        : wallet.name)
                                    .toUpperCase(),
                                textColor: spec.textColor,
                                mutedTextColor: spec.mutedTextColor,
                              ),
                            ),
                            const SizedBox(width: 14),
                            _ShowcaseCardField(
                              label: 'VALID THRU',
                              value: _validThru(),
                              textColor: spec.textColor,
                              mutedTextColor: spec.mutedTextColor,
                              alignEnd: true,
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _displayNumber() {
    if (isCurrent) {
      return wallet.effectiveMaskedCardNumber;
    }
    final suffix = switch (spec.walletCardType) {
      WalletCardType.bronze => '1001',
      WalletCardType.white => '2002',
      WalletCardType.black => '3003',
      null => '0000',
    };
    return '****  ****  ****  $suffix';
  }

  String _validThru() {
    if (isCurrent && wallet.cardExpiresAt != null) {
      final expiry = wallet.cardExpiresAt!;
      return '${expiry.month.toString().padLeft(2, '0')}/${(expiry.year % 100).toString().padLeft(2, '0')}';
    }
    final year = DateTime.now().year + 4;
    return '12/${(year % 100).toString().padLeft(2, '0')}';
  }
}

class _RotationTimelinePanel extends StatelessWidget {
  final Wallet wallet;

  const _RotationTimelinePanel({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: _walletCardPanelBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _walletCardPanelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rotação do cartão',
            style: theme.textTheme.titleMedium?.copyWith(
              color: _walletCardText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'A validade do cartão agora é real e a próxima emissão acontece automaticamente quando a janela expira.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: _walletCardMutedText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _TimelineRow(
            label: 'Atual',
            value:
                '${wallet.effectiveMaskedCardNumber} • vence ${_formatDate(wallet.cardExpiresAt)}',
          ),
          if (wallet.cardLastRotatedAt != null)
            _TimelineRow(
              label: 'Última rotação',
              value: _formatDateTime(wallet.cardLastRotatedAt),
            ),
          if (wallet.hasPreviousCard)
            _TimelineRow(
              label: 'Anterior',
              value:
                  '****${wallet.previousCardNumberSuffix} • expirou ${_formatDate(wallet.previousCardExpiresAt)}',
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'nao informado';
    }
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return 'nao informado';
    }
    return '${_formatDate(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}

class _TimelineRow extends StatelessWidget {
  final String label;
  final String value;

  const _TimelineRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _walletCardFaintText,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _walletCardText,
                    fontFamily: 'JetBrainsMono',
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShowcaseCardField extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;
  final Color mutedTextColor;
  final bool alignEnd;

  const _ShowcaseCardField({
    required this.label,
    required this.value,
    required this.textColor,
    required this.mutedTextColor,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: mutedTextColor,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: alignEnd ? 58 : double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShowcaseChip extends StatelessWidget {
  final Color fillColor;
  final Color lineColor;

  const _ShowcaseChip({
    required this.fillColor,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 34,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: CustomPaint(
        painter: _ShowcaseChipPainter(lineColor: lineColor),
      ),
    );
  }
}

class _ShowcaseChipPainter extends CustomPainter {
  final Color lineColor;

  const _ShowcaseChipPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85;
    canvas.drawLine(
      Offset(size.width * 0.34, 3),
      Offset(size.width * 0.34, size.height - 3),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.66, 3),
      Offset(size.width * 0.66, size.height - 3),
      paint,
    );
    canvas.drawLine(
      Offset(3, size.height * 0.32),
      Offset(size.width * 0.26, size.height * 0.32),
      paint,
    );
    canvas.drawLine(
      Offset(3, size.height * 0.68),
      Offset(size.width * 0.26, size.height * 0.68),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.74, size.height * 0.32),
      Offset(size.width - 3, size.height * 0.32),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.74, size.height * 0.68),
      Offset(size.width - 3, size.height * 0.68),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ShowcaseChipPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}

class _ShowcaseCardTexturePainter extends CustomPainter {
  final Color lineColor;

  const _ShowcaseCardTexturePainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    for (var i = -3; i < 14; i++) {
      final y = i * 18.0;
      canvas.drawLine(
        Offset(-20, y),
        Offset(size.width + 20, y + size.width * 0.24),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ShowcaseCardTexturePainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}

class _CardDescriptionPanel extends StatelessWidget {
  final _CardShowcaseSpec spec;
  final bool isCurrent;

  const _CardDescriptionPanel({
    super.key,
    required this.spec,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: _walletCardPanelBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _walletCardPanelBorder),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  spec.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: _walletCardText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    'SEU CARTÃO',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _walletCardText,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            spec.description ?? '',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _walletCardMutedText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _FeeInfoRow(
            label: 'Depósito',
            value: WalletCardType.formatRate(spec.depositRate ?? 0),
          ),
          _FeeInfoRow(
            label: 'Saque',
            value: WalletCardType.formatRate(spec.withdrawalRate ?? 0),
          ),
          _FeeInfoRow(
            label: 'Mineração',
            value: WalletCardType.formatRate(spec.miningRate ?? 0),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Como conseguir',
            style: theme.textTheme.labelLarge?.copyWith(
              color: _walletCardText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            spec.qualification ?? '',
            style: theme.textTheme.bodySmall?.copyWith(
              color: _walletCardMutedText,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeRulesPanel extends StatelessWidget {
  const _UpgradeRulesPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: _walletCardPanelBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _walletCardPanelBorder),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Como os cartões mudam',
            style: theme.textTheme.titleMedium?.copyWith(
              color: _walletCardText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Quando sua conta estiver de acordo com os requisitos, o cartão é alterado instantaneamente e automaticamente.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _walletCardMutedText,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _EligibilityRow(
            color: Color(0xFF2D5BFF),
            title: 'Azul',
            description: 'Usuários novos.',
          ),
          const _EligibilityRow(
            color: Color(0xFF7F8894),
            title: 'Cinza',
            description:
                'Movimentações acima de 1500 por mês e 6 meses de conta.',
          ),
          const _EligibilityRow(
            color: Color(0xFF101216),
            title: 'Black',
            description:
                'Movimentações acima de 4000 por mês e 1 ano de conta.',
          ),
        ],
      ),
    );
  }
}

class _FeeInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _FeeInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _walletCardMutedText,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _walletCardText,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _EligibilityRow extends StatelessWidget {
  final Color color;
  final String title;
  final String description;

  const _EligibilityRow({
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _walletCardText,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _walletCardMutedText,
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _walletCardPanelBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _walletCardPanelBorder),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _walletCardFaintText,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
            ),
            TextSpan(
              text: value,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _walletCardText,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarouselIndicator extends StatelessWidget {
  final int itemCount;
  final int currentIndex;

  const _CarouselIndicator({
    required this.itemCount,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        itemCount,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: index == currentIndex ? 18 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: index == currentIndex
                ? Colors.white.withValues(alpha: 0.88)
                : Colors.white.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _SolidMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _SolidMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: _walletCardPanelBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _walletCardPanelBorder),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8FA0B2), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: _walletCardText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _walletCardMutedText,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardShowcaseSpec {
  final String id;
  final String title;
  final String tierLabel;
  final String? description;
  final String? qualification;
  final double? depositRate;
  final double? withdrawalRate;
  final double? miningRate;
  final WalletCardType? walletCardType;
  final Color fillColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedTextColor;
  final bool isHidden;

  const _CardShowcaseSpec({
    required this.id,
    required this.title,
    required this.tierLabel,
    required this.description,
    required this.qualification,
    required this.depositRate,
    required this.withdrawalRate,
    required this.miningRate,
    required this.walletCardType,
    required this.fillColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedTextColor,
  }) : isHidden = false;

  const _CardShowcaseSpec.hidden()
      : id = 'hidden',
        title = 'Oculto',
        tierLabel = '',
        description = null,
        qualification = null,
        depositRate = null,
        withdrawalRate = null,
        miningRate = null,
        walletCardType = null,
        fillColor = const Color(0x0AFFFFFF),
        borderColor = const Color(0x26FFFFFF),
        textColor = const Color(0xFFF4F6F8),
        mutedTextColor = const Color(0xB3F4F6F8),
        isHidden = true;
}
