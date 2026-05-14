import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerOverlay extends StatefulWidget {
  final Function(String) onScan;
  final VoidCallback onClose;

  const QrScannerOverlay({
    super.key,
    required this.onScan,
    required this.onClose,
  });

  @override
  State<QrScannerOverlay> createState() => _QrScannerOverlayState();
}

class _QrScannerOverlayState extends State<QrScannerOverlay> {
  MobileScannerController controller = MobileScannerController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
      child: Stack(
        children: [
          // Scanner
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  widget.onScan(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // Scanning Frame / Overlay UI
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.onPrimary, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Decorative corners could be added here
                ],
              ),
            ),
          ),

          // Glassmorphic Footer with Close Button
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Scan a QR Code',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Align the QR code within the frame to scan',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: widget.onClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Actions Row (Flash, Camera Flip)
          Positioned(
            top: 50,
            right: 20,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.flash_on, color: Theme.of(context).colorScheme.onPrimary),
                  onPressed: () => controller.toggleTorch(),
                ),
                IconButton(
                  icon: Icon(Icons.cameraswitch, color: Theme.of(context).colorScheme.onPrimary),
                  onPressed: () => controller.switchCamera(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
