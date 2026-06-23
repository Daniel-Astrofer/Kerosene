/// Kerosene brand language tokens.
///
/// Use these constants for product surfaces that need stable brand copy.
/// User-visible strings inside app flows should still prefer ARB-backed l10n.
class KeroseneBrand {
  const KeroseneBrand._();

  static const String name = 'Kerosene';

  /// Main brand hook.
  static const String hook = 'Dinheiro privado. Controle sereno.';

  /// Main explanatory subhook.
  static const String subhook =
      'Infraestrutura financeira sobre Bitcoin para receber, guardar e mover valor com discrição.';

  /// B2B acquisition hook.
  static const String b2bHook = 'Receba melhor. Exponha menos.';

  /// B2B explanatory subhook.
  static const String b2bSubhook =
      'Pagamentos privados para empresas que querem reduzir taxas, intermediários e exposição operacional.';

  /// Brand essence for internal guidance and editorial surfaces.
  static const String essence =
      'Privacidade financeira com clareza operacional.';

  /// Short institutional description.
  static const String institutional =
      'Infraestrutura financeira para quem valoriza controle.';

  /// Product promise.
  static const String productPromise =
      'Receba, guarde e mova valor com discrição.';

  /// Bitcoin-specific positioning.
  static const String bitcoinPositioning = 'Trilhos privados sobre Bitcoin.';

  /// Trust-oriented phrase.
  static const String trustLine =
      'Privacidade sem ruído. Controle sem fricção.';
}

/// Centralized vocabulary guidance for Kerosene UX writing.
///
/// These lists are not intended to be rendered directly in production UI.
/// They exist as a design-system reference for linting, review and editorial work.
class KeroseneBrandVocabulary {
  const KeroseneBrandVocabulary._();

  static const List<String> preferred = [
    'controle',
    'discrição',
    'privacidade',
    'clareza',
    'autonomia',
    'infraestrutura',
    'recebimentos',
    'operação',
    'capital',
    'trilhos',
    'custódia',
    'liquidação',
    'proteção',
    'soberania',
    'confidencialidade comercial',
    'minimização de dados',
    'exposição operacional',
  ];

  static const List<String> restricted = [
    'anonimato',
    'ocultar',
    'governo',
    'dinheiro sujo',
    'sem rastreamento',
    'fora do sistema',
    'burlar',
    'evadir',
    'invisível',
    'sem perguntas',
  ];
}
