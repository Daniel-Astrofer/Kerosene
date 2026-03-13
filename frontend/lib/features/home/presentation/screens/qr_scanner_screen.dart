import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  late MobileScannerController _controller;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return; // Evitar múltiplas leituras

    for (final barcode in capture.barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        setState(() {
          _hasScanned = true;
        });

        // Retornar o resultado para quem chamou
        Navigator.of(context).pop(barcode.rawValue);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Câmera ocupando tela inteira
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // Overlay escuro com buraco no centro
          _buildScanOverlay(),

          // Barra superior
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botão Voltar
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    // Título
                    const Text(
                      'Scanner QR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Botões de controle
                    Row(
                      children: [
                        // Flash
                        IconButton(
                          icon: ValueListenableBuilder(
                            valueListenable: _controller,
                            builder: (context, state, child) {
                              return Icon(
                                state.torchState == TorchState.on
                                    ? Icons.flash_on
                                    : Icons.flash_off,
                                color: Colors.white,
                              );
                            },
                          ),
                          onPressed: () => _controller.toggleTorch(),
                        ),
                        // Trocar câmera
                        IconButton(
                          icon: const Icon(
                            Icons.cameraswitch,
                            color: Colors.white,
                          ),
                          onPressed: () => _controller.switchCamera(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Instrução na parte inferior
          Positioned(
            bottom: 80,
            left: 40,
            right: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Aponte a câmera para um código QR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o overlay com o "buraco" transparente no centro
  Widget _buildScanOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanAreaSize = constraints.maxWidth * 0.7;
        final scanAreaTop = (constraints.maxHeight - scanAreaSize) / 2;
        final scanAreaLeft = (constraints.maxWidth - scanAreaSize) / 2;

        return Stack(
          children: [
            // Fundo escuro semitransparente
            ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.black54,
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  // Preenche a tela toda
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  // Buraco transparente
                  Positioned(
                    top: scanAreaTop,
                    left: scanAreaLeft,
                    child: Container(
                      width: scanAreaSize,
                      height: scanAreaSize,
                      decoration: BoxDecoration(
                        color: Colors.red, // Qualquer cor, será cortada
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Borda do scanner
            Positioned(
              top: scanAreaTop,
              left: scanAreaLeft,
              child: Container(
                width: scanAreaSize,
                height: scanAreaSize,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF00D4FF), width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            // Cantos decorativos
            _buildCorner(scanAreaTop, scanAreaLeft, true, true),
            _buildCorner(
              scanAreaTop,
              scanAreaLeft + scanAreaSize - 30,
              true,
              false,
            ),
            _buildCorner(
              scanAreaTop + scanAreaSize - 30,
              scanAreaLeft,
              false,
              true,
            ),
            _buildCorner(
              scanAreaTop + scanAreaSize - 30,
              scanAreaLeft + scanAreaSize - 30,
              false,
              false,
            ),
          ],
        );
      },
    );
  }

  Widget _buildCorner(double top, double left, bool isTop, bool isLeft) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: Color(0xFF00D4FF), width: 4)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: Color(0xFF00D4FF), width: 4)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: Color(0xFF00D4FF), width: 4)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: Color(0xFF00D4FF), width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
