import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Luxury QR Deposit Screen — matches Figma "Luxury QR Deposit Screen"
/// Shown after user taps "Continue" on the Receive/Enter Amount screen.
class LuxuryQrDepositScreen extends StatelessWidget {
  final String address;
  final double? amountBtc;
  final String networkLabel;

  const LuxuryQrDepositScreen({
    super.key,
    required this.address,
    this.amountBtc,
    this.networkLabel = 'LIGHTNING NETWORK',
  });

  String get _qrData {
    if (amountBtc != null && amountBtc! > 0) {
      return 'bitcoin:$address?amount=${amountBtc!.toStringAsFixed(8)}';
    }
    return 'bitcoin:$address';
  }

  String get _shortAddress {
    if (address.length > 16) {
      return '${address.substring(0, 8)}...${address.substring(address.length - 8)}';
    }
    return address;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0C), // Dark base from image
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    if (amountBtc != null && amountBtc! > 0)
                      _buildAmountHeader(),
                    const SizedBox(height: 24),
                    _buildQrCard(),
                    const SizedBox(height: 32),
                    _buildSubtitles(),
                    const SizedBox(height: 32),
                    _buildAddressSection(context),
                    const SizedBox(height: 24),
                    _buildActionRow(context),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
            _buildSetAmountButton(context),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const Text(
            'Receive BTC',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 24), // Balance spacing
        ],
      ),
    );
  }

  Widget _buildAmountHeader() {
    return Text(
      amountBtc!.toStringAsFixed(8),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 40,
        fontWeight: FontWeight.w300,
        fontFamily: 'Inter',
        letterSpacing: -1.0,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildQrCard() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32), // Highly rounded
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A5CFF).withOpacity(0.15),
              blurRadius: 40,
              spreadRadius: 0,
            ),
          ],
        ),
        child: QrImageView(
          data: _qrData,
          version: QrVersions.auto,
          size: 240,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: Color(0xFF000000),
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Color(0xFF000000),
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitles() {
    return Column(
      children: [
        const Text(
          'Scan to receive Bitcoin',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Only send Bitcoin (BTC) to this address.\nSending other assets will result in permanent loss.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAddressSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR BTC ADDRESS',
          style: TextStyle(
            color: Colors.white.withOpacity(0.35),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.only(left: 16, right: 6, top: 6, bottom: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04), // Dark pill container
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _shortAddress,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: address));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Address copied!',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: const Color(0xFF1A5CFF),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A5CFF), // Blue copy button
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.copy_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSecondaryActionButton(
            icon: Icons.ios_share_rounded,
            label: 'Share',
            onTap: () {
              // Share address logic
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSecondaryActionButton(
            icon: Icons.download_rounded,
            label: 'Save',
            onTap: () {
              // Save QR logic
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetAmountButton(BuildContext context) {
    if (amountBtc != null && amountBtc! > 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A5CFF), // Royal Blue
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          onPressed: () {
            // Usually returns to amount screen or pops
            Navigator.pop(context);
          },
          child: const Text(
            'Set Amount',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
