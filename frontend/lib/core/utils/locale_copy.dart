import 'package:flutter/widgets.dart';

String localeCopy(
  BuildContext context, {
  required String pt,
  required String en,
  required String es,
}) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'en':
      return en;
    case 'es':
      return es;
    default:
      return pt;
  }
}
