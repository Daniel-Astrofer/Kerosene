import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slip39/slip39.dart';

import '../../../../../../core/theme/cyber_theme.dart';
import '../../../providers/signup_flow_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Standard passphrase phases
// ─────────────────────────────────────────────────────────────────────────────

enum PassphrasePhase { generation, verification }

class PassphraseStep extends ConsumerStatefulWidget {
  const PassphraseStep({super.key});

  @override
  ConsumerState<PassphraseStep> createState() => _PassphraseStepState();
}

class _PassphraseStepState extends ConsumerState<PassphraseStep> {
  // Standard
  PassphrasePhase _phase = PassphrasePhase.generation;
  String _generatedMnemonic = '';
  final _verificationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // SLIP-39 state
  List<List<String>> _slip39Shares = []; // [shareIndex][words]
  int _currentSlip39Page = 0;
  final PageController _slip39PageController = PageController();
  List<bool> _slip39Confirmed = []; // user confirmed each share
  int _verifyingShareIndex = -1; // which share is being verified
  final _slip39VerifyController = TextEditingController();
  final _slip39FormKey = GlobalKey<FormState>();

  // 2FA Multisig
  String _primarySeed = '';
  String _backupSeed = '';
  int twoFaPhase =
      0; // 0 = primary display, 1 = backup display, 2 = verification

  @override
  void initState() {
    super.initState();
    final option = ref.read(signupFlowProvider).seedSecurityOption;
    _initForOption(option);
  }

  void _initForOption(SeedSecurityOption option) {
    switch (option) {
      case SeedSecurityOption.standard:
        _generateMnemonic();
        break;
      case SeedSecurityOption.slip39:
        _generateSlip39Shares();
        break;
      case SeedSecurityOption.multisig2fa:
        _generate2FASeedPair();
        break;
    }
  }

  // ─── Standard ───────────────────────────────────────────────────────────────

  void _generateMnemonic() {
    try {
      final mnemonic = Mnemonic.generate(
        Language.portuguese,
        length: MnemonicLength.words18,
      ).sentence;
      setState(() {
        _generatedMnemonic = mnemonic;
        _phase = PassphrasePhase.generation;
        _verificationController.clear();
      });
    } catch (e) {
      setState(() {
        _generatedMnemonic = 'Erro ao gerar frase';
      });
    }
  }

  // ─── SLIP-39 ─────────────────────────────────────────────────────────────────

  void _generateSlip39Shares() {
    try {
      final flowState = ref.read(signupFlowProvider);
      final total = flowState.slip39TotalShares;
      final threshold = flowState.slip39Threshold;

      // Generate a random 16-byte master secret (must be even length)
      final random = Random.secure();
      final masterSecretBytes = Uint8List.fromList(
        List.generate(16, (_) => random.nextInt(256)),
      );

      // Single group: threshold-of-total  →  groups = [[threshold, total]]
      // Slip39.from() takes a List groups, a Uint8List masterSecret,
      // and an int threshold for the group-of-groups level (use 1 for a single group).
      final slip = Slip39.from(
        [
          [threshold, total],
        ],
        masterSecret: masterSecretBytes,
        passphrase: '',
        threshold: 1,
      );

      // Slip39Node.mnemonics returns List<String> with the words for each leaf
      final List<List<String>> shares = [];
      for (int i = 0; i < total; i++) {
        final node = slip.fromPath('r/0/$i');
        final mnemonic = node.mnemonics;
        shares.add(mnemonic);
      }

      setState(() {
        _slip39Shares = shares;
        _slip39Confirmed = List.filled(total, false);
        _currentSlip39Page = 0;
        _verifyingShareIndex = -1;
      });

      // Store raw bytes encoded to hex — deferred to avoid modifying a provider
      // during initState (Riverpod forbids provider writes while tree is building).
      final masterHex = masterSecretBytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(signupFlowProvider.notifier).setPassphrase(masterHex);
        }
      });
    } catch (e) {
      setState(() {
        _slip39Shares = [
          ['Error generating SLIP-39 shares: $e'],
        ];
      });
    }
  }

  // ─── 2FA Multisig ─────────────────────────────────────────────────────────

  void _generate2FASeedPair() {
    try {
      final primary = Mnemonic.generate(
        Language.english,
        length: MnemonicLength.words18,
      ).sentence;
      final backup = Mnemonic.generate(
        Language.english,
        length: MnemonicLength.words12,
      ).sentence;
      setState(() {
        _primarySeed = primary;
        _backupSeed = backup;
        twoFaPhase = 0;
      });
      // Defer provider write — not allowed inside initState while tree is building.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(signupFlowProvider.notifier).setPassphrase(primary);
        }
      });
    } catch (e) {
      setState(() {
        _primarySeed = 'Error generating seed pair';
        _backupSeed = '';
      });
    }
  }

  @override
  void dispose() {
    _verificationController.dispose();
    _slip39PageController.dispose();
    _slip39VerifyController.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final option = ref.watch(signupFlowProvider).seedSecurityOption;
    switch (option) {
      case SeedSecurityOption.standard:
        return _phase == PassphrasePhase.generation
            ? _buildStandardGeneration()
            : _buildStandardVerification();
      case SeedSecurityOption.slip39:
        if (_verifyingShareIndex >= 0) {
          return _buildSlip39ShareVerification();
        }
        return _buildSlip39SharesDisplay();
      case SeedSecurityOption.multisig2fa:
        return _build2FAPhase();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STANDARD SCREENS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStandardGeneration() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.vpn_key_rounded,
            size: 56,
            color: CyberTheme.neonCyan,
          ),
          const SizedBox(height: 16),
          Text(
            'Your Secret Phrase',
            style: CyberTheme.heading(size: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Write down these 18 words on a physical piece of paper. Never save this digitally.',
            style: CyberTheme.label(size: 14, color: CyberTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _mnemonicCard(_generatedMnemonic, CyberTheme.neonCyan),
          const SizedBox(height: 24),
          _warningRow(
            'If you lose these words, you will permanently lose access to your account and funds.',
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () =>
                setState(() => _phase = PassphrasePhase.verification),
            style: CyberTheme.neonButton(CyberTheme.neonCyan),
            child: const Text('I Have Written It Down'),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardVerification() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.fact_check_rounded,
              size: 56,
              color: CyberTheme.neonPurple,
            ),
            const SizedBox(height: 16),
            Text(
              'Verify Phrase',
              style: CyberTheme.heading(size: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Type your secret phrase to confirm you have backed it up correctly.',
              style: CyberTheme.label(
                size: 14,
                color: CyberTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _verificationController,
              maxLines: 4,
              style: GoogleFonts.jetBrainsMono(
                color: CyberTheme.textPrimary,
                fontSize: 14,
              ),
              decoration: CyberTheme.cyberInput(
                label: 'Enter your 18 words',
                hint: 'word1 word2 word3...',
                icon: Icons.keyboard_rounded,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your passphrase';
                }
                final cleaned = value.trim().replaceAll(RegExp(r'\s+'), ' ');
                if (cleaned != _generatedMnemonic) {
                  return 'Incorrect passphrase. Please try again.';
                }
                return null;
              },
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  ref
                      .read(signupFlowProvider.notifier)
                      .setPassphrase(_generatedMnemonic);
                  ref.read(signupFlowProvider.notifier).nextStep();
                }
              },
              style: CyberTheme.neonButton(CyberTheme.neonPurple),
              child: const Text('Verify & Continue'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () =>
                  setState(() => _phase = PassphrasePhase.generation),
              style: TextButton.styleFrom(
                foregroundColor: CyberTheme.textSecondary,
              ),
              child: const Text('Go back to view phrase again'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SLIP-39 SCREENS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSlip39SharesDisplay() {
    if (_slip39Shares.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: CyberTheme.neonCyan),
      );
    }

    final flowState = ref.watch(signupFlowProvider);
    final total = flowState.slip39TotalShares;
    final threshold = flowState.slip39Threshold;
    final allConfirmed = _slip39Confirmed.every((c) => c);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.hub_rounded, size: 56, color: CyberTheme.neonCyan),
          const SizedBox(height: 16),
          Text(
            'Your SLIP-39 Shares',
            style: CyberTheme.heading(size: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Your seed is split into $total pieces. You need $threshold of them to recover your wallet. Write each share on a separate piece of paper and store them in different locations.',
            style: CyberTheme.label(size: 14, color: CyberTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Share progress indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(total, (i) {
              final confirmed = _slip39Confirmed[i];
              return GestureDetector(
                onTap: () {
                  _slip39PageController.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: confirmed ? 28 : 20,
                  height: 28,
                  decoration: BoxDecoration(
                    color: confirmed
                        ? CyberTheme.neonCyan.withValues(alpha: 0.2)
                        : CyberTheme.bgCard,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: confirmed
                          ? CyberTheme.neonCyan
                          : CyberTheme.border,
                      width: confirmed ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: confirmed
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: CyberTheme.neonCyan,
                          )
                        : Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: CyberTheme.textSecondary,
                            ),
                          ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // PageView of shares
          SizedBox(
            height: 300,
            child: PageView.builder(
              controller: _slip39PageController,
              onPageChanged: (i) => setState(() => _currentSlip39Page = i),
              itemCount: total,
              itemBuilder: (ctx, i) {
                final words = _slip39Shares[i];
                final isConfirmed = _slip39Confirmed[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: CyberTheme.bgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isConfirmed
                                ? CyberTheme.neonCyan
                                : CyberTheme.border,
                          ),
                          boxShadow: isConfirmed
                              ? CyberTheme.subtleGlow(CyberTheme.neonCyan)
                              : [],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Share ${i + 1} of $total',
                                  style: const TextStyle(
                                    color: CyberTheme.neonCyan,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: words.join(' ')),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Share ${i + 1} copied'),
                                        backgroundColor: CyberTheme.neonCyan
                                            .withValues(alpha: 0.8),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.copy,
                                    size: 18,
                                    color: CyberTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              words.join(' '),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 13,
                                color: CyberTheme.neonCyan,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (!isConfirmed)
                        OutlinedButton.icon(
                          onPressed: () =>
                              setState(() => _verifyingShareIndex = i),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: CyberTheme.neonAmber),
                            foregroundColor: CyberTheme.neonAmber,
                          ),
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: Text('I wrote down Share ${i + 1} — Verify'),
                        )
                      else
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: CyberTheme.neonCyan,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Share confirmed!',
                              style: TextStyle(color: CyberTheme.neonCyan),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),
          Text(
            '${_currentSlip39Page + 1} / $total',
            style: const TextStyle(color: CyberTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _warningRow(
            'Do NOT store all shares in the same place. If an attacker finds $threshold pieces they can recover your wallet.',
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: allConfirmed
                ? () => ref.read(signupFlowProvider.notifier).nextStep()
                : null,
            style: CyberTheme.neonButton(CyberTheme.neonCyan),
            child: Text(
              allConfirmed
                  ? 'All Shares Confirmed — Continue'
                  : 'Confirm all $total shares to continue',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlip39ShareVerification() {
    final i = _verifyingShareIndex;
    final expectedWords = _slip39Shares[i];
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Form(
        key: _slip39FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.fact_check_rounded,
              size: 56,
              color: CyberTheme.neonAmber,
            ),
            const SizedBox(height: 16),
            Text(
              'Verify Share ${i + 1}',
              style: CyberTheme.heading(size: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Type the words for Share ${i + 1} exactly as you wrote them down.',
              style: CyberTheme.label(
                size: 14,
                color: CyberTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _slip39VerifyController,
              maxLines: 6,
              style: GoogleFonts.jetBrainsMono(
                color: CyberTheme.textPrimary,
                fontSize: 13,
              ),
              decoration: CyberTheme.cyberInput(
                label: 'Enter the words',
                hint: 'word1 word2 word3...',
                icon: Icons.keyboard_rounded,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the share words';
                }
                final cleaned = value.trim().replaceAll(RegExp(r'\s+'), ' ');
                if (cleaned != expectedWords.join(' ')) {
                  return 'Incorrect. Please re-check what you wrote.';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                if (_slip39FormKey.currentState!.validate()) {
                  setState(() {
                    _slip39Confirmed[i] = true;
                    _verifyingShareIndex = -1;
                    _slip39VerifyController.clear();
                  });
                }
              },
              style: CyberTheme.neonButton(CyberTheme.neonAmber),
              child: Text('Confirm Share ${i + 1}'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _verifyingShareIndex = -1),
              style: TextButton.styleFrom(
                foregroundColor: CyberTheme.textSecondary,
              ),
              child: const Text('Go back to view shares'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2FA MULTISIG SCREENS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _build2FAPhase() {
    if (twoFaPhase == 0) {
      return _build2FAPrimarySeed();
    }
    if (twoFaPhase == 1) {
      return _build2FABackupSeed();
    }
    return _build2FAVerification();
  }

  Widget _build2FAPrimarySeed() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.security_rounded,
            size: 56,
            color: CyberTheme.neonPurple,
          ),
          const SizedBox(height: 16),
          Text(
            'Your Primary Seed',
            style: CyberTheme.heading(size: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          _badgeRow(
            icon: Icons.lock_person_rounded,
            label: 'Key 1 of 3 — Stays on your device only',
            color: CyberTheme.neonPurple,
          ),
          const SizedBox(height: 16),
          Text(
            'This 18-word phrase is your primary private key. It alone is NOT enough to sign transactions — a secondary TOTP authorization is always required from Kerosene. Write these words on paper and store them securely.',
            style: CyberTheme.label(size: 14, color: CyberTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _mnemonicCard(_primarySeed, CyberTheme.neonPurple),
          const SizedBox(height: 24),
          _warningRow(
            'Never share this phrase with anyone, not even Kerosene support.',
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => setState(() => twoFaPhase = 1),
            style: CyberTheme.neonButton(CyberTheme.neonPurple),
            child: const Text('I Have Written It Down'),
          ),
        ],
      ),
    );
  }

  Widget _build2FABackupSeed() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.backup_rounded,
            size: 56,
            color: CyberTheme.neonAmber,
          ),
          const SizedBox(height: 16),
          Text(
            'Your Recovery Seed',
            style: CyberTheme.heading(size: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          _badgeRow(
            icon: Icons.safety_divider_rounded,
            label: 'Key 3 of 3 — Emergency / Sovereignty Bypass',
            color: CyberTheme.neonAmber,
          ),
          const SizedBox(height: 16),
          Text(
            'This is your sovereignty guarantee. If Kerosene ever shuts down, use this 12-word backup seed together with your primary seed to recover your funds without any server involvement. Store this SEPARATELY from your primary seed.',
            style: CyberTheme.label(size: 14, color: CyberTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _mnemonicCard(_backupSeed, CyberTheme.neonAmber),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: CyberTheme.neonAmber),
              borderRadius: BorderRadius.circular(8),
              color: CyberTheme.neonAmber.withValues(alpha: 0.05),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.account_balance_rounded,
                  color: CyberTheme.neonAmber,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Key 2 of 3 is held encrypted by Kerosene and is only used to co-sign trasactions when you provide a valid TOTP code.',
                    style: TextStyle(color: CyberTheme.neonAmber, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => setState(() => twoFaPhase = 2),
            style: CyberTheme.neonButton(CyberTheme.neonAmber),
            child: const Text('I Have Stored Both Seeds'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => twoFaPhase = 0),
            style: TextButton.styleFrom(
              foregroundColor: CyberTheme.textSecondary,
            ),
            child: const Text('Back to Primary Seed'),
          ),
        ],
      ),
    );
  }

  Widget _build2FAVerification() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.fact_check_rounded,
              size: 56,
              color: CyberTheme.neonPurple,
            ),
            const SizedBox(height: 16),
            Text(
              'Verify Primary Seed',
              style: CyberTheme.heading(size: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Confirm your Primary Key (18 words) to prove you have it safely stored.',
              style: CyberTheme.label(
                size: 14,
                color: CyberTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _verificationController,
              maxLines: 4,
              style: GoogleFonts.jetBrainsMono(
                color: CyberTheme.textPrimary,
                fontSize: 14,
              ),
              decoration: CyberTheme.cyberInput(
                label: 'Enter your 18-word Primary Seed',
                hint: 'word1 word2 word3...',
                icon: Icons.keyboard_rounded,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your primary seed';
                }
                final cleaned = value.trim().replaceAll(RegExp(r'\s+'), ' ');
                if (cleaned != _primarySeed) {
                  return 'Incorrect. Please re-check your Primary Seed.';
                }
                return null;
              },
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  ref
                      .read(signupFlowProvider.notifier)
                      .setPassphrase(_primarySeed);
                  ref.read(signupFlowProvider.notifier).nextStep();
                }
              },
              style: CyberTheme.neonButton(CyberTheme.neonPurple),
              child: const Text('Verify & Activate 2FA Vault'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => twoFaPhase = 1),
              style: TextButton.styleFrom(
                foregroundColor: CyberTheme.textSecondary,
              ),
              child: const Text('Back to Recovery Seed'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Shared widgets ───────────────────────────────────────────────────────

  Widget _mnemonicCard(String mnemonic, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CyberTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CyberTheme.border),
        boxShadow: CyberTheme.subtleGlow(color),
      ),
      child: Text(
        mnemonic,
        textAlign: TextAlign.center,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 15,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _warningRow(String message) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          color: CyberTheme.neonAmber,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: CyberTheme.neonAmber.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }

  Widget _badgeRow({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
