import 'package:flutter/widgets.dart';

class LocalizedCopy {
  final String en;
  final String pt;
  final String es;

  const LocalizedCopy({
    required this.en,
    required this.pt,
    required this.es,
  });
}

extension LocalizedCopyX on LocalizedCopy {
  String resolve(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'pt':
        return pt;
      case 'es':
        return es;
      case 'en':
      default:
        return en;
    }
  }
}
