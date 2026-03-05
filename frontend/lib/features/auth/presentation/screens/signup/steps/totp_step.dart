import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';

import '../../../../../../core/theme/cyber_theme.dart';
import '../../../../../../core/presentation/widgets/animated_loading_button.dart';
import '../../../../../../core/utils/totp_util.dart';
import '../../../../../../l10n/l10n_extension.dart';
import '../../../providers/signup_flow_provider.dart';
import 'package:teste/features/auth/presentation/providers/auth_provider.dart';

class TotpStep extends ConsumerStatefulWidget {
  const TotpStep({super.key});

  @override
  ConsumerState<TotpStep> createState() => _TotpStepState();
}

class _TotpStepState extends ConsumerState<TotpStep> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late String _secret;

  @override
  void initState() {
    super.initState();
    // Use secret and qrCodeUri from flow state (populated by API in SignupFlowScreen)
    final flowState = ref.read(signupFlowProvider);
    _secret = flowState.totpSecret ?? 'ERROR_NO_SECRET';
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(signupFlowProvider);
    final qrData =
        flowState.qrCodeUri ?? 'otpauth://totp/ERROR?secret=$_secret';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Icon(
              Icons.security_rounded,
              size: 56,
              color: CyberTheme.neonCyan,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.totpTitle,
              style: CyberTheme.heading(size: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.totpSubtitle,
              style: CyberTheme.label(
                size: 14,
                color: CyberTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: CyberTheme.subtleGlow(CyberTheme.neonCyan),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF050511),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF050511),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _secret,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: CyberTheme.neonCyan,
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.copy,
                    size: 20,
                    color: CyberTheme.textSecondary,
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _secret));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.totpSecretCopied),
                        backgroundColor: CyberTheme.neonCyan.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 48),
            TextFormField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(
                fontSize: 32,
                letterSpacing: 12,
                fontWeight: FontWeight.bold,
                color: CyberTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: context.l10n.totpEnterCodeHint,
                hintStyle: TextStyle(
                  color: CyberTheme.textPrimary.withValues(alpha: 0.1),
                  letterSpacing: 12,
                ),
                filled: true,
                fillColor: CyberTheme.textPrimary.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: CyberTheme.neonCyan,
                    width: 1.5,
                  ),
                ),
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(vertical: 24),
              ),
              validator: (value) {
                if (value == null || value.length != 6) {
                  return context.l10n.totpEnter6Digits;
                }
                if (!TotpUtil.verify(_secret, value)) {
                  return context.l10n.totpInvalidCode;
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: AnimatedLoadingButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final flowState = ref.read(signupFlowProvider);
                    await ref
                        .read(authProvider.notifier)
                        .verifyTotp(
                          username: flowState.username ?? '',
                          passphrase: flowState.passphrase ?? '',
                          totpSecret: _secret,
                          totpCode: _codeController.text,
                        );
                  }
                },
                text: context.l10n.totpVerifyContinue,
                loadingTexts: [
                  context.l10n.totpVerifying,
                  context.l10n.totpAuthenticating,
                  context.l10n.totpEstablishingSession,
                ],
                baseColor: CyberTheme.neonCyan,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
