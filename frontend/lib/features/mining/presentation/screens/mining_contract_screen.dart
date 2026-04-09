import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/core/presentation/widgets/app_notice.dart';
import 'package:teste/core/presentation/widgets/glass_container.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/features/mining/data/models/mempool_market_models.dart';
import 'package:teste/features/mining/presentation/mining_formatters.dart';
import 'package:teste/features/mining/presentation/providers/mining_providers.dart';

class MiningContractScreen extends ConsumerStatefulWidget {
  final MempoolMiningDashboardData dashboardData;

  const MiningContractScreen({
    super.key,
    required this.dashboardData,
  });

  @override
  ConsumerState<MiningContractScreen> createState() =>
      _MiningContractScreenState();
}

class _MiningContractScreenState extends ConsumerState<MiningContractScreen> {
  static const List<int> _durationOptions = [12, 24, 72, 168];

  final TextEditingController _targetController = TextEditingController();
  int _durationHours = 72;

  @override
  void initState() {
    super.initState();
    final activeOperation = ref.read(miningOperationProvider);
    if (activeOperation.isActive) {
      _targetController.text = activeOperation.targetBtc.toStringAsFixed(6);
      _durationHours = activeOperation.durationHours;
    }
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  double get _targetBtc {
    final normalized = _targetController.text.replaceAll(',', '.').trim();
    return double.tryParse(normalized) ?? 0;
  }

  double get _requiredHashrateTh {
    final durationDays = _durationHours / 24.0;
    if (_targetBtc <= 0 ||
        durationDays <= 0 ||
        widget.dashboardData.dailyRewardBtc <= 0 ||
        widget.dashboardData.hashrate.currentHashrate <= 0) {
      return 0;
    }

    final btcPerDayTarget = _targetBtc / durationDays;
    final shareOfNetwork =
        btcPerDayTarget / widget.dashboardData.dailyRewardBtc;
    final contractedHashrateHs =
        widget.dashboardData.hashrate.currentHashrate * shareOfNetwork;

    return contractedHashrateHs / 1000000000000.0;
  }

  Future<void> _submit() async {
    await HapticFeedback.lightImpact();

    if (_targetBtc <= 0) {
      AppNotice.showWarning(
        context,
        title: 'Valor inválido',
        message:
            'Digite um alvo em BTC maior que zero para projetar a operação.',
      );
      return;
    }

    if (_requiredHashrateTh <= 0) {
      AppNotice.showError(
        context,
        title: 'Sem estimativa',
        message:
            'Os dados públicos da mempool não retornaram hashrate suficiente para o cálculo.',
      );
      return;
    }

    await ref.read(miningOperationProvider.notifier).startOperation(
          targetBtc: _targetBtc,
          durationHours: _durationHours,
          contractedHashrateTh: _requiredHashrateTh,
        );

    if (!mounted) {
      return;
    }

    AppNotice.showSuccess(
      context,
      title: 'Operação configurada',
      message:
          'O painel foi atualizado com alvo, hashrate contratado e tempo restante.',
    );
    Navigator.pop(context);
  }

  Future<void> _clearOperation() async {
    await HapticFeedback.selectionClick();
    await ref.read(miningOperationProvider.notifier).clearOperation();

    if (!mounted) {
      return;
    }

    AppNotice.showInfo(
      context,
      title: 'Operação removida',
      message: 'O painel de mineração voltou ao estado inicial.',
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final activeOperation = ref.watch(miningOperationProvider);
    final dailyTargetBtc =
        _durationHours <= 0 ? 0.0 : _targetBtc / (_durationHours / 24.0);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF04070B),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF04070B),
              Color(0xFF07121A),
              Color(0xFF05080D),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                      ),
                      color: Colors.white,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Configurar mineração',
                            style: AppTypography.h2.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Defina o alvo em BTC e o prazo para estimar o hashrate necessário usando somente dados públicos da mempool.',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.62),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                GlassContainer(
                  blur: 24,
                  opacity: 0.08,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alvo da operação',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _targetController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9\.,]'),
                            ),
                          ],
                          onChanged: (_) => setState(() {}),
                          style: AppTypography.h3.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Quanto deseja projetar em BTC',
                            hintText: '0.01500000',
                            suffixText: 'BTC',
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.04),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color:
                                    AppColors.secondary.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Prazo do contrato',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _durationOptions.map((hours) {
                            final selected = hours == _durationHours;
                            return ChoiceChip(
                              label: Text(
                                hours >= 24
                                    ? '${(hours / 24).round()} dia${hours == 24 ? '' : 's'}'
                                    : '$hours h',
                              ),
                              selected: selected,
                              onSelected: (_) {
                                setState(() => _durationHours = hours);
                              },
                              labelStyle: TextStyle(
                                color: selected
                                    ? Colors.black
                                    : Colors.white.withValues(alpha: 0.86),
                                fontWeight: FontWeight.w700,
                              ),
                              selectedColor: const Color(0xFF9FE870),
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.06),
                              side: BorderSide(
                                color: selected
                                    ? const Color(0xFF9FE870)
                                    : Colors.white.withValues(alpha: 0.08),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _EstimatePanel(
                          targetBtc: _targetBtc,
                          durationHours: _durationHours,
                          requiredHashrateTh: _requiredHashrateTh,
                          dailyTargetBtc: dailyTargetBtc,
                          networkHashrate:
                              widget.dashboardData.hashrate.currentHashrate,
                          dailyRewardBtc: widget.dashboardData.dailyRewardBtc,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF9FE870),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text('Minerar'),
                          ),
                        ),
                        if (activeOperation.isActive) ...[
                          const SizedBox(height: AppSpacing.sm),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _clearOperation,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.10),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: const Text('Limpar operação atual'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                GlassContainer(
                  blur: 18,
                  opacity: 0.05,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Referência de mercado',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Hashrate atual da rede: ${MiningFormatters.hashrate(widget.dashboardData.hashrate.currentHashrate)}',
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Recompensa das últimas 144 confirmações: ${MiningFormatters.btc(widget.dashboardData.dailyRewardBtc)}',
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Esta tela só estima a operação usando dados públicos da mempool. Nenhum pedido externo além da API da mempool é enviado.',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.62),
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
      ),
    );
  }
}

class _EstimatePanel extends StatelessWidget {
  final double targetBtc;
  final int durationHours;
  final double requiredHashrateTh;
  final double dailyTargetBtc;
  final double networkHashrate;
  final double dailyRewardBtc;

  const _EstimatePanel({
    required this.targetBtc,
    required this.durationHours,
    required this.requiredHashrateTh,
    required this.dailyTargetBtc,
    required this.networkHashrate,
    required this.dailyRewardBtc,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = <({String label, String value})>[
      (
        label: 'Meta',
        value: targetBtc > 0 ? MiningFormatters.btc(targetBtc) : '--',
      ),
      (
        label: 'Hashrate estimado',
        value: requiredHashrateTh > 0
            ? MiningFormatters.hashrateFromTh(requiredHashrateTh)
            : '--',
      ),
      (
        label: 'Meta por dia',
        value: dailyTargetBtc > 0 ? MiningFormatters.btc(dailyTargetBtc) : '--',
      ),
      (
        label: 'Prazo',
        value: MiningFormatters.duration(Duration(hours: durationHours)),
      ),
      (
        label: 'Hashrate da rede',
        value: MiningFormatters.hashrate(networkHashrate),
      ),
      (
        label: 'Recompensa diária',
        value: MiningFormatters.btc(dailyRewardBtc),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estimativa instantânea',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.52,
          ),
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.label,
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.58),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    metric.value,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
