import 'package:flutter/widgets.dart';
import 'package:teste/l10n/l10n_extension.dart';

class SafeDisplayText {
  SafeDisplayText._();

  static String unavailable(BuildContext context) {
    return context.l10n.apiDisplayInformationUnavailable;
  }

  static String addressUnavailable(BuildContext context) {
    return context.l10n.apiDisplayAddressUnavailable;
  }

  static String maskAddress(
    String? value, {
    int leading = 8,
    int trailing = 6,
  }) {
    return maskIdentifier(value, leading: leading, trailing: trailing);
  }

  static String maskInvoice(String? value) {
    return maskIdentifier(value, leading: 8, trailing: 6);
  }

  static String maskTxid(String? value) {
    return maskIdentifier(value, leading: 10, trailing: 8);
  }

  static String maskIdentifier(
    String? value, {
    int leading = 8,
    int trailing = 6,
  }) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return '';
    }
    final visibleLength = leading + trailing + 3;
    if (normalized.length <= visibleLength) {
      return normalized;
    }
    return '${normalized.substring(0, leading)}...${normalized.substring(normalized.length - trailing)}';
  }

  static String displayIdentifier(
    BuildContext context,
    String? value, {
    int leading = 8,
    int trailing = 6,
  }) {
    final masked = maskIdentifier(
      value,
      leading: leading,
      trailing: trailing,
    );
    return masked.isEmpty ? unavailable(context) : masked;
  }

  static String displayAddress(BuildContext context, String? value) {
    final masked = maskAddress(value);
    return masked.isEmpty ? addressUnavailable(context) : masked;
  }
}
