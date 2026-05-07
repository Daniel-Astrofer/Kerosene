import 'package:flutter/material.dart';

List<String> splitBitcoinAddress(
  String address, {
  int chunkSize = 4,
}) {
  final normalized = address.trim();
  if (normalized.isEmpty) {
    return const [];
  }

  final chunks = <String>[];
  for (var index = 0; index < normalized.length; index += chunkSize) {
    final end = (index + chunkSize).clamp(0, normalized.length);
    chunks.add(normalized.substring(index, end));
  }
  return chunks;
}

class BitcoinAddressBlocks extends StatelessWidget {
  final String address;
  final TextStyle? style;
  final Color backgroundColor;
  final Color borderColor;
  final EdgeInsetsGeometry padding;
  final int chunkSize;

  const BitcoinAddressBlocks({
    super.key,
    required this.address,
    this.style,
    this.backgroundColor = const Color(0xFF141414),
    this.borderColor = const Color(0xFF262626),
    this.padding = const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
    this.chunkSize = 4,
  });

  @override
  Widget build(BuildContext context) {
    final chunks = splitBitcoinAddress(address, chunkSize: chunkSize);
    return SelectionArea(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 5,
        runSpacing: 5,
        children: [
          for (final chunk in chunks)
            DecoratedBox(
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border.all(color: borderColor),
              ),
              child: Padding(
                padding: padding,
                child: Text(chunk, style: style),
              ),
            ),
        ],
      ),
    );
  }
}
