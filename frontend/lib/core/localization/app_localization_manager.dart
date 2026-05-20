import 'dart:ui' show Locale, PlatformDispatcher;

class AppLocalizationManager {
  const AppLocalizationManager._();

  static const Locale fallbackLocale = Locale('en');
  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
    Locale('es'),
  ];

  static const supportedLanguageCodes = {'en', 'pt', 'es'};

  static Locale resolve(Locale? requested) {
    final languageCode = requested?.languageCode.toLowerCase();
    if (languageCode != null && supportedLanguageCodes.contains(languageCode)) {
      return Locale(languageCode);
    }
    return fallbackLocale;
  }

  static Locale deviceOrFallback() {
    return resolve(PlatformDispatcher.instance.locale);
  }
}
