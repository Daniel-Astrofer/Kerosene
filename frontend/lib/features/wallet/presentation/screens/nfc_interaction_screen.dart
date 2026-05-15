import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/l10n/l10n_extension.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/utils/snackbar_helper.dart';
import 'package:teste/core/services/audio_service.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import '../../../../core/utils/qr_payment_parser.dart'; // [NEW]

/// Premium NFC Interaction Screen - Refactored
class NfcInteractionScreen extends StatefulWidget {
  final String amountDisplay;
  final String? paymentUri;

  const NfcInteractionScreen({
    super.key,
    required this.amountDisplay,
    this.paymentUri,
  });

  @override
  State<NfcInteractionScreen> createState() => _NfcInteractionScreenState();
}

class _NfcInteractionScreenState extends State<NfcInteractionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;

  String _statusMessage = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_statusMessage.isEmpty) {
      _statusMessage = context.l10n.waitingConnection;
    }
  }

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startNfcSession();
  }

  void _startNfcSession() async {
    final availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) {
      if (mounted) {
        setState(() {
          _statusMessage = context.l10n.nfcUnavailable;
        });
      }
      return;
    }

    NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
      onDiscovered: (NfcTag tag) async {
        if (!mounted) return;
        final l10n = context.l10n;
        setState(() {
          _statusMessage = l10n.processing;
        });

        try {
          if (widget.paymentUri != null) {
            await _writePaymentUri(tag, widget.paymentUri!);
          } else {
            final ndef = Ndef.from(tag);
            final cachedMessage = ndef?.cachedMessage;
            if (cachedMessage == null) {
              _handleError(l10n.nfcTagInvalid);
              return;
            }

            for (final record in cachedMessage.records) {
              final fullUri = _decodeUriRecord(record);
              if (fullUri == null) continue;
              final parsed = QrPaymentParser.decode(fullUri);
              if (parsed != null && parsed.isComplete) {
                _handleSuccessRead(fullUri);
                return;
              }
            }
            _handleError(l10n.nfcPaymentNotFound);
          }
        } catch (_) {
          _handleError(l10n.nfcCouldNotProcess);
        }
      },
    );
  }

  Future<void> _writePaymentUri(NfcTag tag, String paymentUri) async {
    final l10n = context.l10n;
    final ndef = Ndef.from(tag);
    if (ndef == null) {
      _handleError(l10n.nfcTagNotSupported);
      return;
    }
    if (!ndef.isWritable) {
      _handleError(l10n.nfcTagNotWritable);
      return;
    }

    final message = _buildUriMessage(paymentUri);
    if (ndef.maxSize > 0 && message.byteLength > ndef.maxSize) {
      _handleError(l10n.nfcTagCapacityError);
      return;
    }

    await ndef.write(message: message);
    if (!mounted) return;
    _handleSuccess(l10n.nfcTagWrittenSuccess);
  }

  NdefMessage _buildUriMessage(String uri) {
    return NdefMessage(
      records: [
        NdefRecord(
          typeNameFormat: TypeNameFormat.wellKnown,
          type: Uint8List.fromList('U'.codeUnits),
          identifier: Uint8List(0),
          payload: Uint8List.fromList([0x00, ...utf8.encode(uri)]),
        ),
      ],
    );
  }

  String? _decodeUriRecord(NdefRecord record) {
    if (record.typeNameFormat != TypeNameFormat.wellKnown ||
        utf8.decode(record.type, allowMalformed: true) != 'U' ||
        record.payload.isEmpty) {
      return null;
    }

    final prefixIndex = record.payload.first;
    final prefix =
        prefixIndex < _uriPrefixes.length ? _uriPrefixes[prefixIndex] : '';
    final contentBytes = record.payload.skip(1).toList(growable: false);
    return '$prefix${utf8.decode(contentBytes, allowMalformed: true)}';
  }

  static const List<String> _uriPrefixes = [
    '',
    'http://www.',
    'https://www.',
    'http://',
    'https://',
    'tel:',
    'mailto:',
    'ftp://anonymous:anonymous@',
    'ftp://ftp.',
    'ftps://',
    'sftp://',
    'smb://',
    'nfs://',
    'ftp://',
    'dav://',
    'news:',
    'telnet://',
    'imap:',
    'rtsp://',
    'urn:',
    'pop:',
    'sip:',
    'sips:',
    'tftp:',
    'btspp://',
    'btl2cap://',
    'btgoep://',
    'tcpobex://',
    'irdaobex://',
    'file://',
    'urn:epc:id:',
    'urn:epc:tag:',
    'urn:epc:pat:',
    'urn:epc:raw:',
    'urn:epc:',
    'urn:nfc:',
  ];

  void _handleError(String msg) {
    if (!mounted) return;
    NfcManager.instance.stopSession();
    AudioService.instance.playError();
    HapticFeedback.heavyImpact();
    setState(() {
      _statusMessage = msg;
    });
    SnackbarHelper.showError(msg);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _statusMessage = context.l10n.waitingConnection);
        _startNfcSession();
      }
    });
  }

  void _handleSuccess(String msg) {
    if (!mounted) return;
    NfcManager.instance.stopSession();
    AudioService.instance.playTransaction();
    HapticFeedback.vibrate();
    SnackbarHelper.showSuccess(msg);
    Navigator.pop(context, true);
  }

  void _handleSuccessRead(String uri) {
    if (!mounted) return;
    NfcManager.instance.stopSession();
    AudioService.instance.playTransaction();
    HapticFeedback.mediumImpact();
    Navigator.pop(context, uri);
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: authenticatedSurfaceBackgroundColor,
      body: CyberBackground.authenticated(
        useScroll: false,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: AppSpacing.xxl),
              _buildAmount().animate().fade().slideY(begin: 0.1, end: 0.0),
              Expanded(
                child: Center(
                  child: _buildNfcRipple(),
                ).animate().scale(curve: Curves.easeOutBack),
              ),
              _buildInstructions()
                  .animate(delay: 200.ms)
                  .fade()
                  .slideY(begin: 0.1, end: 0.0),
              const SizedBox(height: AppSpacing.xxl),
              _buildCancelButton(
                context,
              ).animate(delay: 400.ms).fade().slideY(begin: 0.2, end: 0.0),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              LucideIcons.x,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 24,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.onPrimary.withValues(alpha: 0.05),
              padding: const EdgeInsets.all(AppSpacing.sm),
            ),
          ),
          Text(
            (widget.paymentUri != null
                ? context.l10n.receive.toUpperCase()
                : context.l10n.send.toUpperCase()),
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  letterSpacing: 4,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(width: 48),
        ],
      ).animate().fade().slideY(begin: -0.2, end: 0.0),
    );
  }

  Widget _buildAmount() {
    return Column(
      children: [
        Text(
          widget.paymentUri != null
              ? context.l10n.amountToReceive.toUpperCase()
              : context.l10n.amount.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onPrimary.withValues(alpha: 0.3),
                letterSpacing: 3,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          "₿ ${widget.amountDisplay}",
          style: Theme.of(context).textTheme.displayLarge!.copyWith(
                fontSize: 56,
                fontWeight: FontWeight.w200,
                letterSpacing: 0,
                color: Theme.of(context).colorScheme.primary,
                fontFamily: 'IBM Plex Mono',
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNfcRipple() {
    return AnimatedBuilder(
      animation: _rippleController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Ripple 1
            Transform.scale(
              scale: 1.0 + (_rippleController.value * 0.8),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(
                          alpha: 0.2 * (1.0 - _rippleController.value),
                        ),
                    width: 2,
                  ),
                ),
              ),
            ),
            // Ripple 2
            Transform.scale(
              scale: 1.0 + (_rippleController.value * 1.6),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(
                          alpha: 0.1 * (1.0 - _rippleController.value),
                        ),
                    width: 1,
                  ),
                ),
              ),
            ),
            // Central Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.05),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Icon(
                LucideIcons.smartphoneNfc,
                color: Theme.of(context).colorScheme.primary,
                size: 56,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInstructions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        children: [
          Text(
            widget.paymentUri != null
                ? "APROXIME PARA COBRAR"
                : "APROXIME PARA PAGAR",
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.nfcInstructions,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withValues(alpha: 0.4),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.3, 1.3),
                    duration: 800.ms,
                  ),
              const SizedBox(width: AppSpacing.md),
              Text(
                _statusMessage,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: InkWell(
        onTap: () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        child: Container(
          width: double.infinity,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.onPrimary.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(AppSpacing.md),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.onPrimary.withValues(alpha: 0.05),
              width: 1.5,
            ),
          ),
          child: Text(
            context.l10n.cancelOperation.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
          ),
        ),
      ),
    );
  }
}
