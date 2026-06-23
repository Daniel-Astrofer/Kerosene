// ignore_for_file: unused_element, unused_field, unused_element_parameter

import 'package:flutter/material.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/features/landing/application/providers/public_site_provider.dart';
import 'package:kerosene/features/landing/presentation/kerosene_landing_components.dart';
import 'package:kerosene/features/landing/presentation/kerosene_landing_tokens.dart';

class KeroseneLandingPage extends ConsumerStatefulWidget {
  final bool focusDownload;

  const KeroseneLandingPage({super.key, this.focusDownload = false});

  @override
  ConsumerState<KeroseneLandingPage> createState() =>
      _KeroseneLandingPageState();
}

class _KeroseneLandingPageState extends ConsumerState<KeroseneLandingPage> {
  final _productKey = GlobalKey();
  final _securityKey = GlobalKey();
  final _businessKey = GlobalKey();
  final _infrastructureKey = GlobalKey();
  final _faqKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.focusDownload) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(_faqKey));
    }
  }

  @override
  Widget build(BuildContext context) {
    final readyAsync = ref.watch(publicReadinessProvider);
    final statusLabel = landingStatusLabel(context, readyAsync.asData?.value);

    return Scaffold(
      backgroundColor: landingInk,
      body: SelectionArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: const LandingBackdropPainter(),
              ),
            ),
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: LandingHeroSection(
                    statusLabel: statusLabel,
                    onCreateAccount: _openCreateAccount,
                    onBusinessPanel: _openBusinessPanel,
                  ),
                ),
                SliverToBoxAdapter(
                  child: LandingSectionShell(
                    key: _productKey,
                    topPadding: 16,
                    child: LandingProductSection(
                        onCreateAccount: _openCreateAccount),
                  ),
                ),
                SliverToBoxAdapter(
                  child: LandingSectionShell(
                    key: _businessKey,
                    topPadding: 14,
                    child: const LandingAudienceSection(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: LandingSectionShell(
                    key: _securityKey,
                    topPadding: 26,
                    child: const LandingArchitectureSection(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: LandingSectionShell(
                    key: _faqKey,
                    topPadding: 22,
                    bottomPadding: 30,
                    child: LandingFinalCta(
                      onCreateAccount: _openCreateAccount,
                      onBusinessPanel: _openBusinessPanel,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                    child: LandingFooter(statusLabel: statusLabel)),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LandingTopNav(
                onProduct: () => _scrollTo(_productKey),
                onSecurity: () => _scrollTo(_securityKey),
                onBusiness: () => _scrollTo(_businessKey),
                onInfrastructure: () => _scrollTo(_securityKey),
                onFaq: () => _scrollTo(_faqKey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateAccount() {
    Navigator.of(context).pushNamed('/download');
  }

  void _openBusinessPanel() {
    Navigator.of(context).pushNamed('/admin');
  }

  void _scrollTo(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext == null) {
      return;
    }
    Scrollable.ensureVisible(
      targetContext,
      duration: KeroseneMotion.slow,
      curve: KeroseneMotion.standard,
      alignment: 0.04,
    );
  }
}

class KerosenePublicStatusPage extends ConsumerWidget {
  const KerosenePublicStatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readyAsync = ref.watch(publicReadinessProvider);
    final releaseAsync = ref.watch(publicReleaseProvider);
    final readiness = readyAsync.asData?.value;
    final release = releaseAsync.asData?.value;

    return Scaffold(
      backgroundColor: landingInk,
      appBar: AppBar(
        backgroundColor: landingInk,
        foregroundColor: Colors.white,
        title: Text(context.tr.landingStatusPageTitle),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(publicReadinessProvider);
          ref.invalidate(publicReleaseProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: LandingStatusDetails(
                readiness: readiness,
                release: release,
                loading: readyAsync.isLoading || releaseAsync.isLoading,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
