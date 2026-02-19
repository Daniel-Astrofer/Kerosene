import 'package:flutter/material.dart';
import 'nfc_scan_animation.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import '../../../../core/presentation/widgets/glass_container.dart';

class NfcSearchingOverlay extends StatefulWidget {
  final VoidCallback onCancel;
  final Function(String)? onTagRead;

  const NfcSearchingOverlay({
    super.key,
    required this.onCancel,
    this.onTagRead,
  });

  @override
  State<NfcSearchingOverlay> createState() => _NfcSearchingOverlayState();
}

class _NfcSearchingOverlayState extends State<NfcSearchingOverlay> {
  bool _isNfcAvailable = false;
  bool _isScanning = false;
  String _statusMessage = 'Verificando NFC...';

  @override
  void initState() {
    super.initState();
    _checkNfcAndStart();
  }

  Future<void> _checkNfcAndStart() async {
    try {
      final availability = await NfcManager.instance.checkAvailability();
      final isAvailable = availability == NfcAvailability.enabled;
      if (!mounted) return;

      setState(() {
        _isNfcAvailable = isAvailable;
      });

      if (isAvailable) {
        _startNfcSession();
      } else {
        setState(() {
          _statusMessage =
              'NFC não está disponível neste dispositivo.\nVerifique se o NFC está ativado nas configurações.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Erro ao verificar NFC: $e';
      });
    }
  }

  void _startNfcSession() {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Aproxime o celular de um dispositivo NFC';
    });

    NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
      onDiscovered: (NfcTag tag) async {
        // Extrair dados da tag NFC
        final ndef = Ndef.from(tag);
        String tagData = '';

        if (ndef != null) {
          final cachedMessage = ndef.cachedMessage;
          if (cachedMessage != null) {
            for (final record in cachedMessage.records) {
              tagData += String.fromCharCodes(record.payload);
            }
          }
        }

        if (tagData.isEmpty) {
          tagData = 'Tag NFC detectada!';
        }

        // Parar sessão NFC
        await NfcManager.instance.stopSession();

        if (!mounted) return;

        setState(() {
          _isScanning = false;
          _statusMessage = 'Tag NFC lida com sucesso!';
        });

        widget.onTagRead?.call(tagData);

        // Fechar overlay após 1 segundo
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) widget.onCancel();
      },
    );
  }

  @override
  void dispose() {
    if (_isScanning) {
      NfcManager.instance.stopSession();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: GlassContainer(
            borderRadius: BorderRadius.circular(32),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 40.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animação NFC (Programática - Melhor Performance)
                  const NfcScanAnimation(size: 200),
                  const SizedBox(height: 24),

                  // Status
                  Text(
                    _isScanning
                        ? 'Buscando dispositivos...'
                        : _isNfcAvailable
                        ? 'NFC Pronto'
                        : 'NFC Indisponível',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  Text(
                    _statusMessage,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Indicador de progresso se escaneando
                  if (_isScanning) ...[
                    const SizedBox(height: 20),
                    const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  // Botão Cancelar
                  ElevatedButton(
                    onPressed: widget.onCancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
