import 'package:flutter/material.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';

class InternalRecentAvatar extends StatelessWidget {
  final String title;
  final double size;
  final double fontSize;

  const InternalRecentAvatar({
    super.key,
    required this.title,
    this.size = 48,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _initialsFor(title);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: KeroseneBrandTokens.surfaceHigh,
        border: Border.all(
          color: KeroseneBrandTokens.textPrimary.withValues(alpha: 0.10),
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: KeroseneBrandTokens.textPrimary,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
        ),
      ),
    );
  }

  String _initialsFor(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+')).where((part) {
      return part.trim().isNotEmpty;
    }).toList(growable: false);
    if (parts.length > 1) {
      return '${parts.first.characters.first}${parts[1].characters.first}'
          .toUpperCase();
    }
    return trimmed.characters.take(2).join().toUpperCase();
  }
}
