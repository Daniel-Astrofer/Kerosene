import 'package:flutter/widgets.dart';
import 'package:teste/l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  /// Retorna as strings baseadas no locale atual do context.
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
