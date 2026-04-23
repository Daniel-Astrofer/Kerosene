import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/core/presentation/widgets/app_notice.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/presentation/widgets/glass_container.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/widgets/transaction_auth_gate.dart';
import 'package:teste/features/auth/presentation/widgets/totp_input_container.dart';
import 'package:teste/features/mining/data/models/mempool_market_models.dart';
import 'package:teste/features/mining/domain/entities/mining_allocation.dart';
import 'package:teste/features/mining/domain/entities/mining_rig_offer.dart';
import 'package:teste/features/mining/presentation/mining_formatters.dart';
import 'package:teste/features/mining/presentation/providers/mining_providers.dart';
import 'package:teste/features/security/domain/entities/account_security_profile.dart';
import 'package:teste/features/security/presentation/providers/security_provider.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:teste/features/wallet/presentation/state/wallet_state.dart';

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
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _hashrateController = TextEditingController();
  final TextEditingController _payoutAddressController =
      TextEditingController();
  final TextEditingController _poolUrlController = TextEditingController(
    text: 'stratum+tcp://pool.example:3333',
  );
  final TextEditingController _workerNameController = TextEditingController(
    text: 'worker.01',
  );
  final TextEditingController _totpController = TextEditingController();

  bool _useBudgetMode = true;
  int _durationHours = 24;
  int? _selectedRigId;

  @override
  void dispose() {
    _budgetController.dispose();
    _hashrateController.dispose();
    _payoutAddressController.dispose();
    _poolUrlController.dispose();
    _workerNameController.dispose();
    _totpController.dispose();
    super.dispose();
  }

  Wallet? _resolveActiveWallet(WalletState state) {
    if (state is! WalletLoaded || state.wallets.isEmpty) {
      return null;
    }
    return state.selectedWallet ?? state.wallets.first;
  }

  double get _budgetBtc =>
      double.tryParse(_budgetController.text.replaceAll(',', '.')) ?? 0;

  double get _requestedHashrate =>
      double.tryParse(_hashrateController.text.replaceAll(',', '.')) ?? 0;

  MiningRigOffer? _resolveSelectedRig(List<MiningRigOffer> rigs) {
    if (rigs.isEmpty) {
      return null;
    }
    final selected = rigs.where((rig) => rig.id == _selectedRigId);
    if (selected.isNotEmpty) {
      return selected.first;
    }
    return rigs.first;
  }

  double _estimatedAllocatedHashrate(MiningRigOffer? rig) {
    if (rig == null) {
      return 0;
    }
    final durationDays = _durationHours / 24.0;
    if (durationDays <= 0) {
      return 0;
    }

    double value;
    if (_useBudgetMode) {
      if (_budgetBtc <= 0 || rig.pricePerUnitDayBtc <= 0) {
        return 0;
      }
      value = _budgetBtc / (rig.pricePerUnitDayBtc * durationDays);
    } else {
      value = _requestedHashrate;
    }

    return value.clamp(0.0, rig.availableHashrate);
  }

  double _estimatedRentalCost(MiningRigOffer? rig) {
    if (rig == null) {
      return 0;
    }
    final durationDays = _durationHours / 24.0;
    if (durationDays <= 0) {
      return 0;
    }
    final allocated = _estimatedAllocatedHashrate(rig);
    return allocated * rig.pricePerUnitDayBtc * durationDays;
  }

  double _estimatedProjectedYield(MiningRigOffer? rig) {
    if (rig == null) {
      return 0;
    }
    final durationDays = _durationHours / 24.0;
    if (durationDays <= 0) {
      return 0;
    }
    final allocated = _estimatedAllocatedHashrate(rig);
    return allocated * rig.projectedBtcYieldPerUnitDay * durationDays;
  }

  Future<AccountSecurityProfile> _resolveSecurityProfile(Wallet wallet) async {
    try {
      return await ref.read(accountSecurityProfileProvider.future);
    } catch (_) {
      return _fallbackSecurityProfile(wallet.accountSecurity);
    }
  }

  AccountSecurityProfile _fallbackSecurityProfile(String rawSecurity) {
    final mode = accountSecurityModeFromApi(rawSecurity);
    final requiredFactors = switch (mode) {
      AccountSecurityMode.shamir => const ['SLIP39_SHARES', 'TOTP'],
      AccountSecurityMode.multisig2fa => const ['PASSPHRASE', 'TOTP'],
      AccountSecurityMode.passkey => const ['PASSKEY'],
      AccountSecurityMode.standard => const ['PASSKEY'],
    };

    return AccountSecurityProfile(
      mode: mode,
      passkeyAvailable: mode == AccountSecurityMode.standard,
      passkeyEnabledForTransactions: mode == AccountSecurityMode.standard,
      requiredFactors: requiredFactors,
    );
  }

  AccountSecurityProfile _buildAuthProfile(AccountSecurityProfile profile) {
    return profile.copyWith(
      requiredFactors:
          profile.requiredFactors.where((factor) => factor != 'TOTP').toList(),
    );
  }

  Future<void> _submit(List<MiningRigOffer> rigs, Wallet wallet) async {
    await HapticFeedback.lightImpact();

    final rig = _resolveSelectedRig(rigs);
    if (rig == null) {
      AppNotice.showWarning(
        context,
        title: 'Selecione um rig',
        message: 'O backend não retornou rigs disponíveis para aluguel.',
      );
      return;
    }

    if (_durationHours < rig.minRentalHours ||
        _durationHours > rig.maxRentalHours) {
      AppNotice.showWarning(
        context,
        title: 'Prazo inválido',
        message:
            'Escolha um prazo entre ${rig.minRentalHours}h e ${rig.maxRentalHours}h para este rig.',
      );
      return;
    }

    if (_useBudgetMode && _budgetBtc <= 0) {
      AppNotice.showWarning(
        context,
        title: 'Budget inválido',
        message: 'Informe um budget em BTC maior que zero.',
      );
      return;
    }

    if (!_useBudgetMode && _requestedHashrate <= 0) {
      AppNotice.showWarning(
        context,
        title: 'Hashrate inválido',
        message: 'Informe o hashrate desejado em ${rig.hashUnit}.',
      );
      return;
    }

    if (_estimatedAllocatedHashrate(rig) <= 0) {
      AppNotice.showWarning(
        context,
        title: 'Sem alocação estimada',
        message: 'A combinação escolhida não gera hashrate contratável.',
      );
      return;
    }

    if (_totpController.text.trim().length != 6) {
      AppNotice.showWarning(
        context,
        title: 'TOTP obrigatório',
        message: 'Digite o código TOTP da carteira para continuar.',
      );
      return;
    }

    if (_payoutAddressController.text.trim().isEmpty ||
        _poolUrlController.text.trim().isEmpty ||
        _workerNameController.text.trim().isEmpty) {
      AppNotice.showWarning(
        context,
        title: 'Campos obrigatórios',
        message: 'Preencha payout address, pool URL e worker name.',
      );
      return;
    }

    final authProfile =
        _buildAuthProfile(await _resolveSecurityProfile(wallet));
    final authResult = await TransactionAuthGate.show(
      context,
      profile: authProfile,
    );

    if (!authResult.isAuthenticated || !mounted) {
      AppNotice.showWarning(
        context,
        title: 'Autenticação incompleta',
        message: 'A operação foi cancelada antes da autorização final.',
      );
      return;
    }

    final result = await ref
        .read(miningMarketplaceActionProvider.notifier)
        .createAllocation(
          walletName: wallet.name,
          rigId: rig.id,
          requestedHashrate:
              _useBudgetMode ? null : _estimatedAllocatedHashrate(rig),
          budgetBtc: _useBudgetMode ? _budgetBtc : null,
          durationHours: _durationHours,
          payoutAddress: _payoutAddressController.text.trim(),
          poolUrl: _poolUrlController.text.trim(),
          workerName: _workerNameController.text.trim(),
          totpCode: _totpController.text.trim(),
          confirmationPassphrase: authResult.confirmationPassphrase,
          passkeyAssertionResponseJson: authResult.passkeyAssertionJson,
        );

    if (!mounted) {
      return;
    }

    if (result == null) {
      final error = ref.read(miningMarketplaceActionProvider).error;
      AppNotice.showError(
        context,
        title: 'Falha ao criar alocação',
        message: error ?? 'Erro desconhecido',
      );
      return;
    }

    AppNotice.showSuccess(
      context,
      title: 'Alocação criada',
      message:
          'Rig ${rig.displayName} alugado com ${MiningFormatters.hashrateFromTh(result.allocatedHashrate)} por ${result.durationHours}h.',
    );
    Navigator.pop(context);
  }

  Future<void> _cancelAllocation(String allocationId) async {
    await HapticFeedback.selectionClick();
    final result = await ref
        .read(miningMarketplaceActionProvider.notifier)
        .cancelAllocation(allocationId);

    if (!mounted) {
      return;
    }

    if (result == null) {
      final error = ref.read(miningMarketplaceActionProvider).error;
      AppNotice.showError(
        context,
        title: 'Falha ao cancelar',
        message: error ?? 'Erro desconhecido',
      );
      return;
    }

    AppNotice.showInfo(
      context,
      title: 'Alocação encerrada',
      message: 'Refund e settlement pró-rata foram recalculados pelo backend.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final rigsAsync = ref.watch(miningRigOffersProvider);
    final allocationsAsync = ref.watch(miningAllocationsProvider);
    final actionState = ref.watch(miningMarketplaceActionProvider);
    final walletState = ref.watch(walletProvider);
    final wallet = _resolveActiveWallet(walletState);
    const scaffoldBackground = authenticatedSurfaceBackgroundColor;

    if (_payoutAddressController.text.isEmpty &&
        wallet?.address.isNotEmpty == true) {
      _payoutAddressController.text = wallet!.address;
    }
    if ((_workerNameController.text.isEmpty ||
            _workerNameController.text == 'worker.01') &&
        wallet != null) {
      _workerNameController.text =
          '${wallet.name.toLowerCase().replaceAll(' ', '-')}.01';
    }

    return Scaffold(
      backgroundColor: scaffoldBackground,
      body: Stack(
        children: [
          const Positioned.fill(
            child: AmbientSideGlowBackdrop.authenticated(),
          ),
          SafeArea(
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
                              'Marketplace de mineração',
                              style: AppTypography.h2.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Selecione um rig, defina budget ou hashrate e envie a alocação para o backend.',
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
                  _buildNetworkContextCard(wallet),
                  const SizedBox(height: AppSpacing.lg),
                  rigsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, _) => _ErrorCard(
                      message: error.toString(),
                      onRetry: () {
                        ref.invalidate(miningRigOffersProvider);
                      },
                    ),
                    data: (rigs) {
                      final rig = _resolveSelectedRig(rigs);
                      final allocatedHashrate =
                          _estimatedAllocatedHashrate(rig);
                      final rentalCostBtc = _estimatedRentalCost(rig);
                      final projectedYieldBtc = _estimatedProjectedYield(rig);

                      if (_selectedRigId == null && rigs.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() => _selectedRigId = rigs.first.id);
                          }
                        });
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel(
                            title: 'Rigs disponíveis',
                            subtitle:
                                'Catálogo retornado por `GET /mining/rigs` com preço por unidade-dia.',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: rigs.map((item) {
                              final selected = item.id == rig?.id;
                              return ChoiceChip(
                                selected: selected,
                                label: Text(item.displayName),
                                onSelected: (_) {
                                  setState(() {
                                    _selectedRigId = item.id;
                                    _durationHours = _durationHours.clamp(
                                      item.minRentalHours,
                                      item.maxRentalHours,
                                    );
                                  });
                                },
                                selectedColor:
                                    AppColors.success.withValues(alpha: 0.22),
                                labelStyle: TextStyle(
                                  color: Colors.white.withValues(
                                    alpha: selected ? 1 : 0.72,
                                  ),
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _buildRigSummaryCard(rig),
                          const SizedBox(height: AppSpacing.lg),
                          _buildModeSelector(),
                          const SizedBox(height: AppSpacing.md),
                          if (_useBudgetMode)
                            _buildBudgetField()
                          else
                            _buildHashrateField(rig),
                          const SizedBox(height: AppSpacing.lg),
                          _buildDurationSelector(rig),
                          const SizedBox(height: AppSpacing.lg),
                          _buildDestinationFields(),
                          const SizedBox(height: AppSpacing.lg),
                          _buildEstimateCard(
                            rig: rig,
                            allocatedHashrate: allocatedHashrate,
                            rentalCostBtc: rentalCostBtc,
                            projectedYieldBtc: projectedYieldBtc,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _buildTotpCard(),
                          const SizedBox(height: AppSpacing.lg),
                          FilledButton.icon(
                            onPressed: wallet == null || actionState.isLoading
                                ? null
                                : () => _submit(rigs, wallet),
                            icon: actionState.isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.bolt_rounded),
                            label: const Text('Criar alocação'),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _SectionLabel(
                    title: 'Alocações ativas e recentes',
                    subtitle:
                        'Histórico autenticado de `GET /mining/allocations` com cancelamento pró-rata.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  allocationsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, _) => _ErrorCard(
                      message: error.toString(),
                      onRetry: () {
                        ref.invalidate(miningAllocationsProvider);
                      },
                    ),
                    data: (allocations) {
                      if (allocations.isEmpty) {
                        return _EmptyCard(
                          message:
                              'Nenhuma alocação encontrada ainda. Crie a primeira operação acima.',
                        );
                      }
                      return Column(
                        children: allocations
                            .map(
                              (allocation) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md),
                                child: _AllocationCard(
                                  allocation: allocation,
                                  onCancel: allocation.isActive
                                      ? () => _cancelAllocation(allocation.id)
                                      : null,
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkContextCard(Wallet? wallet) {
    return GlassContainer(
      blur: 24,
      opacity: 0.08,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contexto de rede e liquidação',
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _MiniMetric(
                    label: 'Hashrate da rede',
                    value: MiningFormatters.hashrate(
                      widget.dashboardData.hashrate.currentHashrate,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MiniMetric(
                    label: 'Recompensa diária',
                    value: MiningFormatters.btc(
                        widget.dashboardData.dailyRewardBtc),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              wallet == null
                  ? 'Selecione uma carteira para debitar o aluguel e preencher o payout address.'
                  : 'Carteira ativa: ${wallet.name} • saldo ${MiningFormatters.btc(wallet.balance)}',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.62),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRigSummaryCard(MiningRigOffer? rig) {
    if (rig == null) {
      return const SizedBox.shrink();
    }

    return GlassContainer(
      blur: 20,
      opacity: 0.06,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rig.displayName,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${rig.algorithm} • ${rig.provider} • ${rig.availableHashrate.toStringAsFixed(0)} ${rig.hashUnit} disponíveis',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _MiniMetric(
                    label: 'Preço por ${rig.hashUnit}/dia',
                    value: MiningFormatters.btc(rig.pricePerUnitDayBtc),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MiniMetric(
                    label: 'Yield por ${rig.hashUnit}/dia',
                    value: MiningFormatters.btc(
                      rig.projectedBtcYieldPerUnitDay,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            selected: _useBudgetMode,
            label: const Text('Budget BTC'),
            onSelected: (_) => setState(() => _useBudgetMode = true),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: ChoiceChip(
            selected: !_useBudgetMode,
            label: const Text('Hashrate'),
            onSelected: (_) => setState(() => _useBudgetMode = false),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetField() {
    return TextField(
      controller: _budgetController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      decoration: _inputDecoration(
        label: 'Budget em BTC',
        hint: '0.01000000',
        suffix: 'BTC',
      ),
      style: AppTypography.h3.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _buildHashrateField(MiningRigOffer? rig) {
    return TextField(
      controller: _hashrateController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      decoration: _inputDecoration(
        label: 'Hashrate desejado',
        hint: rig == null ? '0' : '1000',
        suffix: rig?.hashUnit ?? 'TH',
      ),
      style: AppTypography.h3.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _buildDurationSelector(MiningRigOffer? rig) {
    final allowedDurations = const [1, 6, 12, 24, 72, 168]
        .where((hours) =>
            rig == null ||
            (hours >= rig.minRentalHours && hours <= rig.maxRentalHours))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prazo do aluguel',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allowedDurations.map((hours) {
            final selected = hours == _durationHours;
            return ChoiceChip(
              selected: selected,
              label: Text('${hours}h'),
              onSelected: (_) => setState(() => _durationHours = hours),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDestinationFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _payoutAddressController,
          decoration: _inputDecoration(
            label: 'Payout address',
            hint: 'bc1q...',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _poolUrlController,
          decoration: _inputDecoration(
            label: 'Pool URL',
            hint: 'stratum+tcp://pool.example:3333',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _workerNameController,
          decoration: _inputDecoration(
            label: 'Worker name',
            hint: 'worker.01',
          ),
        ),
      ],
    );
  }

  Widget _buildEstimateCard({
    required MiningRigOffer? rig,
    required double allocatedHashrate,
    required double rentalCostBtc,
    required double projectedYieldBtc,
  }) {
    return GlassContainer(
      blur: 18,
      opacity: 0.06,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prévia da alocação',
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _MiniMetric(
              label: 'Hashrate alocado',
              value: rig == null
                  ? '--'
                  : '${allocatedHashrate.toStringAsFixed(2)} ${rig.hashUnit}',
            ),
            const SizedBox(height: AppSpacing.sm),
            _MiniMetric(
              label: 'Custo estimado',
              value: MiningFormatters.btc(rentalCostBtc),
            ),
            const SizedBox(height: AppSpacing.sm),
            _MiniMetric(
              label: 'Yield bruto projetado',
              value: MiningFormatters.btc(projectedYieldBtc),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotpCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Autorização TOTP',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TotpInputContainer(
          controller: _totpController,
          onChanged: (_) {},
          onCompleted: (_) {},
          accentColor: AppColors.success,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    String? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffix,
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
          color: AppColors.secondary.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionLabel({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white.withValues(alpha: 0.58),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.48),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AllocationCard extends StatelessWidget {
  final MiningAllocation allocation;
  final VoidCallback? onCancel;

  const _AllocationCard({
    required this.allocation,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (allocation.status) {
      MiningAllocationStatus.active => AppColors.success,
      MiningAllocationStatus.cancelled => AppColors.warning,
      MiningAllocationStatus.completed => AppColors.secondary,
      MiningAllocationStatus.unknown => Colors.white54,
    };

    return GlassContainer(
      blur: 18,
      opacity: 0.06,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    allocation.rigName,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    allocation.status.name.toUpperCase(),
                    style: AppTypography.caption.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${allocation.algorithm} • ${allocation.allocatedHashrate.toStringAsFixed(2)} ${allocation.hashUnit} • ${allocation.durationHours}h',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _MiniMetric(
                    label: 'Custo',
                    value: MiningFormatters.btc(allocation.rentalCostBtc),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MiniMetric(
                    label: 'Yield líquido',
                    value:
                        MiningFormatters.btc(allocation.projectedNetYieldBtc),
                  ),
                ),
              ],
            ),
            if (onCancel != null) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Cancelar alocação'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: 18,
      opacity: 0.06,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.error.withValues(alpha: 0.18)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.68),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: 18,
      opacity: 0.06,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          message,
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white.withValues(alpha: 0.62),
          ),
        ),
      ),
    );
  }
}
