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

/// Central source for copy that has not yet been migrated to ARB-backed l10n.
///
/// English is the canonical source language. UI code should reference entries
/// here instead of embedding visible strings directly in widgets.
class AppCopy {
  AppCopy._();

  static const signupUsernameValidationRequired = LocalizedCopy(
    en: 'Username is required.',
    pt: 'O nome de usuário é obrigatório.',
    es: 'El nombre de usuario es obligatorio.',
  );
  static const signupUsernameValidationMin = LocalizedCopy(
    en: 'Use at least 3 characters.',
    pt: 'Use pelo menos 3 caracteres.',
    es: 'Usa al menos 3 caracteres.',
  );
  static const signupUsernameValidationMax = LocalizedCopy(
    en: 'Use up to 15 characters.',
    pt: 'Use no máximo 15 caracteres.',
    es: 'Usa como máximo 15 caracteres.',
  );
  static const signupUsernameValidationCharset = LocalizedCopy(
    en: 'Use only lowercase letters, numbers, and "_".',
    pt: 'Use apenas letras minúsculas, números e "_".',
    es: 'Usa solo letras minúsculas, números y "_".',
  );
  static const signupUsernamePreviewPlaceholder = LocalizedCopy(
    en: 'your_handle',
    pt: 'nome_da_conta',
    es: 'tu_usuario',
  );
  static const signupUsernameEyebrow = LocalizedCopy(
    en: 'Identity',
    pt: 'Identidade',
    es: 'Identidad',
  );
  static const signupUsernameTitle = LocalizedCopy(
    en: 'Choose how you will sign in',
    pt: 'Escolha como você vai entrar',
    es: 'Elige cómo vas a iniciar sesión',
  );
  static const signupUsernameSubtitle = LocalizedCopy(
    en: 'Use a short, simple name that is easy to remember. We automatically clean spaces, uppercase letters, and symbols to reduce friction.',
    pt: 'Use um nome curto, simples e fácil de lembrar. Nós limpamos espaços, maiúsculas e símbolos automaticamente para reduzir atrito.',
    es: 'Usa un nombre corto, simple y fácil de recordar. Limpiamos espacios, mayúsculas y símbolos automáticamente para reducir fricción.',
  );
  static const signupUsernameHighlightLabel = LocalizedCopy(
    en: 'Preview',
    pt: 'Pré-visualização',
    es: 'Vista previa',
  );
  static const signupUsernameHighlightReady = LocalizedCopy(
    en: 'Format is ready to continue.',
    pt: 'Formato pronto para seguir.',
    es: 'El formato está listo para continuar.',
  );
  static const signupUsernameHighlightPending = LocalizedCopy(
    en: 'Use 3 to 15 characters.',
    pt: 'Use de 3 a 15 caracteres.',
    es: 'Usa de 3 a 15 caracteres.',
  );
  static const signupUsernameChipLength = LocalizedCopy(
    en: '3 to 15 characters',
    pt: '3 a 15 caracteres',
    es: '3 a 15 caracteres',
  );
  static const signupUsernameChipCharset = LocalizedCopy(
    en: 'a-z and 0-9',
    pt: 'a-z e 0-9',
    es: 'a-z y 0-9',
  );
  static const signupUsernameChipUnderscore = LocalizedCopy(
    en: 'underscore allowed',
    pt: 'underscore permitido',
    es: 'guion bajo permitido',
  );
  static const signupUsernameLabel = LocalizedCopy(
    en: 'Username',
    pt: 'Nome de usuário',
    es: 'Nombre de usuario',
  );
  static const signupUsernameHint = LocalizedCopy(
    en: '@your_handle',
    pt: '@seu_usuario',
    es: '@tu_usuario',
  );
  static const signupUsernameGenerateTooltip = LocalizedCopy(
    en: 'Generate automatically',
    pt: 'Gerar automaticamente',
    es: 'Generar automáticamente',
  );
  static const signupUsernameValidTag = LocalizedCopy(
    en: 'Valid format',
    pt: 'Formato válido',
    es: 'Formato válido',
  );
  static const signupUsernameAdjustTag = LocalizedCopy(
    en: 'Adjust the format',
    pt: 'Ajuste o formato',
    es: 'Ajusta el formato',
  );
  static const signupUsernameNoSpaces = LocalizedCopy(
    en: 'No spaces',
    pt: 'Sem espaços',
    es: 'Sin espacios',
  );
  static const signupUsernameNoUppercase = LocalizedCopy(
    en: 'No uppercase letters',
    pt: 'Sem maiúsculas',
    es: 'Sin mayúsculas',
  );
  static const signupUsernameSpeedTitle = LocalizedCopy(
    en: 'Want to speed it up?',
    pt: 'Quer acelerar?',
    es: '¿Quieres acelerar?',
  );
  static const signupUsernameSpeedBody = LocalizedCopy(
    en: 'We can generate a suggestion and you can edit it if you want.',
    pt: 'Geramos uma sugestão e você edita se quiser.',
    es: 'Podemos generar una sugerencia y puedes editarla si quieres.',
  );
  static const signupUsernameSuggestNow = LocalizedCopy(
    en: 'Suggest a name now',
    pt: 'Sugerir um nome agora',
    es: 'Sugerir un nombre ahora',
  );
  static const signupUsernameNoticeTitle = LocalizedCopy(
    en: 'Clarity first',
    pt: 'Clareza primeiro',
    es: 'Claridad primero',
  );
  static const signupUsernameNoticeBody = LocalizedCopy(
    en: 'This name will be used for sign in and as your identity inside the platform. Prefer something easy to recognize later.',
    pt: 'Esse nome será usado no login e na sua identificação dentro da plataforma. Prefira algo fácil de reconhecer depois.',
    es: 'Este nombre se usará para iniciar sesión y como tu identidad dentro de la plataforma. Prefiere algo fácil de reconocer después.',
  );
  static const signupUsernameContinue = LocalizedCopy(
    en: 'Continue with this username',
    pt: 'Continuar com este nome',
    es: 'Continuar con este nombre',
  );

  static const signupHardwareEyebrow = LocalizedCopy(
    en: 'Device security',
    pt: 'Segurança do aparelho',
    es: 'Seguridad del dispositivo',
  );
  static const signupHardwareTitle = LocalizedCopy(
    en: 'Protect this device with biometrics',
    pt: 'Proteja este aparelho com biometria',
    es: 'Protege este dispositivo con biometría',
  );
  static const signupHardwareSubtitle = LocalizedCopy(
    en: 'The account only moves forward when this device registers a passkey. This keeps security visible without adding extra menus.',
    pt: 'A conta só avança quando este aparelho registra uma passkey. Isso deixa a segurança visível sem adicionar menus extras.',
    es: 'La cuenta solo avanza cuando este dispositivo registra una passkey. Esto hace visible la seguridad sin añadir menús extra.',
  );
  static const signupHardwareHighlightLabel = LocalizedCopy(
    en: 'What will be enabled',
    pt: 'O que será ativado',
    es: 'Qué se activará',
  );
  static const signupHardwareHighlightValue = LocalizedCopy(
    en: 'Passkey on this device',
    pt: 'Passkey neste aparelho',
    es: 'Passkey en este dispositivo',
  );
  static const signupHardwareHighlightHint = LocalizedCopy(
    en: 'Confirmation uses biometrics or the system local lock.',
    pt: 'A confirmação usa biometria ou o bloqueio local do sistema.',
    es: 'La confirmación usa biometría o el bloqueo local del sistema.',
  );
  static const signupHardwareChipBiometric = LocalizedCopy(
    en: 'Biometrics',
    pt: 'Biometria',
    es: 'Biometría',
  );
  static const signupHardwareChipDeviceLock = LocalizedCopy(
    en: 'System lock',
    pt: 'Bloqueio local',
    es: 'Bloqueo local',
  );
  static const signupHardwareChipSaferAccess = LocalizedCopy(
    en: 'Safer access',
    pt: 'Acesso mais seguro',
    es: 'Acceso más seguro',
  );
  static const signupHardwareBenefitExposure = LocalizedCopy(
    en: 'Reduces misuse risk, even if the main recovery phrase is exposed.',
    pt: 'Reduz o risco de uso indevido, mesmo se a frase principal for exposta.',
    es: 'Reduce el riesgo de uso indebido, incluso si la frase principal queda expuesta.',
  );
  static const signupHardwareBenefitBinding = LocalizedCopy(
    en: 'The passkey stays bound to this device hardware.',
    pt: 'A passkey fica vinculada ao hardware deste aparelho.',
    es: 'La passkey queda vinculada al hardware de este dispositivo.',
  );
  static const signupHardwareBenefitLock = LocalizedCopy(
    en: 'Confirmation uses biometrics or the system local lock.',
    pt: 'A confirmação usa biometria ou o bloqueio local do sistema.',
    es: 'La confirmación usa biometría o el bloqueo local del sistema.',
  );
  static const signupHardwareNoticeTitle = LocalizedCopy(
    en: 'Continuous trust',
    pt: 'Confiança contínua',
    es: 'Confianza continua',
  );
  static const signupHardwareNoticeBody = LocalizedCopy(
    en: 'Once the passkey is created successfully, signup is complete.',
    pt: 'Quando a passkey for criada com sucesso, o cadastro estará concluído.',
    es: 'Cuando la passkey se cree con éxito, el registro estará completo.',
  );
  static const signupHardwareCta = LocalizedCopy(
    en: 'Bind this device',
    pt: 'Vincular este dispositivo',
    es: 'Vincular este dispositivo',
  );

  static const signupPaymentSecurityLabelMultisig = LocalizedCopy(
    en: 'Multisig Vault',
    pt: 'Cofre Multisig',
    es: 'Bóveda Multisig',
  );
  static const signupPaymentSecurityLabelStandard = LocalizedCopy(
    en: 'Standard',
    pt: 'Padrão',
    es: 'Estándar',
  );
  static const signupPaymentSecuritySummarySlip39 = LocalizedCopy(
    en: 'Backup split into parts, with recovery only when enough parts are together.',
    pt: 'Backup dividido em partes, com recuperacao apenas quando houver partes suficientes.',
    es: 'Respaldo dividido en partes, con recuperacion solo cuando haya partes suficientes.',
  );
  static const signupPaymentSecuritySummaryMultisig = LocalizedCopy(
    en: 'A stronger custody model for operations with stricter process requirements.',
    pt: 'Custódia mais robusta para operações com processo mais rígido.',
    es: 'Un modelo de custodia más robusto para operaciones con mayor rigor.',
  );
  static const signupPaymentSecuritySummaryStandard = LocalizedCopy(
    en: 'Best balance between simplicity, compatibility, and security.',
    pt: 'Melhor equilíbrio entre simplicidade, compatibilidade e segurança.',
    es: 'Mejor equilibrio entre simplicidad, compatibilidad y seguridad.',
  );
  static const signupPaymentEyebrow = LocalizedCopy(
    en: 'Next step',
    pt: 'Próximo passo',
    es: 'Siguiente paso',
  );
  static const signupPaymentTitle = LocalizedCopy(
    en: 'Prepare your secure access',
    pt: 'Preparar seu acesso seguro',
    es: 'Preparar tu acceso seguro',
  );
  static const signupPaymentSubtitle = LocalizedCopy(
    en: 'Before the authenticator is unlocked, the system prepares your initial credentials. You move automatically to 2FA when it finishes.',
    pt: 'Antes de liberar o autenticador, o sistema prepara suas credenciais iniciais. Você segue automaticamente para o 2FA quando isso terminar.',
    es: 'Antes de liberar el autenticador, el sistema prepara tus credenciales iniciales. Pasas automáticamente al 2FA cuando termine.',
  );
  static const signupPaymentHighlightLabel = LocalizedCopy(
    en: 'Selected protection',
    pt: 'Proteção escolhida',
    es: 'Protección elegida',
  );
  static const signupPaymentChip2fa = LocalizedCopy(
    en: '2FA next',
    pt: '2FA em seguida',
    es: '2FA a continuación',
  );
  static const signupPaymentChipPasskey = LocalizedCopy(
    en: 'Passkey required',
    pt: 'Passkey obrigatória',
    es: 'Passkey obligatoria',
  );
  static const signupPaymentChipActivation = LocalizedCopy(
    en: 'Activation later',
    pt: 'Ativação depois',
    es: 'Activación después',
  );
  static const signupPaymentReviewUsernameLabel = LocalizedCopy(
    en: 'Username',
    pt: 'Nome de usuário',
    es: 'Nombre de usuario',
  );
  static const signupPaymentReviewUsernameHint = LocalizedCopy(
    en: 'This identifier will be used at sign in.',
    pt: 'Esse identificador será usado no login.',
    es: 'Este identificador se usará para iniciar sesión.',
  );
  static const signupPaymentReviewProtectionLabel = LocalizedCopy(
    en: 'How you will protect your account',
    pt: 'Como você vai guardar sua conta',
    es: 'Cómo protegerás tu cuenta',
  );
  static const signupPaymentSectionTitle = LocalizedCopy(
    en: 'What happens next',
    pt: 'O que acontece agora',
    es: 'Qué ocurre ahora',
  );
  static const signupPaymentStepPrepareTitle = LocalizedCopy(
    en: 'Your device prepares the account',
    pt: 'O aparelho prepara a conta',
    es: 'El dispositivo prepara la cuenta',
  );
  static const signupPaymentStepPrepareBody = LocalizedCopy(
    en: 'There is a quick technical step before the authenticator is released.',
    pt: 'Existe uma etapa técnica rápida antes de liberar o autenticador.',
    es: 'Hay un paso técnico rápido antes de liberar el autenticador.',
  );
  static const signupPaymentStepTotpTitle = LocalizedCopy(
    en: 'You store your 2FA',
    pt: 'Você salva o 2FA',
    es: 'Guardas tu 2FA',
  );
  static const signupPaymentStepTotpBody = LocalizedCopy(
    en: 'QR code, secret, and backup codes appear on the next step.',
    pt: 'QR Code, segredo e códigos de backup aparecem na etapa seguinte.',
    es: 'El código QR, el secreto y los códigos de respaldo aparecen en el siguiente paso.',
  );
  static const signupPaymentStepPasskeyTitle = LocalizedCopy(
    en: 'Then you protect this device',
    pt: 'Depois você protege este aparelho',
    es: 'Luego proteges este dispositivo',
  );
  static const signupPaymentStepPasskeyBody = LocalizedCopy(
    en: 'The account is only ready when biometrics or device lock are linked.',
    pt: 'A conta só fica pronta quando biometria ou bloqueio local estiverem vinculados.',
    es: 'La cuenta solo queda lista cuando la biometría o el bloqueo local quedan vinculados.',
  );
  static const signupPaymentNoticeTitle = LocalizedCopy(
    en: 'Less reading, more action',
    pt: 'Menos leitura, mais ação',
    es: 'Menos lectura, más acción',
  );
  static const signupPaymentNoticeBody = LocalizedCopy(
    en: 'The app performs this protection check automatically and continues when it finishes.',
    pt: 'O app faz essa verificacao de protecao automaticamente e continua quando terminar.',
    es: 'La app hace esta verificacion de proteccion automaticamente y continua cuando termine.',
  );
  static const signupPaymentCta = LocalizedCopy(
    en: 'Continue and prepare the account',
    pt: 'Continuar e preparar a conta',
    es: 'Continuar y preparar la cuenta',
  );

  static const presentationPrivacyEyebrow = LocalizedCopy(
    en: 'PRIVACY BY DEFAULT',
    pt: 'PRIVACIDADE DESDE O INÍCIO',
    es: 'PRIVACIDAD DESDE EL INICIO',
  );
  static const presentationPrivacyTitle = LocalizedCopy(
    en: 'Your account starts on infrastructure designed to reduce exposure.',
    pt: 'Sua conta começa em uma infraestrutura pensada para reduzir exposição.',
    es: 'Tu cuenta comienza en una infraestructura pensada para reducir la exposición.',
  );
  static const presentationPrivacySummary = LocalizedCopy(
    en: 'Kerosene prioritizes onion routing, a smaller attack surface, and clearer risk visibility from the first access.',
    pt: 'A Kerosene prioriza roteamento onion, menor superfície exposta e uma leitura mais clara do risco desde o primeiro acesso.',
    es: 'Kerosene prioriza enrutamiento onion, una superficie de ataque menor y una lectura de riesgo más clara desde el primer acceso.',
  );
  static const presentationPrivacyHighlightOnion = LocalizedCopy(
    en: 'Onion routing enabled by default',
    pt: 'Roteamento onion habilitado por padrão',
    es: 'Enrutamiento onion habilitado por defecto',
  );
  static const presentationPrivacyHighlightExposure = LocalizedCopy(
    en: 'Less dependence on exposed infrastructure',
    pt: 'Menor dependência de infraestrutura exposta',
    es: 'Menor dependencia de infraestructura expuesta',
  );
  static const presentationPrivacyHighlightArchitecture = LocalizedCopy(
    en: 'Security treated as architecture, not as optional',
    pt: 'Segurança tratada como arquitetura, não como opcional',
    es: 'La seguridad tratada como arquitectura, no como opcional',
  );
  static const presentationPrivacyHeroLabel = LocalizedCopy(
    en: 'TRAFFIC',
    pt: 'REDE',
    es: 'RED',
  );
  static const presentationPrivacyHeroCaption = LocalizedCopy(
    en: 'Network baseline',
    pt: 'Base de conexão',
    es: 'Base de conexión',
  );
  static const presentationRecoveryEyebrow = LocalizedCopy(
    en: 'RECOVERY UNDER YOUR CONTROL',
    pt: 'RECUPERAÇÃO SOB SEU CONTROLE',
    es: 'RECUPERACIÓN BAJO TU CONTROL',
  );
  static const presentationRecoveryTitle = LocalizedCopy(
    en: 'You create the account with a seed, 2FA, and device binding.',
    pt: 'Você cria a conta com frase de recuperação, 2FA e vínculo do dispositivo.',
    es: 'Creas la cuenta con seed, 2FA y vinculación del dispositivo.',
  );
  static const presentationRecoverySummary = LocalizedCopy(
    en: 'The flow requires offline backup and an authenticator app. It adds initial friction but reduces dependencies and assisted recovery.',
    pt: 'O fluxo exige backup offline e autenticador. Isso aumenta o cuidado no início, mas reduz dependências e pedidos de recuperação assistida.',
    es: 'El flujo exige respaldo offline y autenticador. Agrega fricción inicial, pero reduce dependencias y recuperación asistida.',
  );
  static const presentationRecoveryHighlightSeed = LocalizedCopy(
    en: 'Seed shown once for physical backup',
    pt: 'Frase exibida uma única vez para backup físico',
    es: 'La seed se muestra una sola vez para respaldo físico',
  );
  static const presentationRecoveryHighlightTotp = LocalizedCopy(
    en: 'TOTP to confirm possession and recover access',
    pt: 'TOTP para confirmar posse e reforçar o acesso',
    es: 'TOTP para confirmar posesión y reforzar el acceso',
  );
  static const presentationRecoveryHighlightPasskey = LocalizedCopy(
    en: 'Passkey to bind this device to login',
    pt: 'Passkey para vincular este dispositivo ao login',
    es: 'Passkey para vincular este dispositivo al acceso',
  );
  static const presentationRecoveryHeroLabel = LocalizedCopy(
    en: 'SECURITY',
    pt: 'SEGURANÇA',
    es: 'SEGURIDAD',
  );
  static const presentationRecoveryHeroCaption = LocalizedCopy(
    en: 'Access baseline',
    pt: 'Base do acesso',
    es: 'Base del acceso',
  );
  static const presentationActivationEyebrow = LocalizedCopy(
    en: 'DEPOSIT INSIDE THE PLATFORM',
    pt: 'DEPÓSITO DENTRO DA PLATAFORMA',
    es: 'DEPÓSITO DENTRO DE LA PLATAFORMA',
  );
  static const presentationActivationTitle = LocalizedCopy(
    en: 'Signup does not ask for a deposit.',
    pt: 'O cadastro não pede depósito.',
    es: 'El registro no pide depósito.',
  );
  static const presentationActivationSummary = LocalizedCopy(
    en: 'Receiving inside the platform is released after the first deposit made from the authenticated deposit flow.',
    pt: 'O recebimento dentro da plataforma é liberado após o primeiro depósito feito pelo fluxo autenticado.',
    es: 'La recepción dentro de la plataforma se libera después del primer depósito hecho desde el flujo autenticado.',
  );
  static const presentationActivationHighlightLivePending = LocalizedCopy(
    en: 'Amount fetched live before payment',
    pt: 'Valor consultado em tempo real antes do pagamento',
    es: 'Importe consultado en tiempo real antes del pago',
  );
  static const presentationActivationHighlightFees = LocalizedCopy(
    en: 'Network fees vary with blockchain conditions',
    pt: 'Taxas de rede variam conforme a blockchain',
    es: 'Las comisiones de red varían según la blockchain',
  );
  static const presentationActivationHighlightConfirmations = LocalizedCopy(
    en: 'Your account is activated after on-chain confirmations',
    pt: 'A conta é ativada após as confirmações on-chain',
    es: 'La cuenta se activa después de las confirmaciones on-chain',
  );
  static const presentationActivationHeroLabel = LocalizedCopy(
    en: 'ACTIVATION',
    pt: 'ATIVAÇÃO',
    es: 'ACTIVACIÓN',
  );
  static const presentationActivationHeroLive = LocalizedCopy(
    en: 'LIVE',
    pt: 'AO VIVO',
    es: 'EN VIVO',
  );
  static const presentationActivationHeroCurrentAmount = LocalizedCopy(
    en: 'Current amount',
    pt: 'Valor atual',
    es: 'Valor actual',
  );
  static const presentationActivationHeroPendingAmount = LocalizedCopy(
    en: 'Current amount',
    pt: 'Cotação em andamento',
    es: 'Cotización en curso',
  );

  static const homeLoadingAuthFailure = LocalizedCopy(
    en: 'AUTHENTICATION FAILURE',
    pt: 'FALHA DE AUTENTICAÇÃO',
    es: 'FALLO DE AUTENTICACIÓN',
  );
  static const homeLoadingQuoteUnavailable = LocalizedCopy(
    en: 'QUOTE UNAVAILABLE',
    pt: 'COTAÇÃO INDISPONÍVEL',
    es: 'COTIZACIÓN NO DISPONIBLE',
  );
  static const homeLoadingSlowConnection = LocalizedCopy(
    en: 'SLOW CONNECTION',
    pt: 'CONEXÃO LENTA',
    es: 'CONEXIÓN LENTA',
  );
  static const homeLoadingSyncing = LocalizedCopy(
    en: 'SYNCING',
    pt: 'SINCRONIZANDO',
    es: 'SINCRONIZANDO',
  );
  static const homeLoadingAccessDenied = LocalizedCopy(
    en: 'Access denied.',
    pt: 'Acesso negado.',
    es: 'Acceso denegado.',
  );
  static const homeLoadingQuoteBlockingBody = LocalizedCopy(
    en: 'The app will not start until quotes are synchronized.',
    pt: 'O app não será iniciado até sincronizar as cotações.',
    es: 'La app no se iniciará hasta sincronizar las cotizaciones.',
  );
  static const homeLoadingTorRetryBody = LocalizedCopy(
    en: 'We are still trying through the Tor network. You will enter as soon as the response arrives.',
    pt: 'Seguimos tentando pela rede Tor. Você entra assim que a resposta chegar.',
    es: 'Seguimos intentando por la red Tor. Entrarás apenas llegue la respuesta.',
  );
  static const homeLoadingSecureAssetsBody = LocalizedCopy(
    en: 'Ensuring full security for your assets',
    pt: 'Garantindo segurança total para seus ativos',
    es: 'Garantizando seguridad total para tus activos',
  );
  static const homeLoadingTryAgain = LocalizedCopy(
    en: 'TRY AGAIN',
    pt: 'TENTAR DE NOVO',
    es: 'INTENTAR DE NUEVO',
  );
  static const homeLoadingReloadQuotes = LocalizedCopy(
    en: 'RELOAD QUOTES',
    pt: 'RECARREGAR COTAÇÕES',
    es: 'RECARGAR COTIZACIONES',
  );
  static const homeLoadingRepeatSync = LocalizedCopy(
    en: 'REPEAT SYNC',
    pt: 'REPETIR SINCRONIZAÇÃO',
    es: 'REPETIR SINCRONIZACIÓN',
  );

  static const createWalletNameRequired = LocalizedCopy(
    en: 'Enter a name for the wallet',
    pt: 'INSIRA UM NOME PARA A CARTEIRA',
    es: 'INGRESA UN NOMBRE PARA LA BILLETERA',
  );
  static const createWalletSuccess = LocalizedCopy(
    en: 'Wallet created successfully',
    pt: 'CARTEIRA CRIADA COM SUCESSO',
    es: 'BILLETERA CREADA CON ÉXITO',
  );
  static const createWalletScreenTitle = LocalizedCopy(
    en: 'NEW WALLET',
    pt: 'NOVA CARTEIRA',
    es: 'NUEVA BILLETERA',
  );
  static const createWalletGenerateStructure = LocalizedCopy(
    en: 'GENERATE STRUCTURE',
    pt: 'GERAR ESTRUTURA',
    es: 'GENERAR ESTRUCTURA',
  );
  static const createWalletFinish = LocalizedCopy(
    en: 'FINISH CREATION',
    pt: 'FINALIZAR CRIAÇÃO',
    es: 'FINALIZAR CREACIÓN',
  );
  static const createWalletBackAndEdit = LocalizedCopy(
    en: 'BACK AND EDIT',
    pt: 'VOLTAR E ALTERAR',
    es: 'VOLVER Y EDITAR',
  );
  static const createWalletProtectSeed = LocalizedCopy(
    en: 'PROTECT YOUR SEED',
    pt: 'PROTEJA SUA SEED',
    es: 'PROTEGE TU SEED',
  );
  static const createWalletDefineParameters = LocalizedCopy(
    en: 'DEFINE PARAMETERS',
    pt: 'DEFINA OS PARÂMETROS',
    es: 'DEFINE LOS PARÁMETROS',
  );
  static const createWalletProtectSeedBody = LocalizedCopy(
    en: 'Write these words down in order. They are the only key to your funds.',
    pt: 'Anote estas palavras em ordem. Elas são a única chave para seus fundos.',
    es: 'Anota estas palabras en orden. Son la única llave de tus fondos.',
  );
  static const createWalletDefineParametersBody = LocalizedCopy(
    en: 'Choose the encryption level and the name of your new Vault account.',
    pt: 'Escolha o nível de criptografia e o nome da sua nova conta no Vault.',
    es: 'Elige el nivel de cifrado y el nombre de tu nueva cuenta en Vault.',
  );
  static const createWalletNameLabel = LocalizedCopy(
    en: 'WALLET NAME',
    pt: 'NOME DA CARTEIRA',
    es: 'NOMBRE DE LA BILLETERA',
  );
  static const createWalletNameHint = LocalizedCopy(
    en: 'Ex: Savings, Trading...',
    pt: 'Ex: Economias, Trading...',
    es: 'Ej.: Ahorros, Trading...',
  );
  static const createWalletPassphraseSize = LocalizedCopy(
    en: 'PASSPHRASE SIZE',
    pt: 'TAMANHO DA PASSPHRASE',
    es: 'TAMAÑO DE LA PASSPHRASE',
  );
  static const createWalletProtocolSecurity = LocalizedCopy(
    en: 'PROTOCOL SECURITY',
    pt: 'SEGURANÇA DO PROTOCOLO',
    es: 'SEGURIDAD DEL PROTOCOLO',
  );
  static const createWalletStandardTitle = LocalizedCopy(
    en: 'STANDARD',
    pt: 'STANDARD',
    es: 'ESTÁNDAR',
  );
  static const createWalletStandardBody = LocalizedCopy(
    en: 'Standard AES-256 encryption. Recommended for daily use.',
    pt: 'Criptografia AES-256 padrão. Recomendado para uso diário.',
    es: 'Cifrado AES-256 estándar. Recomendado para uso diario.',
  );
  static const createWalletShamirTitle = LocalizedCopy(
    en: 'SHAMIR',
    pt: 'SHAMIR',
    es: 'SHAMIR',
  );
  static const createWalletShamirBody = LocalizedCopy(
    en: 'Cryptographic secret sharing (SSS). Military-grade security.',
    pt: 'Divisão criptográfica de segredo (SSS). Segurança de nível militar.',
    es: 'División criptográfica del secreto (SSS). Seguridad de nivel militar.',
  );
  static const createWalletPaperOnly = LocalizedCopy(
    en: 'Write on paper. Digital copies are not shown here for your safety.',
    pt: 'Anote em papel. Cópias digitais não são oferecidas aqui para sua segurança.',
    es: 'Anótalo en papel. No ofrecemos copias digitales aquí por tu seguridad.',
  );

  static const createWalletColdPublicKeyLabel = LocalizedCopy(
    en: 'Cold wallet public key',
    pt: 'Chave pública da carteira fria',
    es: 'Llave pública de la billetera fría',
  );

  static const createWalletColdPublicKeyHint = LocalizedCopy(
    en: 'xpub / zpub / vpub',
    pt: 'xpub / zpub / vpub',
    es: 'xpub / zpub / vpub',
  );

  static const createWalletManagementPassphraseLabel = LocalizedCopy(
    en: 'Management passphrase',
    pt: 'Senha de administração',
    es: 'Contraseña de administración',
  );

  static const createWalletManagementPassphraseHint = LocalizedCopy(
    en: 'Use a password only for managing this wallet',
    pt: 'Use uma senha só para administrar esta carteira',
    es: 'Usa una contraseña solo para administrar esta billetera',
  );

  static const createWalletModeLabel = LocalizedCopy(
    en: 'Wallet mode',
    pt: 'Modo da carteira',
    es: 'Modo de billetera',
  );

  static const createWalletKeroseneModeTitle = LocalizedCopy(
    en: 'Kerosene',
    pt: 'Kerosene',
    es: 'Kerosene',
  );

  static const createWalletKeroseneModeSubtitle = LocalizedCopy(
    en: 'On-chain custody + Lightning',
    pt: 'Custódia on-chain + Lightning',
    es: 'Custodia on-chain + Lightning',
  );

  static const createWalletColdModeTitle = LocalizedCopy(
    en: 'Cold wallet',
    pt: 'Carteira fria',
    es: 'Billetera fría',
  );

  static const createWalletColdModeSubtitle = LocalizedCopy(
    en: 'Receive and monitor without moving keys',
    pt: 'Receber e acompanhar sem mover chaves',
    es: 'Recibir y acompañar sin mover llaves',
  );

  static const depositAmountZero = LocalizedCopy(
    en: 'Please enter an amount greater than zero.',
    pt: 'Por favor, insira um valor maior que zero.',
    es: 'Por favor, ingresa un importe mayor que cero.',
  );

  static const withdrawReviewLightningEmpty = LocalizedCopy(
    en: 'Enter the Lightning request',
    pt: 'Insira o pedido Lightning',
    es: 'Ingresa el pedido Lightning',
  );
  static const withdrawReviewOnChainEmpty = LocalizedCopy(
    en: 'Enter the on-chain address',
    pt: 'Insira o endereço On-chain',
    es: 'Ingresa la dirección on-chain',
  );
  static const withdrawReviewAuthReason = LocalizedCopy(
    en: 'Confirm your identity to complete the withdrawal',
    pt: 'Confirme sua identidade para realizar o saque',
    es: 'Confirma tu identidad para realizar el retiro',
  );
  static const withdrawReviewAuthFailed = LocalizedCopy(
    en: 'Biometric authentication failed',
    pt: 'Falha na autenticação biométrica',
    es: 'Falló la autenticación biométrica',
  );
  static const withdrawReviewInvalidTotp = LocalizedCopy(
    en: 'Invalid TOTP code',
    pt: 'Código TOTP inválido',
    es: 'Código TOTP inválido',
  );
  static const withdrawReviewLightningTitle = LocalizedCopy(
    en: 'LIGHTNING WITHDRAWAL',
    pt: 'SAQUE LIGHTNING',
    es: 'RETIRO LIGHTNING',
  );
  static const withdrawReviewOnChainTitle = LocalizedCopy(
    en: 'ON-CHAIN WITHDRAWAL',
    pt: 'SAQUE ON-CHAIN',
    es: 'RETIRO ON-CHAIN',
  );
  static const withdrawReviewPasteLightning = LocalizedCopy(
    en: 'Paste Lightning request',
    pt: 'Cole o pedido Lightning',
    es: 'Pega el pedido Lightning',
  );
  static const withdrawReviewPasteBitcoinAddress = LocalizedCopy(
    en: 'Paste Bitcoin Address',
    pt: 'Cole o endereço Bitcoin',
    es: 'Pega la dirección Bitcoin',
  );
  static const withdrawReviewContinue = LocalizedCopy(
    en: 'CONTINUE',
    pt: 'CONTINUAR',
    es: 'CONTINUAR',
  );
  static const withdrawReviewSecurityTitle = LocalizedCopy(
    en: 'SECURITY VERIFICATION',
    pt: 'VERIFICAÇÃO DE SEGURANÇA',
    es: 'VERIFICACIÓN DE SEGURIDAD',
  );
  static const withdrawReviewShamirLabel = LocalizedCopy(
    en: 'SHAMIR SSSS',
    pt: 'SHAMIR SSSS',
    es: 'SHAMIR SSSS',
  );
  static const withdrawReviewVerified = LocalizedCopy(
    en: 'VERIFIED',
    pt: 'VERIFICADO',
    es: 'VERIFICADO',
  );
  static const withdrawReviewPending = LocalizedCopy(
    en: 'PENDING',
    pt: 'PENDENTE',
    es: 'PENDIENTE',
  );
  static const withdrawReviewPasskeyLabel = LocalizedCopy(
    en: 'DIGITAL PASSKEY',
    pt: 'PASSKEY DIGITAL',
    es: 'PASSKEY DIGITAL',
  );
  static const withdrawReviewRequired = LocalizedCopy(
    en: 'REQUIRED',
    pt: 'OBRIGATÓRIO',
    es: 'OBLIGATORIO',
  );
  static const withdrawReviewEnterTotp = LocalizedCopy(
    en: 'ENTER TOTP CODE',
    pt: 'INSIRA O CÓDIGO TOTP',
    es: 'INGRESA EL CÓDIGO TOTP',
  );
  static const withdrawReviewConfirm = LocalizedCopy(
    en: 'CONFIRM WITHDRAWAL',
    pt: 'CONFIRMAR SAQUE',
    es: 'CONFIRMAR RETIRO',
  );
  static const withdrawDestinationDetectedOnChain = LocalizedCopy(
    en: 'Valid on-chain address detected',
    pt: 'Endereco on-chain valido detectado',
    es: 'Direccion on-chain valida detectada',
  );
  static const withdrawDestinationDetectedLightning = LocalizedCopy(
    en: 'Lightning request detected',
    pt: 'Pedido Lightning detectado',
    es: 'Pedido Lightning detectado',
  );
  static const withdrawDestinationInvalid = LocalizedCopy(
    en: 'Enter a valid Bitcoin address or Lightning request.',
    pt: 'Informe um endereco Bitcoin valido ou um pedido Lightning valido.',
    es: 'Ingresa una direccion Bitcoin valida o un pedido Lightning valido.',
  );
  static const withdrawDestinationLightningUnsupported = LocalizedCopy(
    en: 'For this withdrawal, use a Bitcoin on-chain address.',
    pt: 'Para este saque, use um endereco Bitcoin on-chain.',
    es: 'Para este retiro, usa una direccion Bitcoin on-chain.',
  );
  static const withdrawDestinationPaste = LocalizedCopy(
    en: 'Paste',
    pt: 'Colar',
    es: 'Pegar',
  );
  static const withdrawDestinationPasteHint = LocalizedCopy(
    en: 'Paste an on-chain address, bitcoin: URI, or Lightning request.',
    pt: 'Cole um endereco on-chain, URI bitcoin: ou pedido Lightning.',
    es: 'Pega una direccion on-chain, URI bitcoin: o pedido Lightning.',
  );
  static const withdrawWalletBalanceLabel = LocalizedCopy(
    en: 'AVAILABLE BALANCE',
    pt: 'SALDO DISPONIVEL',
    es: 'SALDO DISPONIBLE',
  );
  static const withdrawDestinationLabel = LocalizedCopy(
    en: 'DESTINATION',
    pt: 'DESTINO',
    es: 'DESTINO',
  );
  static const withdrawNetworkAutoLabel = LocalizedCopy(
    en: 'AUTO DETECTION',
    pt: 'DETECCAO AUTOMATICA',
    es: 'DETECCION AUTOMATICA',
  );
  static const withdrawSecurityTotpHint = LocalizedCopy(
    en: 'Enter the wallet TOTP to authorize this withdrawal.',
    pt: 'Digite o TOTP da carteira para autorizar este saque.',
    es: 'Ingresa el TOTP de la billetera para autorizar este retiro.',
  );
  static const withdrawDescriptionLabel = LocalizedCopy(
    en: 'DESCRIPTION',
    pt: 'DESCRICAO',
    es: 'DESCRIPCION',
  );
  static const withdrawReviewSummaryLabel = LocalizedCopy(
    en: 'WITHDRAWAL SUMMARY',
    pt: 'RESUMO DO SAQUE',
    es: 'RESUMEN DEL RETIRO',
  );
  static const withdrawInsufficientBalance = LocalizedCopy(
    en: 'Insufficient balance to cover the withdrawal and estimated network fee.',
    pt: 'Saldo insuficiente para cobrir o saque e a taxa estimada da rede.',
    es: 'Saldo insuficiente para cubrir el retiro y la tasa estimada de la red.',
  );
  static const withdrawNetworkOnChainChip = LocalizedCopy(
    en: 'ON-CHAIN',
    pt: 'ON-CHAIN',
    es: 'ON-CHAIN',
  );
  static const withdrawNetworkReviewChip = LocalizedCopy(
    en: 'REVIEW',
    pt: 'REVISAR',
    es: 'REVISAR',
  );
  static const withdrawFeeModeTitle = LocalizedCopy(
    en: 'HOW TO APPLY FEES',
    pt: 'COMO APLICAR AS TAXAS',
    es: 'COMO APLICAR LAS TASAS',
  );
  static const withdrawFeeModeSenderPaysTitle = LocalizedCopy(
    en: 'Fees added',
    pt: 'Taxas por fora',
    es: 'Tasas por fuera',
  );
  static const withdrawFeeModeSenderPaysBody = LocalizedCopy(
    en: 'The recipient receives the amount you entered. Fees are added to your total.',
    pt: 'O destino recebe o valor digitado. As taxas entram por fora no total.',
    es: 'El destino recibe el importe ingresado. Las tasas se suman al total.',
  );
  static const withdrawFeeModeRecipientPaysTitle = LocalizedCopy(
    en: 'Fees deducted',
    pt: 'Taxas descontadas',
    es: 'Tasas descontadas',
  );
  static const withdrawFeeModeRecipientPaysBody = LocalizedCopy(
    en: 'The total paid stays close to the amount entered. Fees are deducted from what arrives.',
    pt: 'O total pago fica próximo do valor digitado. As taxas saem do que chega.',
    es: 'El total pagado queda cerca del importe ingresado. Las tasas salen de lo que llega.',
  );
  static const withdrawReceiverReceivesLabel = LocalizedCopy(
    en: 'Recipient receives',
    pt: 'Destino recebe',
    es: 'Destino recibe',
  );
  static const withdrawYouPayTotalLabel = LocalizedCopy(
    en: 'You pay in total',
    pt: 'Voce paga no total',
    es: 'Pagas en total',
  );
  static const withdrawFeesDeductedLabel = LocalizedCopy(
    en: 'Fees deducted',
    pt: 'Taxas descontadas',
    es: 'Tasas descontadas',
  );
  static const withdrawFeesAddedLabel = LocalizedCopy(
    en: 'Estimated fees',
    pt: 'Taxas estimadas',
    es: 'Tasas estimadas',
  );
  static const withdrawFeeModeDeductedHint = LocalizedCopy(
    en: 'In this mode, the destination receives the amount after platform and transaction fees.',
    pt: 'Neste modo, o destino recebe o valor apos taxas da plataforma e da transacao.',
    es: 'En este modo, el destino recibe el importe despues de tasas de plataforma y transaccion.',
  );
  static const withdrawFeeModeAddedHint = LocalizedCopy(
    en: 'In this mode, the destination receives the full amount and fees are charged separately.',
    pt: 'Neste modo, o destino recebe o valor integral e as taxas sao cobradas separadamente.',
    es: 'En este modo, el destino recibe el importe completo y las tasas se cobran aparte.',
  );

  static const withdrawReceiptWallet = LocalizedCopy(
    en: 'WALLET',
    pt: 'CARTEIRA',
    es: 'BILLETERA',
  );
  static const withdrawReceiptInvoice = LocalizedCopy(
    en: 'INVOICE',
    pt: 'INVOICE',
    es: 'INVOICE',
  );
  static const withdrawReceiptTime = LocalizedCopy(
    en: 'TIME',
    pt: 'HORÁRIO',
    es: 'HORA',
  );
  static const withdrawReceiptFee = LocalizedCopy(
    en: 'FEE',
    pt: 'TAXA',
    es: 'COMISIÓN',
  );
  static const withdrawReceiptStatus = LocalizedCopy(
    en: 'STATUS',
    pt: 'STATUS',
    es: 'ESTADO',
  );
  static const withdrawReceiptConfirmed = LocalizedCopy(
    en: 'CONFIRMED',
    pt: 'CONFIRMADO',
    es: 'CONFIRMADO',
  );
  static const withdrawReceiptTransactionId = LocalizedCopy(
    en: 'TRANSACTION ID',
    pt: 'ID DA TRANSAÇÃO',
    es: 'ID DE TRANSACCIÓN',
  );

  static const settingsOverviewSummary = LocalizedCopy(
    en: 'Quickly review the current access, privacy, and display posture before changing finer details.',
    pt: 'Revise rapidamente a postura atual de acesso, privacidade e exibição antes de alterar detalhes finos.',
    es: 'Revisa rápidamente la postura actual de acceso, privacidad y visualización antes de cambiar detalles finos.',
  );
  static const settingsRouting = LocalizedCopy(
    en: 'Routing',
    pt: 'Roteamento',
    es: 'Enrutamiento',
  );
  static const settingsOnionActive = LocalizedCopy(
    en: 'Onion active',
    pt: 'Onion ativo',
    es: 'Onion activo',
  );
  static const settingsDirectConnection = LocalizedCopy(
    en: 'Direct connection',
    pt: 'Conexão direta',
    es: 'Conexión directa',
  );
  static const settingsBiometrics = LocalizedCopy(
    en: 'Biometrics',
    pt: 'Biometria',
    es: 'Biometría',
  );
  static const settingsBalance = LocalizedCopy(
    en: 'Balance',
    pt: 'Saldo',
    es: 'Saldo',
  );
  static const settingsHidden = LocalizedCopy(
    en: 'Hidden',
    pt: 'Oculto',
    es: 'Oculto',
  );
  static const settingsVisible = LocalizedCopy(
    en: 'Visible',
    pt: 'Visível',
    es: 'Visible',
  );
  static const settingsLocation = LocalizedCopy(
    en: 'Locale',
    pt: 'Localização',
    es: 'Localización',
  );

  static const loginPassphraseIntro = LocalizedCopy(
    en: 'Enter your secret phrase exactly as it was stored.',
    pt: 'Digite sua frase secreta exatamente como foi armazenada.',
    es: 'Ingresa tu frase secreta exactamente como fue guardada.',
  );
  static const loginPassphraseHint = LocalizedCopy(
    en: 'This step authenticates access and does not change your seed.',
    pt: 'Esta etapa autentica o acesso e nao altera sua seed.',
    es: 'Este paso autentica el acceso y no cambia tu seed.',
  );
  static const loginPassphraseValidationAllWords = LocalizedCopy(
    en: 'Fill all words before continuing.',
    pt: 'Preencha todas as palavras antes de continuar.',
    es: 'Completa todas las palabras antes de continuar.',
  );
  static const loginPassphraseTitle = LocalizedCopy(
    en: 'BIP39',
    pt: 'BIP39',
    es: 'BIP39',
  );
  static const loginPassphraseManualMode = LocalizedCopy(
    en: 'Manual login',
    pt: 'Login manual',
    es: 'Login manual',
  );
  static const loginPassphraseDescription = LocalizedCopy(
    en: 'Enter your BIP39 phrase exactly in the stored order. The layout below adapts between one and two columns to avoid clipping and misalignment.',
    pt: 'Digite sua frase BIP39 exatamente na ordem em que foi armazenada. O layout abaixo se adapta entre uma e duas colunas para evitar cortes e desalinhamentos.',
    es: 'Ingresa tu frase BIP39 exactamente en el orden en que fue guardada. El layout se adapta entre una y dos columnas para evitar cortes y desalineacion.',
  );
  static const loginPassphraseRecoveryHint = LocalizedCopy(
    en: 'If you lost the passphrase, use the recovery codes to rotate TOTP, passkey, and seed in a new flow.',
    pt: 'Se voce perdeu a frase secreta, use os recovery codes para rotacionar TOTP, passkey e seed em um fluxo novo.',
    es: 'Si perdiste la frase secreta, usa los recovery codes para rotar TOTP, passkey y seed en un nuevo flujo.',
  );
  static const loginPassphraseWordHint = LocalizedCopy(
    en: 'word',
    pt: 'palavra',
    es: 'palabra',
  );
  static const loginManualModePassphrase = LocalizedCopy(
    en: 'BIP39',
    pt: 'BIP39',
    es: 'BIP39',
  );
  static const loginManualModeShamir = LocalizedCopy(
    en: 'SLIP-39 shares',
    pt: 'Shares SLIP-39',
    es: 'Shares SLIP-39',
  );
  static const loginPassphraseDescriptionShamir = LocalizedCopy(
    en: 'Paste the full SLIP-39 shares to reconstruct your secret phrase locally before login.',
    pt: 'Cole as shares completas do SLIP-39 para reconstruir sua frase secreta localmente antes do login.',
    es: 'Pega las shares completas de SLIP-39 para reconstruir tu frase secreta localmente antes del acceso.',
  );
  static const loginShamirShareCountLabel = LocalizedCopy(
    en: 'Shares provided',
    pt: 'Shares informadas',
    es: 'Shares informadas',
  );
  static const loginShamirShareCountHint = LocalizedCopy(
    en: 'Use the number of shares you actually have available now.',
    pt: 'Use a quantidade de shares que voce realmente tem disponivel agora.',
    es: 'Usa la cantidad de shares que realmente tienes disponible ahora.',
  );
  static const loginShamirContinue = LocalizedCopy(
    en: 'Reconstruct and continue',
    pt: 'Reconstruir e continuar',
    es: 'Reconstruir y continuar',
  );
  static const loginPassphraseInvalidWord = LocalizedCopy(
    en: 'Use only valid recovery words before continuing.',
    pt: 'Use apenas palavras validas de recuperacao antes de continuar.',
    es: 'Usa solo palabras validas de recuperacion antes de continuar.',
  );
  static const loginShamirInvalidShare = LocalizedCopy(
    en: 'One or more SLIP-39 shards are invalid or incomplete.',
    pt: 'Uma ou mais shards SLIP-39 estao invalidas ou incompletas.',
    es: 'Una o mas shards SLIP-39 son invalidas o incompletas.',
  );
  static const loginMultisigTitle = LocalizedCopy(
    en: 'Multisig',
    pt: 'Multisig',
    es: 'Multisig',
  );
  static const loginMultisigDescription = LocalizedCopy(
    en: 'Enter each multisig recovery shard using the same guided word layout. Every shard is validated before the request is sent.',
    pt: 'Informe cada shard de recuperacao multisig usando o mesmo layout guiado por palavras. Cada shard e validado antes do envio.',
    es: 'Ingresa cada shard de recuperacion multisig usando el mismo layout guiado por palabras. Cada shard se valida antes del envio.',
  );
  static const loginMultisigShardCountLabel = LocalizedCopy(
    en: 'Shards provided',
    pt: 'Shards informadas',
    es: 'Shards informadas',
  );
  static const loginMultisigShardCountHint = LocalizedCopy(
    en: 'Use the number of multisig shards you have available for this access.',
    pt: 'Use a quantidade de shards multisig disponiveis para este acesso.',
    es: 'Usa la cantidad de shards multisig disponibles para este acceso.',
  );
  static const loginMultisigShardIncomplete = LocalizedCopy(
    en: 'Complete every word in this multisig shard before continuing.',
    pt: 'Preencha todas as palavras desta shard multisig antes de continuar.',
    es: 'Completa todas las palabras de este shard multisig antes de continuar.',
  );

  static const authReasonWalletAccess = LocalizedCopy(
    en: 'Authenticate to access your wallet',
    pt: 'Autentique-se para acessar sua carteira',
    es: 'Autentícate para acceder a tu billetera',
  );
  static const authReasonSovereignKeyAccess = LocalizedCopy(
    en: 'Authenticate to access your device key',
    pt: 'Autentique para acessar sua chave do dispositivo',
    es: 'Autentícate para acceder a tu llave del dispositivo',
  );
  static const authReasonTransactionConfirm = LocalizedCopy(
    en: 'Use your device lock to confirm this transaction',
    pt: 'Use o bloqueio do dispositivo para confirmar esta transacao',
    es: 'Usa el bloqueo del dispositivo para confirmar esta transacción',
  );

  static const signupRequirementsEyebrow = LocalizedCopy(
    en: 'Start',
    pt: 'Começo',
    es: 'Inicio',
  );
  static const signupRequirementsTitle = LocalizedCopy(
    en: 'Open your account',
    pt: 'Abra sua conta',
    es: 'Abre tu cuenta',
  );
  static const signupRequirementsSubtitle = LocalizedCopy(
    en: 'Set aside a few uninterrupted minutes, an authenticator app, and a safe place for your recovery backup. The flow is linear and only shows what matters at each step.',
    pt: 'Separe alguns minutos, um autenticador e um lugar seguro para guardar sua recuperacao. O fluxo e linear e mostra so o que voce precisa em cada etapa.',
    es: 'Reserva algunos minutos, un autenticador y un lugar seguro para guardar tu respaldo. El flujo es lineal y solo muestra lo necesario en cada paso.',
  );
  static const signupRequirementsHighlightLabel = LocalizedCopy(
    en: 'Estimated activation',
    pt: 'Ativacao estimada',
    es: 'Activación estimada',
  );
  static const signupRequirementsHighlightLiveHint = LocalizedCopy(
    en: 'This amount is fetched live. Your account is activated after 3 network confirmations.',
    pt: 'O valor e consultado em tempo real. A conta e ativada depois de 3 confirmacoes na rede.',
    es: 'El importe se consulta en tiempo real. La cuenta se activa después de 3 confirmaciones en la red.',
  );
  static const signupRequirementsHighlightPendingHint = LocalizedCopy(
    en: 'The final amount is fetched live right before you send the payment.',
    pt: 'O valor final e buscado em tempo real antes do envio.',
    es: 'El importe final se consulta en tiempo real antes del envío.',
  );
  static const signupRequirementsChip2fa = LocalizedCopy(
    en: 'Two-factor code required',
    pt: 'Codigo de dois fatores obrigatorio',
    es: 'Código de dos factores obligatorio',
  );
  static const signupRequirementsChipPasskey = LocalizedCopy(
    en: 'Passkey on this device',
    pt: 'Passkey no aparelho',
    es: 'Passkey en este dispositivo',
  );
  static const signupRequirementsChipConfirmations = LocalizedCopy(
    en: '3 network confirmations',
    pt: '3 confirmacoes na rede',
    es: '3 confirmaciones en la red',
  );
  static const signupRequirementsPanelTitle = LocalizedCopy(
    en: 'Have this ready',
    pt: 'Tenha isso em maos',
    es: 'Ten esto listo',
  );
  static const signupRequirementsTimeTitle = LocalizedCopy(
    en: 'A few uninterrupted minutes',
    pt: 'Alguns minutos sem interrupcao',
    es: 'Algunos minutos sin interrupciones',
  );
  static const signupRequirementsTimeBody = LocalizedCopy(
    en: 'You will create the backup, enable 2FA, protect the device, and confirm activation.',
    pt: 'Voce vai criar o backup, ativar o 2FA, proteger o aparelho e confirmar a ativacao.',
    es: 'Vas a crear el respaldo, activar el 2FA, proteger el dispositivo y confirmar la activación.',
  );
  static const signupRequirementsAuthenticatorTitle = LocalizedCopy(
    en: 'An installed authenticator app',
    pt: 'Um autenticador instalado',
    es: 'Un autenticador instalado',
  );
  static const signupRequirementsAuthenticatorBody = LocalizedCopy(
    en: 'You will scan a QR code and enter a 6-digit code before moving on.',
    pt: 'Voce vai escanear um QR Code e digitar um codigo de 6 digitos antes de seguir.',
    es: 'Vas a escanear un código QR e ingresar un código de 6 dígitos antes de continuar.',
  );
  static const signupRequirementsBackupTitle = LocalizedCopy(
    en: 'An offline backup',
    pt: 'Um backup offline',
    es: 'Un respaldo offline',
  );
  static const signupRequirementsBackupBody = LocalizedCopy(
    en: 'Your recovery phrase must stay out of screenshots, cloud storage, email, and notes apps.',
    pt: 'Sua frase de recuperacao deve ficar fora de print, nuvem, e-mail e bloco de notas.',
    es: 'Tu frase de recuperación debe quedar fuera de capturas, nube, correo y notas.',
  );
  static const signupRequirementsNoticeTitle = LocalizedCopy(
    en: 'Attention',
    pt: 'Atencao',
    es: 'Atención',
  );
  static const signupRequirementsNoticeBody = LocalizedCopy(
    en: 'If you lose the phrase, the backup codes, and access to the authenticator, the account may become unrecoverable.',
    pt: 'Se voce perder a frase, os codigos de backup e o acesso ao autenticador, a conta pode se tornar irrecuperavel.',
    es: 'Si pierdes la frase, los códigos de respaldo y el acceso al autenticador, la cuenta puede volverse irrecuperable.',
  );
  static const signupRequirementsCta = LocalizedCopy(
    en: 'I am ready to continue',
    pt: 'Estou pronto para continuar',
    es: 'Estoy listo para continuar',
  );
  static const signupRequirementsCaption = LocalizedCopy(
    en: 'You can still go back one step to review before creating the account.',
    pt: 'Voce ainda podera voltar uma etapa para revisar antes de criar a conta.',
    es: 'Aún podrás volver un paso para revisar antes de crear la cuenta.',
  );

  static const signupSecurityStandardTitle = LocalizedCopy(
    en: 'Standard',
    pt: 'Padrao',
    es: 'Estándar',
  );
  static const signupSecurityStandardBadge = LocalizedCopy(
    en: 'Recommended',
    pt: 'Recomendado',
    es: 'Recomendado',
  );
  static const signupSecurityStandardDescription = LocalizedCopy(
    en: 'A single recovery phrase with lower operational complexity and broad compatibility.',
    pt: 'Uma unica frase de recuperacao, com menor complexidade operacional e ampla compatibilidade.',
    es: 'Una sola frase de recuperación, con menor complejidad operativa y amplia compatibilidad.',
  );
  static const signupSecurityStandardBulletStore = LocalizedCopy(
    en: 'Simpler to store and recover',
    pt: 'Mais simples para guardar e recuperar',
    es: 'Mas simple de guardar y recuperar',
  );
  static const signupSecurityStandardBulletFit = LocalizedCopy(
    en: 'Best fit for most users',
    pt: 'Boa escolha para a maioria dos usuarios',
    es: 'La mejor opción para la mayoría',
  );
  static const signupSecurityStandardBulletFriction = LocalizedCopy(
    en: 'Less friction in daily use',
    pt: 'Menor atrito no uso diario',
    es: 'Menos fricción en el uso diario',
  );
  static const signupSecuritySlip39Badge = LocalizedCopy(
    en: 'Advanced',
    pt: 'Avancado',
    es: 'Avanzado',
  );
  static const signupSecuritySlip39Title = LocalizedCopy(
    en: 'Shamir SLIP-39',
    pt: 'Shamir SLIP-39',
    es: 'Shamir SLIP-39',
  );
  static const signupSecuritySlip39Description = LocalizedCopy(
    en: 'Splits the secret into independent shares. You choose how many shares exist and how many are required to recover the account.',
    pt: 'Divide o segredo em partes independentes. Voce escolhe quantas partes existirao e quantas serao necessarias para recuperar a conta.',
    es: 'Divide el secreto en partes independientes. Tú eliges cuántas partes existirán y cuántas serán necesarias para recuperar la cuenta.',
  );
  static const signupSecuritySlip39BulletStorage = LocalizedCopy(
    en: 'Ideal for storing in different locations',
    pt: 'Ideal para guardar em locais diferentes',
    es: 'Ideal para guardar en lugares distintos',
  );
  static const signupSecuritySlip39BulletQuorum = LocalizedCopy(
    en: 'Recovery needs enough saved parts',
    pt: 'A recuperacao exige partes suficientes guardadas',
    es: 'La recuperacion exige suficientes partes guardadas',
  );
  static const signupSecuritySlip39BulletDiscipline = LocalizedCopy(
    en: 'Requires stronger operational discipline',
    pt: 'Exige mais disciplina operacional',
    es: 'Exige mayor disciplina operativa',
  );
  static const signupSecurityMultisigTitle = LocalizedCopy(
    en: 'Multisig Vault',
    pt: 'Cofre Multisig',
    es: 'Bóveda Multisig',
  );
  static const signupSecurityMultisigBadge = LocalizedCopy(
    en: 'Institutional',
    pt: 'Institucional',
    es: 'Institucional',
  );
  static const signupSecurityMultisigDescription = LocalizedCopy(
    en: 'A model for stricter operations, including an additional authorization layer.',
    pt: 'Modelo para operacoes com processo mais rigido, incluindo exigencia adicional de autorizacao.',
    es: 'Un modelo para operaciones mas estrictas, con una capa adicional de autorización.',
  );
  static const signupSecurityMultisigBulletAdvanced = LocalizedCopy(
    en: 'Better suited for advanced setups',
    pt: 'Mais indicado para setups avancados',
    es: 'Mas adecuado para configuraciones avanzadas',
  );
  static const signupSecurityMultisigBulletRigor = LocalizedCopy(
    en: 'Higher operational rigor',
    pt: 'Maior rigor operacional',
    es: 'Mayor rigor operativo',
  );
  static const signupSecurityMultisigBulletBeginners = LocalizedCopy(
    en: 'Not the best choice for beginners',
    pt: 'Nao e a melhor opcao para iniciantes',
    es: 'No es la mejor opción para principiantes',
  );
  static const signupSecurityMultisigConfigTitle = LocalizedCopy(
    en: 'Vault approval rules',
    pt: 'Regras de aprovacao do cofre',
    es: 'Reglas de aprobacion de la boveda',
  );
  static const signupSecurityMultisigConfigBody = LocalizedCopy(
    en: 'Choose how many confirmations are required for each withdrawal and internal payment. Mode 2 uses access password + authenticator code. Mode 3 also asks for your device key.',
    pt: 'Escolha quantas confirmacoes serao exigidas em cada saque e pagamento interno. O modo 2 usa senha de acesso + codigo do autenticador. O modo 3 tambem pede a chave do dispositivo.',
    es: 'Elige cuantas confirmaciones se exigiran en cada retiro y pago interno. El modo 2 usa contrasena de acceso + codigo del autenticador. El modo 3 tambien pide la llave del dispositivo.',
  );
  static const signupSecurityMultisigRequiredFactors = LocalizedCopy(
    en: 'Required factors',
    pt: 'Fatores exigidos',
    es: 'Factores requeridos',
  );
  static const signupSecurityMultisigRequiredFactorsHint = LocalizedCopy(
    en: 'Choose 2 for strong protection with less friction or 3 to require passkey on every critical operation.',
    pt: 'Escolha 2 para uma operacao forte com menos friccao ou 3 para exigir passkey em toda operacao critica.',
    es: 'Elige 2 para una proteccion fuerte con menos friccion o 3 para exigir passkey en cada operacion critica.',
  );
  static const signupSecurityEyebrow = LocalizedCopy(
    en: 'Protection',
    pt: 'Protecao',
    es: 'Protección',
  );
  static const signupSecurityTitle = LocalizedCopy(
    en: 'Choose a model you can actually maintain',
    pt: 'Escolha um modelo que voce consegue manter',
    es: 'Elige un modelo que realmente puedas mantener',
  );
  static const signupSecuritySubtitle = LocalizedCopy(
    en: 'The best security is the one you can operate confidently. For most people, the standard model is the best decision.',
    pt: 'A melhor seguranca e a que voce consegue operar com confianca. Para a maioria das pessoas, o modelo padrao e a melhor decisao.',
    es: 'La mejor seguridad es la que puedes operar con confianza. Para la mayoría, el modelo estándar es la mejor decisión.',
  );
  static const signupSecurityHighlightLabel = LocalizedCopy(
    en: 'Selected now',
    pt: 'Selecionado agora',
    es: 'Seleccionado ahora',
  );
  static const signupSecurityChipFriction = LocalizedCopy(
    en: 'Less friction',
    pt: 'Menos friccao',
    es: 'Menos fricción',
  );
  static const signupSecurityChipGuidedBackup = LocalizedCopy(
    en: 'Guided backup',
    pt: 'Backup guiado',
    es: 'Respaldo guiado',
  );
  static const signupSecuritySlip39ConfigIntro = LocalizedCopy(
    en: 'You will see the parts separately on the next screen. Store each part in a different safe place and choose how many parts are needed to recover.',
    pt: 'Voce vera as partes separadas na proxima tela. Guarde cada parte em um local seguro diferente e escolha quantas partes serao necessarias para recuperar.',
    es: 'Veras las partes por separado en la siguiente pantalla. Guarda cada parte en un lugar seguro distinto y elige cuantas partes seran necesarias para recuperar.',
  );
  static const signupSecuritySlip39TotalSharesHint = LocalizedCopy(
    en: 'How many independent shares will be generated.',
    pt: 'Quantas partes independentes serao geradas.',
    es: 'Cuántas partes independientes se generarán.',
  );
  static const signupSecuritySlip39ThresholdHint = LocalizedCopy(
    en: 'How many shares will be required to recover the account.',
    pt: 'Quantas partes serao necessarias para recuperar a conta.',
    es: 'Cuántas partes serán necesarias para recuperar la cuenta.',
  );
  static const signupSecurityNextScreenTitle = LocalizedCopy(
    en: 'What changes on the next screen',
    pt: 'O que muda na proxima tela',
    es: 'Que cambia en la siguiente pantalla',
  );
  static const signupSecurityNextScreenSlip39 = LocalizedCopy(
    en: 'You will see the shares separately and confirm that each one was stored securely.',
    pt: 'Voce vera as partes separadas e podera confirmar que cada uma foi guardada com seguranca.',
    es: 'Verás las partes por separado y podrás confirmar que cada una fue guardada con seguridad.',
  );
  static const signupSecurityNextScreenStandard = LocalizedCopy(
    en: 'You will see the recovery phrase and complete a quick check before continuing.',
    pt: 'Voce vera a frase de recuperacao e fara uma checagem rapida antes de continuar.',
    es: 'Verás la frase de recuperación y harás una revisión rápida antes de continuar.',
  );
  static const signupSecurityNextScreenMultisig = LocalizedCopy(
    en: 'The vault will be activated now and these approval rules will apply to withdrawals and internal payments.',
    pt: 'O cofre sera ativado agora e estas regras de aprovacao passarao a valer para saques e pagamentos internos.',
    es: 'La boveda se activara ahora y estas reglas de aprobacion se aplicaran a retiros y pagos internos.',
  );

  static const signupSeedWordCountRecommended = LocalizedCopy(
    en: 'Recommended',
    pt: 'Recomendado',
    es: 'Recomendado',
  );
  static const signupSeedTitleSlip39 = LocalizedCopy(
    en: 'Store your recovery shares',
    pt: 'Guarde suas partes de recuperacao',
    es: 'Guarda tus partes de recuperación',
  );
  static const signupSeedTitleStandard = LocalizedCopy(
    en: 'Store your recovery phrase',
    pt: 'Guarde sua frase de recuperacao',
    es: 'Guarda tu frase de recuperación',
  );
  static const signupSeedSubtitleSlip39 = LocalizedCopy(
    en: 'The primary phrase has been split into independent parts. Store each part separately and keep the recovery rule in mind.',
    pt: 'A frase principal foi dividida em partes independentes. Guarde cada parte separadamente e mantenha a regra de recuperacao em mente.',
    es: 'La frase principal fue dividida en partes independientes. Guarda cada parte por separado y ten presente la regla de recuperacion.',
  );
  static const signupSeedSubtitleStandard = LocalizedCopy(
    en: 'This phrase controls account recovery. Write it down on paper, carefully, and confirm it before you continue.',
    pt: 'Esta frase controla a recuperacao da conta. Anote em papel, com calma, e confirme antes de continuar.',
    es: 'Esta frase controla la recuperación de la cuenta. Anótala en papel, con calma, y confírmala antes de continuar.',
  );
  static const signupSeedWarningSlip39 = LocalizedCopy(
    en: 'Do not store all shares in the same place, or in screenshots, cloud storage, email, or notes apps.',
    pt: 'Nao salve todas as partes no mesmo local, nem em print, nuvem, e-mail ou bloco de notas.',
    es: 'No guardes todas las partes en el mismo lugar, ni en capturas, nube, correo o notas.',
  );
  static const signupSeedWarningStandard = LocalizedCopy(
    en: 'Do not save the phrase in screenshots, cloud storage, email, or digital notes.',
    pt: 'Nao salve a frase em print, nuvem, e-mail ou bloco de notas digital.',
    es: 'No guardes la frase en capturas, nube, correo o notas digitales.',
  );
  static const signupSeedGenerateNewShares = LocalizedCopy(
    en: 'Generate new shares',
    pt: 'Gerar novas partes',
    es: 'Generar nuevas partes',
  );
  static const signupSeedGenerateNewPhrase = LocalizedCopy(
    en: 'Generate new phrase',
    pt: 'Gerar nova frase',
    es: 'Generar nueva frase',
  );
  static const signupSeedConfirmationStandard = LocalizedCopy(
    en: 'I confirm that I wrote the phrase down on a physical medium and can access it later.',
    pt: 'Confirmei que anotei a frase em um meio fisico e consigo acessa-la depois.',
    es: 'Confirmo que anoté la frase en un medio físico y podré acceder a ella después.',
  );
  static const signupSeedContinueSlip39 = LocalizedCopy(
    en: 'I saved the shares',
    pt: 'Ja guardei as partes',
    es: 'Ya guardé las partes',
  );
  static const signupSeedContinueMultisig = LocalizedCopy(
    en: 'Continue with the vault setup',
    pt: 'Continuar com a configuracao do cofre',
    es: 'Continuar con la configuracion de la bóveda',
  );
  static const signupSeedContinueStandard = LocalizedCopy(
    en: 'I saved the phrase',
    pt: 'Ja guardei a frase',
    es: 'Ya guardé la frase',
  );

  static const signupVerificationError = LocalizedCopy(
    en: 'Some words are incorrect. Review your backup and try again.',
    pt: 'Algumas palavras estao incorretas. Revise o backup e tente novamente.',
    es: 'Algunas palabras son incorrectas. Revisa el respaldo e inténtalo de nuevo.',
  );
  static const signupVerificationTitle = LocalizedCopy(
    en: 'Confirm your backup',
    pt: 'Confirme seu backup',
    es: 'Confirma tu respaldo',
  );
  static const signupVerificationFillHighlighted = LocalizedCopy(
    en: 'Fill in only the highlighted fields.',
    pt: 'Preencha apenas os campos destacados.',
    es: 'Completa solo los campos destacados.',
  );
  static const signupVerificationContinue = LocalizedCopy(
    en: 'Confirm backup and continue',
    pt: 'Confirmar backup e continuar',
    es: 'Confirmar respaldo y continuar',
  );
  static const signupVerificationSlip39Title = LocalizedCopy(
    en: 'Review your shares',
    pt: 'Revise suas partes',
    es: 'Revisa tus partes',
  );

  static const signupTotpEyebrow = LocalizedCopy(
    en: '2FA',
    pt: '2FA',
    es: '2FA',
  );
  static const signupTotpTitle = LocalizedCopy(
    en: 'Set up your authenticator',
    pt: 'Configure seu autenticador',
    es: 'Configura tu autenticador',
  );
  static const signupTotpSubtitle = LocalizedCopy(
    en: 'The sequence is simple: scan the QR code, store your backups, and only then validate the 6-digit code.',
    pt: 'A sequencia e simples: escaneie o QR Code, guarde seus backups e so depois valide o codigo de 6 digitos.',
    es: 'La secuencia es simple: escanea el código QR, guarda tus respaldos y solo después valida el código de 6 dígitos.',
  );
  static const signupTotpHighlightLabel = LocalizedCopy(
    en: 'Status',
    pt: 'Estado',
    es: 'Estado',
  );
  static const signupTotpHighlightReady = LocalizedCopy(
    en: 'Ready to validate',
    pt: 'Pronto para validar',
    es: 'Listo para validar',
  );
  static const signupTotpHighlightPending = LocalizedCopy(
    en: 'Backup still pending',
    pt: 'Falta concluir o backup',
    es: 'Falta concluir el respaldo',
  );
  static const signupTotpHighlightHint = LocalizedCopy(
    en: 'Storing the backup now reduces risk and avoids lockout later.',
    pt: 'Guardar o backup agora reduz risco e evita bloqueio depois.',
    es: 'Guardar el respaldo ahora reduce el riesgo y evita un bloqueo después.',
  );
  static const signupTotpChipQr = LocalizedCopy(
    en: 'QR code',
    pt: 'QR Code',
    es: 'Código QR',
  );
  static const signupTotpChipBackup = LocalizedCopy(
    en: 'Backup codes',
    pt: 'Codigos de backup',
    es: 'Códigos de respaldo',
  );
  static const signupTotpChipCode = LocalizedCopy(
    en: '6-digit code',
    pt: 'Codigo de 6 digitos',
    es: 'Código de 6 dígitos',
  );
  static const signupTotpStepScan = LocalizedCopy(
    en: 'Scan the QR code in your authenticator',
    pt: 'Escaneie o QR Code no autenticador',
    es: 'Escanea el código QR en tu autenticador',
  );
  static const signupTotpStepStore = LocalizedCopy(
    en: 'Store the secret and backup codes',
    pt: 'Guarde o segredo e os codigos de backup',
    es: 'Guarda el secreto y los códigos de respaldo',
  );
  static const signupTotpSecretLabel = LocalizedCopy(
    en: 'TOTP SECRET',
    pt: 'SEGREDO TOTP',
    es: 'SECRETO TOTP',
  );
  static const signupTotpBackupCodesLabel = LocalizedCopy(
    en: 'BACKUP CODES',
    pt: 'CODIGOS DE BACKUP',
    es: 'CÓDIGOS DE RESPALDO',
  );
  static const signupTotpBackupConfirm = LocalizedCopy(
    en: 'I confirm that I stored the backup codes offline before continuing.',
    pt: 'Confirmei que guardei os codigos de backup offline antes de continuar.',
    es: 'Confirmo que guardé los códigos de respaldo offline antes de continuar.',
  );
  static const signupTotpStepEnter = LocalizedCopy(
    en: 'Enter the 6-digit code',
    pt: 'Digite o codigo de 6 digitos',
    es: 'Ingresa el código de 6 dígitos',
  );

  static const signupPowPhaseRequestTitle = LocalizedCopy(
    en: 'Preparing account',
    pt: 'Preparando a conta',
    es: 'Preparando la cuenta',
  );
  static const signupPowPhaseRequestBody = LocalizedCopy(
    en: 'We are preparing a protected setup for this account.',
    pt: 'Estamos preparando uma configuracao protegida para esta conta.',
    es: 'Estamos preparando una configuracion protegida para esta cuenta.',
  );
  static const signupPowPhaseSolveTitle = LocalizedCopy(
    en: 'Checking security',
    pt: 'Verificando seguranca',
    es: 'Verificando seguridad',
  );
  static const signupPowPhaseSolveBody = LocalizedCopy(
    en: 'Your device completes a quick local protection check before continuing.',
    pt: 'Seu aparelho conclui uma verificacao local de protecao antes de continuar.',
    es: 'Tu dispositivo completa una verificacion local de proteccion antes de continuar.',
  );
  static const signupPowPhaseProvisionTitle = LocalizedCopy(
    en: 'Protecting credentials',
    pt: 'Protegendo credenciais',
    es: 'Protegiendo credenciales',
  );
  static const signupPowPhaseProvisionBody = LocalizedCopy(
    en: 'Your authenticator setup is being prepared securely.',
    pt: 'A configuracao do seu autenticador esta sendo preparada com seguranca.',
    es: 'La configuracion de tu autenticador se esta preparando con seguridad.',
  );
  static const signupPowErrorTitle = LocalizedCopy(
    en: 'Could not complete the protection check',
    pt: 'Nao foi possivel concluir a verificacao de protecao',
    es: 'No se pudo completar la verificacion de proteccion',
  );
  static const signupPowEyebrow = LocalizedCopy(
    en: 'Preparation',
    pt: 'Preparacao',
    es: 'Preparación',
  );
  static const signupPowSubtitle = LocalizedCopy(
    en: 'There is a short technical step before the authenticator is released. You do not need to do anything now: the app advances automatically when it finishes.',
    pt: 'Existe uma etapa tecnica curta antes de liberar o autenticador. Voce nao precisa fazer nada agora: o app avanca automaticamente quando terminar.',
    es: 'Hay un paso tecnico corto antes de liberar el autenticador. No necesitas hacer nada ahora: la app avanza automaticamente cuando termina.',
  );
  static const signupPowHighlightLabel = LocalizedCopy(
    en: 'Current status',
    pt: 'Status atual',
    es: 'Estado actual',
  );
  static const signupPowChipAutomatic = LocalizedCopy(
    en: 'Automatic step',
    pt: 'Etapa automatica',
    es: 'Paso automático',
  );
  static const signupPowChipKeepOpen = LocalizedCopy(
    en: 'Keep the app open',
    pt: 'Aguarde com o app aberto',
    es: 'Espera con la app abierta',
  );
  static const signupPowChipAutoAdvance = LocalizedCopy(
    en: 'Automatic advance',
    pt: 'Avanco automatico',
    es: 'Avance automático',
  );
  static const signupPowDeviceTitle = LocalizedCopy(
    en: 'POW',
    pt: 'POW',
    es: 'POW',
  );
  static const signupPowDeviceSubtitle = LocalizedCopy(
    en: 'NONCE SEARCH',
    pt: 'BUSCA DE NONCE',
    es: 'BUSQUEDA DE NONCE',
  );
  static const signupPowNoticeTitle = LocalizedCopy(
    en: 'Immediate feedback',
    pt: 'Feedback imediato',
    es: 'Retroalimentación inmediata',
  );
  static const signupPowNoticeLoading = LocalizedCopy(
    en: 'Keep the app open for a few seconds while the calculation finishes.',
    pt: 'Mantenha o aplicativo aberto por alguns segundos enquanto o calculo termina.',
    es: 'Mantén la aplicación abierta unos segundos mientras termina el cálculo.',
  );
  static const signupPowNoticeReady = LocalizedCopy(
    en: 'Finishing this step before continuing.',
    pt: 'Finalizando esta etapa antes de continuar.',
    es: 'Finalizando este paso antes de continuar.',
  );
  static const signupPowStatusInProgress = LocalizedCopy(
    en: 'IN PROGRESS',
    pt: 'EM PROCESSO',
    es: 'EN PROCESO',
  );
  static const signupPowStatusCompleted = LocalizedCopy(
    en: 'COMPLETED',
    pt: 'CONCLUIDO',
    es: 'COMPLETADO',
  );

  static const passkeyVerificationUserNotFound = LocalizedCopy(
    en: 'User not found',
    pt: 'Usuario nao encontrado',
    es: 'Usuario no encontrado',
  );
  static const passkeyVerificationNoLocal = LocalizedCopy(
    en: 'No local passkey on this device',
    pt: 'Sem passkey neste aparelho',
    es: 'Sin passkey en este dispositivo',
  );
  static const passkeyVerificationCancelled = LocalizedCopy(
    en: 'Verification cancelled',
    pt: 'Verificacao cancelada',
    es: 'Verificación cancelada',
  );
  static const passkeyVerificationChallengeExpired = LocalizedCopy(
    en: 'Time expired',
    pt: 'Tempo expirado',
    es: 'Tiempo expirado',
  );
  static const passkeyVerificationRejected = LocalizedCopy(
    en: 'Passkey rejected',
    pt: 'Passkey rejeitada',
    es: 'Passkey rechazada',
  );
  static const passkeyVerificationFailed = LocalizedCopy(
    en: 'Could not validate passkey',
    pt: 'Falha ao validar a passkey',
    es: 'No fue posible validar la passkey',
  );
  static const passkeyVerificationHeadlinePreparing = LocalizedCopy(
    en: 'Preparing passkey',
    pt: 'Preparando passkey',
    es: 'Preparando passkey',
  );
  static const passkeyVerificationHeadlineSending = LocalizedCopy(
    en: 'Checking device',
    pt: 'Verificando aparelho',
    es: 'Verificando dispositivo',
  );
  static const passkeyVerificationHeadlineDevice = LocalizedCopy(
    en: 'Confirm on your device',
    pt: 'Confirme no dispositivo',
    es: 'Confirma en tu dispositivo',
  );
  static const passkeyVerificationHeadlineSuccess = LocalizedCopy(
    en: 'Passkey validated',
    pt: 'Passkey validada',
    es: 'Passkey validada',
  );
  static const passkeyVerificationBodyPreparing = LocalizedCopy(
    en: 'Starting secure confirmation.',
    pt: 'Iniciando confirmação segura.',
    es: 'Iniciando confirmación segura.',
  );
  static const passkeyVerificationBodySending = LocalizedCopy(
    en: 'Waiting for approval from this device.',
    pt: 'Aguardando aprovação neste aparelho.',
    es: 'Esperando aprobación en este dispositivo.',
  );
  static const passkeyVerificationBodyDevice = LocalizedCopy(
    en: 'Use biometrics, PIN, or local lock.',
    pt: 'Use biometria, PIN ou bloqueio local.',
    es: 'Usa biometría, PIN o bloqueo local.',
  );
  static const passkeyVerificationBodySuccess = LocalizedCopy(
    en: 'Credential accepted. Continuing automatically.',
    pt: 'Credencial aceita. Continuando automaticamente.',
    es: 'Credencial aceptada. Continuando automáticamente.',
  );
  static const passkeyVerificationScreenTitle = LocalizedCopy(
    en: 'Passkey login',
    pt: 'Login com passkey',
    es: 'Acceso con passkey',
  );
  static const passkeyVerificationLocalChip = LocalizedCopy(
    en: 'Local passkey',
    pt: 'Passkey local',
    es: 'Passkey local',
  );
  static const passkeyVerificationRetry = LocalizedCopy(
    en: 'Try again',
    pt: 'Tentar novamente',
    es: 'Intentar de nuevo',
  );
  static const passkeyVerificationUsePassphrase = LocalizedCopy(
    en: 'Use passphrase instead',
    pt: 'Usar frase secreta',
    es: 'Usar frase secreta',
  );
  static const passkeyVerificationBack = LocalizedCopy(
    en: 'Go back and review username',
    pt: 'Voltar e revisar usuario',
    es: 'Volver y revisar usuario',
  );
  static const passkeyVerificationFallbackHint = LocalizedCopy(
    en: 'Use passphrase if this device has no linked passkey.',
    pt: 'Use a passphrase se este aparelho não tiver a passkey vinculada.',
    es: 'Usa la frase secreta si este dispositivo no tiene la passkey vinculada.',
  );

  static const signupFinalPaymentAddressCopiedTitle = LocalizedCopy(
    en: 'Address copied',
    pt: 'Endereco copiado',
    es: 'Dirección copiada',
  );
  static const signupFinalPaymentAddressCopiedBody = LocalizedCopy(
    en: 'Paste the address into your wallet and confirm the last characters before sending.',
    pt: 'Cole o endereco na sua carteira e confira os ultimos caracteres antes de enviar.',
    es: 'Pega la direccion en tu billetera y confirma los ultimos caracteres antes de enviar.',
  );
  static const signupFinalPaymentAmountCopiedTitle = LocalizedCopy(
    en: 'Amount copied',
    pt: 'Valor copiado',
    es: 'Importe copiado',
  );
  static const signupFinalPaymentAmountCopiedBody = LocalizedCopy(
    en: 'Send exactly this amount to avoid mismatches during validation.',
    pt: 'Envie exatamente este montante para evitar divergencias na validacao.',
    es: 'Envía exactamente este importe para evitar divergencias en la validación.',
  );
  static const signupFinalPaymentEyebrow = LocalizedCopy(
    en: 'Activation',
    pt: 'Ativacao',
    es: 'Activación',
  );
  static const signupFinalPaymentLoading = LocalizedCopy(
    en: 'Loading activation data...',
    pt: 'Carregando dados de ativacao...',
    es: 'Cargando datos de activación...',
  );
  static const signupFinalPaymentHighlightExactAmount = LocalizedCopy(
    en: 'Exact amount',
    pt: 'Valor exato',
    es: 'Importe exacto',
  );
  static const signupFinalPaymentHighlightStatus = LocalizedCopy(
    en: 'Status',
    pt: 'Status',
    es: 'Estado',
  );
  static const signupFinalPaymentChipAddress = LocalizedCopy(
    en: 'On-chain address',
    pt: 'Endereco on-chain',
    es: 'Dirección on-chain',
  );
  static const signupFinalPaymentChipTxid = LocalizedCopy(
    en: 'TXID required',
    pt: 'TXID obrigatorio',
    es: 'TXID obligatorio',
  );
  static const signupFinalPaymentChipConfirmations = LocalizedCopy(
    en: '3 network confirmations',
    pt: '3 confirmacoes na rede',
    es: '3 confirmaciones en la red',
  );
  static const signupFinalPaymentSectionCopy = LocalizedCopy(
    en: '1. Copy the amount and address',
    pt: '1. Copie o valor e o endereco',
    es: '1. Copia el importe y la dirección',
  );
  static const signupFinalPaymentExactAmountLabel = LocalizedCopy(
    en: 'EXACT AMOUNT',
    pt: 'VALOR EXATO',
    es: 'IMPORTE EXACTO',
  );
  static const signupFinalPaymentBtcAddressLabel = LocalizedCopy(
    en: 'BTC ADDRESS',
    pt: 'ENDERECO BTC',
    es: 'DIRECCIÓN BTC',
  );
  static const signupFinalPaymentSectionTxid = LocalizedCopy(
    en: '2. Paste the TXID after sending',
    pt: '2. Cole o TXID depois do envio',
    es: '2. Pega el TXID después del envío',
  );
  static const signupFinalPaymentPaste = LocalizedCopy(
    en: 'Paste',
    pt: 'Colar',
    es: 'Pegar',
  );
  static const signupFinalPaymentTxidBody = LocalizedCopy(
    en: 'If your wallet shows the TXID right after sending the transaction, paste it here to start validation.',
    pt: 'Se a sua carteira mostrar o TXID logo apos transmitir a transacao, cole-o aqui para iniciar a validacao.',
    es: 'Si tu billetera muestra el TXID justo despues de transmitir la transaccion, pegalo aqui para iniciar la validacion.',
  );
  static const signupFinalPaymentTxidHint = LocalizedCopy(
    en: 'Paste the on-chain TXID here',
    pt: 'Cole aqui o TXID on-chain',
    es: 'Pega aqui el TXID on-chain',
  );
  static const signupFinalPaymentValidationTitle = LocalizedCopy(
    en: 'Could not validate',
    pt: 'Nao foi possivel validar',
    es: 'No se pudo validar',
  );
  static const signupFinalPaymentTrackTitle = LocalizedCopy(
    en: '3. Follow the confirmation',
    pt: '3. Acompanhe a confirmacao',
    es: '3. Sigue la confirmación',
  );
  static const signupFinalPaymentPollingExpired = LocalizedCopy(
    en: 'Link expired',
    pt: 'Link expirado',
    es: 'Enlace expirado',
  );
  static const signupFinalPaymentPollingDetected = LocalizedCopy(
    en: 'Payment detected',
    pt: 'Pagamento identificado',
    es: 'Pago detectado',
  );
  static const signupFinalPaymentPollingRunning = LocalizedCopy(
    en: 'Public polling in progress',
    pt: 'Polling publico em andamento',
    es: 'Polling público en curso',
  );
  static const signupFinalPaymentPollingBody = LocalizedCopy(
    en: 'This voucher is being monitored via /voucher/onboarding-link/{linkId} without authentication.',
    pt: 'Este voucher esta sendo monitorado por /voucher/onboarding-link/{linkId} sem exigir autenticacao.',
    es: 'Este voucher se monitorea via /voucher/onboarding-link/{linkId} sin autenticación.',
  );

  static const transactionAuthPassphraseTitle = LocalizedCopy(
    en: 'Passphrase confirmation',
    pt: 'Confirmacao da Passphrase',
    es: 'Confirmación de la passphrase',
  );
  static const transactionAuthPassphraseSubtitle = LocalizedCopy(
    en: 'Enter your passphrase to authorize this transaction',
    pt: 'Digite sua passphrase para autorizar esta transacao',
    es: 'Ingresa tu passphrase para autorizar esta transacción',
  );
  static const transactionAuthVaultTitle = LocalizedCopy(
    en: 'Vault confirmation',
    pt: 'Confirmacao do Cofre',
    es: 'Confirmación de la bóveda',
  );
  static const transactionAuthVaultSubtitle = LocalizedCopy(
    en: 'Enter your passphrase to release this transaction',
    pt: 'Digite sua passphrase para liberar esta transacao',
    es: 'Ingresa tu passphrase para liberar esta transacción',
  );
  static const transactionAuthTotpTitle = LocalizedCopy(
    en: 'Authenticator (TOTP)',
    pt: 'Autenticador (TOTP)',
    es: 'Autenticador (TOTP)',
  );
  static const transactionAuthTotpSubtitle = LocalizedCopy(
    en: 'Enter the 6-digit code from your authenticator app',
    pt: 'Digite o codigo de 6 digitos do seu app autenticador',
    es: 'Ingresa el código de 6 dígitos de tu app autenticadora',
  );
  static const transactionAuthTotpLabel = LocalizedCopy(
    en: '6-digit code',
    pt: 'Codigo de 6 digitos',
    es: 'Código de 6 dígitos',
  );
  static const transactionAuthPassphraseLabel = LocalizedCopy(
    en: 'Passphrase',
    pt: 'Passphrase',
    es: 'Passphrase',
  );
  static const transactionAuthPassphraseRequired = LocalizedCopy(
    en: 'Passphrase is required.',
    pt: 'Passphrase obrigatoria.',
    es: 'La passphrase es obligatoria.',
  );
  static const transactionAuthCodeInvalid = LocalizedCopy(
    en: 'Incorrect code. Try again.',
    pt: 'Codigo incorreto. Tente novamente.',
    es: 'Codigo incorrecto. Intentalo de nuevo.',
  );
  static const transactionAuthVerify = LocalizedCopy(
    en: 'VERIFY',
    pt: 'VERIFICAR',
    es: 'VERIFICAR',
  );
  static const transactionAuthOperationTitle = LocalizedCopy(
    en: 'Operation authorization',
    pt: 'Autorizacao da operacao',
    es: 'Autorizacion de la operacion',
  );
  static const transactionAuthConfirmationPassphraseLabel = LocalizedCopy(
    en: 'Confirmation passphrase',
    pt: 'Passphrase de confirmacao',
    es: 'Passphrase de confirmacion',
  );
  static const transactionAuthEnterPassphrase = LocalizedCopy(
    en: 'Enter your passphrase.',
    pt: 'Informe sua passphrase.',
    es: 'Ingresa tu passphrase.',
  );
  static const transactionAuthTotpCodeLabel = LocalizedCopy(
    en: 'TOTP code',
    pt: 'Codigo TOTP',
    es: 'Codigo TOTP',
  );
  static const transactionAuthEnterAuthenticatorDigits = LocalizedCopy(
    en: 'Enter the 6 digits from your authenticator.',
    pt: 'Informe os 6 digitos do autenticador.',
    es: 'Ingresa los 6 digitos del autenticador.',
  );
  static const transactionAuthPasskeyChallengeTitle = LocalizedCopy(
    en: 'Passkey confirmation',
    pt: 'Confirmacao por passkey',
    es: 'Confirmacion por passkey',
  );
  static const transactionAuthPasskeyChallengeMessage = LocalizedCopy(
    en: 'If this operation requires passkey, the app will ask for biometric confirmation before sending it.',
    pt: 'Se esta operacao exigir passkey, o app vai pedir confirmacao biometrica antes do envio.',
    es: 'Si esta operacion exige passkey, la app pedira confirmacion biometrica antes del envio.',
  );
  static const transactionAuthContinue = LocalizedCopy(
    en: 'CONTINUE',
    pt: 'CONTINUAR',
    es: 'CONTINUAR',
  );
  static const transactionAuthShamirTitle = LocalizedCopy(
    en: 'Shamir authorization',
    pt: 'Autorizacao Shamir',
    es: 'Autorizacion Shamir',
  );
  static const transactionAuthReconstructAndContinue = LocalizedCopy(
    en: 'RECONSTRUCT AND CONTINUE',
    pt: 'RECONSTRUIR E CONTINUAR',
    es: 'RECONSTRUIR Y CONTINUAR',
  );
  static const transactionAuthShareHint = LocalizedCopy(
    en: 'Paste the full share here',
    pt: 'Cole a share completa aqui',
    es: 'Pega la share completa aqui',
  );

  static const signupFlowCreateAccount = LocalizedCopy(
    en: 'Create account',
    pt: 'Criar conta',
    es: 'Crear cuenta',
  );
  static const signupFlowPhasePreparation = LocalizedCopy(
    en: 'Preparation',
    pt: 'Preparacao',
    es: 'Preparación',
  );
  static const signupFlowPhaseProtection = LocalizedCopy(
    en: 'Protection',
    pt: 'Protecao',
    es: 'Protección',
  );
  static const signupFlowPhaseActivation = LocalizedCopy(
    en: 'Activation',
    pt: 'Ativacao',
    es: 'Activación',
  );
  static const signupFlowGuidedStepsChip = LocalizedCopy(
    en: '10 guided steps',
    pt: '10 etapas guiadas',
    es: '10 pasos guiados',
  );
  static const signupFlowRequired2faChip = LocalizedCopy(
    en: '2FA required',
    pt: '2FA obrigatorio',
    es: '2FA obligatorio',
  );
  static const signupFlowDevicePasskeyChip = LocalizedCopy(
    en: 'Passkey on this device',
    pt: 'Passkey neste aparelho',
    es: 'Passkey en este dispositivo',
  );
  static const signupFlowThreeConfirmationsChip = LocalizedCopy(
    en: '3 network confirmations',
    pt: '3 confirmacoes na rede',
    es: '3 confirmaciones en la red',
  );

  static String _resolve(
    BuildContext context, {
    required String en,
    required String pt,
    required String es,
  }) {
    return LocalizedCopy(en: en, pt: pt, es: es).resolve(context);
  }

  static String presentationActivationCurrentAmount(
    BuildContext context,
    String amount,
  ) {
    final copy = LocalizedCopy(
      en: 'Current quoted amount: $amount',
      pt: 'Valor atual consultado: $amount',
      es: 'Importe consultado ahora: $amount',
    );
    return copy.resolve(context);
  }

  static String depositCurrencyDescription(
    BuildContext context, {
    required bool isBtc,
    required String code,
  }) {
    final copy = isBtc
        ? const LocalizedCopy(
            en: 'This currency follows the app setting. This operation is in BTC.',
            pt: 'A moeda segue a configuracao geral do app. Esta operacao esta em BTC.',
            es: 'La moneda sigue la configuración general de la app. Esta operación está en BTC.',
          )
        : LocalizedCopy(
            en: 'This currency follows the app setting. This operation is in $code.',
            pt: 'A moeda segue a configuracao geral do app. Esta operacao esta em $code.',
            es: 'La moneda sigue la configuración general de la app. Esta operación está en $code.',
          );
    return copy.resolve(context);
  }

  static String homeLoadingTitle(
    BuildContext context, {
    required bool hasError,
    required bool isQuoteBlocking,
    required bool isDelayed,
  }) {
    if (hasError) return homeLoadingAuthFailure.resolve(context);
    if (isQuoteBlocking && isDelayed) {
      return homeLoadingQuoteUnavailable.resolve(context);
    }
    if (isDelayed) return homeLoadingSlowConnection.resolve(context);
    return homeLoadingSyncing.resolve(context);
  }

  static String homeLoadingBody(
    BuildContext context, {
    required bool hasError,
    required bool isQuoteBlocking,
    required bool isDelayed,
  }) {
    if (hasError) return homeLoadingAccessDenied.resolve(context);
    if (isQuoteBlocking && isDelayed) {
      return homeLoadingQuoteBlockingBody.resolve(context);
    }
    if (isDelayed) return homeLoadingTorRetryBody.resolve(context);
    return homeLoadingSecureAssetsBody.resolve(context);
  }

  static String homeLoadingRetryLabel(
    BuildContext context, {
    required bool hasError,
    required bool isQuoteBlocking,
  }) {
    if (hasError) return homeLoadingTryAgain.resolve(context);
    if (isQuoteBlocking) return homeLoadingReloadQuotes.resolve(context);
    return homeLoadingRepeatSync.resolve(context);
  }

  static String createWalletHeaderTitle(
    BuildContext context, {
    required bool hasGenerated,
  }) {
    return (hasGenerated
            ? createWalletProtectSeed
            : createWalletDefineParameters)
        .resolve(context);
  }

  static String createWalletHeaderBody(
    BuildContext context, {
    required bool hasGenerated,
  }) {
    return (hasGenerated
            ? createWalletProtectSeedBody
            : createWalletDefineParametersBody)
        .resolve(context);
  }

  static String withdrawReviewAddressPrompt(
    BuildContext context, {
    required bool isLightning,
  }) {
    return (isLightning
            ? withdrawReviewPasteLightning
            : withdrawReviewPasteBitcoinAddress)
        .resolve(context);
  }

  static String withdrawReviewTitle(
    BuildContext context, {
    required bool isLightning,
  }) {
    return (isLightning
            ? withdrawReviewLightningTitle
            : withdrawReviewOnChainTitle)
        .resolve(context);
  }

  static String withdrawReviewEmptyError(
    BuildContext context, {
    required bool isLightning,
  }) {
    return (isLightning
            ? withdrawReviewLightningEmpty
            : withdrawReviewOnChainEmpty)
        .resolve(context);
  }

  static String withdrawReceiptDestinationLabel(
    BuildContext context, {
    required bool isLightning,
  }) {
    return (isLightning ? withdrawReceiptInvoice : withdrawReceiptWallet)
        .resolve(context);
  }

  static String signupSeedConfirmationSlip39(
    BuildContext context, {
    required int threshold,
    required int totalShares,
  }) {
    return _resolve(
      context,
      en: 'I confirm that I wrote each share down separately and understand that I need $threshold of $totalShares shares to recover the account.',
      pt: 'Confirmei que anotei cada parte separadamente e entendo que preciso de $threshold de $totalShares partes para recuperar a conta.',
      es: 'Confirmo que anote cada parte por separado y entiendo que necesito $threshold de $totalShares partes para recuperar la cuenta.',
    );
  }

  static String signupSecurityMultisigHighlightHint(
    BuildContext context, {
    required int threshold,
  }) {
    return _resolve(
      context,
      en: threshold == 3
          ? '3 factors: passphrase, TOTP, and passkey.'
          : '2 factors: passphrase and TOTP.',
      pt: threshold == 3
          ? '3 fatores: passphrase, TOTP e passkey.'
          : '2 fatores: passphrase e TOTP.',
      es: threshold == 3
          ? '3 factores: passphrase, TOTP y passkey.'
          : '2 factores: passphrase y TOTP.',
    );
  }

  static String signupSecurityMultisigSummary(
    BuildContext context, {
    required int threshold,
  }) {
    return _resolve(
      context,
      en: threshold == 3
          ? 'Maximum institutional policy: passphrase + TOTP + passkey.'
          : 'Balanced institutional policy: passphrase + TOTP.',
      pt: threshold == 3
          ? 'Politica institucional maxima: passphrase + TOTP + passkey.'
          : 'Politica institucional equilibrada: passphrase + TOTP.',
      es: threshold == 3
          ? 'Politica institucional maxima: passphrase + TOTP + passkey.'
          : 'Politica institucional equilibrada: passphrase + TOTP.',
    );
  }

  static String signupVerificationSubtitle(
    BuildContext context, {
    required int missingCount,
  }) {
    return _resolve(
      context,
      en: 'Fill in the $missingCount missing words. This helps prevent moving forward without checking the phrase carefully.',
      pt: 'Preencha as $missingCount palavras faltantes. Esta etapa ajuda a evitar que voce continue sem conferir a frase com atencao.',
      es: 'Completa las $missingCount palabras faltantes. Esto evita avanzar sin revisar la frase con cuidado.',
    );
  }

  static String signupFinalPaymentTitle(
    BuildContext context, {
    required String paymentStatus,
  }) {
    switch (paymentStatus) {
      case 'completed':
        return _resolve(
          context,
          en: 'Payment completed',
          pt: 'Pagamento concluido',
          es: 'Pago completado',
        );
      case 'verifying_onboarding':
        return _resolve(
          context,
          en: 'Payment under validation',
          pt: 'Pagamento em validacao',
          es: 'Pago en validación',
        );
      default:
        return _resolve(
          context,
          en: 'Activate your account',
          pt: 'Ative sua conta',
          es: 'Activa tu cuenta',
        );
    }
  }

  static String signupFinalPaymentSubtitle(
    BuildContext context, {
    required String paymentStatus,
  }) {
    switch (paymentStatus) {
      case 'completed':
        return _resolve(
          context,
          en: 'The public onboarding flow confirmed the payment. You can now continue to finish activation.',
          pt: 'O onboarding publico confirmou o pagamento. Agora voce pode prosseguir para finalizar a ativacao.',
          es: 'El onboarding publico confirmo el pago. Ahora puedes continuar para finalizar la activación.',
        );
      case 'verifying_onboarding':
        return _resolve(
          context,
          en: 'Your TXID has already been submitted. Now just wait for network confirmations.',
          pt: 'Seu TXID ja foi enviado. Agora basta acompanhar as confirmacoes na rede.',
          es: 'Tu TXID ya fue enviado. Ahora solo espera las confirmaciones de la red.',
        );
      default:
        return _resolve(
          context,
          en: 'Copy the exact amount, send it to the shown address, and then paste the TXID to start validation.',
          pt: 'Copie o valor exato, envie para o endereco indicado e depois cole o TXID para iniciar a validacao.',
          es: 'Copia el importe exacto, envialo a la direccion indicada y luego pega el TXID para iniciar la validación.',
        );
    }
  }

  static String signupFinalPaymentHighlightValue(
    BuildContext context, {
    required String paymentStatus,
    required String amountBtc,
  }) {
    if (paymentStatus == 'completed') {
      return _resolve(
        context,
        en: 'Ready to finish',
        pt: 'Pronto para finalizar',
        es: 'Listo para finalizar',
      );
    }
    if (paymentStatus == 'verifying_onboarding') {
      return _resolve(
        context,
        en: 'Waiting for confirmations',
        pt: 'Aguardando confirmacoes',
        es: 'Esperando confirmaciones',
      );
    }
    return '$amountBtc BTC';
  }

  static String signupFinalPaymentDefaultHint(BuildContext context) {
    return _resolve(
      context,
      en: 'The account will be activated automatically after 3 confirmations on the network.',
      pt: 'A conta sera ativada automaticamente apos 3 confirmacoes na rede.',
      es: 'La cuenta se activara automaticamente despues de 3 confirmaciones en la red.',
    );
  }

  static String signupFinalPaymentCta(
    BuildContext context, {
    required String paymentStatus,
    required bool isSubmitting,
  }) {
    if (paymentStatus == 'completed') {
      return _resolve(
        context,
        en: 'Continue to finish',
        pt: 'Prosseguir para finalizar',
        es: 'Continuar para finalizar',
      );
    }
    if (paymentStatus == 'verifying_onboarding') {
      return _resolve(
        context,
        en: 'Waiting for confirmations',
        pt: 'Aguardando confirmacoes',
        es: 'Esperando confirmaciones',
      );
    }
    if (isSubmitting) {
      return _resolve(
        context,
        en: 'Validating TXID...',
        pt: 'Validando TXID...',
        es: 'Validando TXID...',
      );
    }
    return _resolve(
      context,
      en: 'I sent it, validate TXID',
      pt: 'Ja enviei, validar TXID',
      es: 'Ya lo envie, validar TXID',
    );
  }

  static String signupFinalPaymentSubmittedTxid(
    BuildContext context, {
    required String txid,
  }) {
    return _resolve(
      context,
      en: 'Submitted TXID: $txid',
      pt: 'TXID enviado: $txid',
      es: 'TXID enviado: $txid',
    );
  }

  static String signupFinalPaymentFooterCaption(
    BuildContext context, {
    required String paymentStatus,
  }) {
    if (paymentStatus == 'completed') {
      return _resolve(
        context,
        en: 'The public link has already been validated. Tap to finish onboarding.',
        pt: 'O link publico ja foi validado. Toque para finalizar o onboarding.',
        es: 'El enlace publico ya fue validado. Toca para finalizar el onboarding.',
      );
    }
    return _resolve(
      context,
      en: 'This voucher status keeps being polled without authentication while payment is pending.',
      pt: 'O status deste voucher continua sendo consultado sem autenticacao enquanto o pagamento estiver pendente.',
      es: 'El estado de este voucher se sigue consultando sin autenticación mientras el pago siga pendiente.',
    );
  }

  static String signupFlowPhaseTitle(
    BuildContext context, {
    required int step,
  }) {
    if (step <= 2) {
      return _resolve(context, en: 'START', pt: 'COMECO', es: 'INICIO');
    }
    if (step <= 8) {
      return _resolve(context,
          en: 'PROTECTION', pt: 'PROTECAO', es: 'PROTECCIÓN');
    }
    return _resolve(context,
        en: 'ACTIVATION', pt: 'ATIVACAO', es: 'ACTIVACIÓN');
  }

  static String signupFlowPhaseSubtitle(
    BuildContext context, {
    required int step,
  }) {
    if (step <= 2) {
      return _resolve(
        context,
        en: 'Essential data and initial choice',
        pt: 'Dados essenciais e escolha inicial',
        es: 'Datos esenciales y elección inicial',
      );
    }
    if (step <= 8) {
      return _resolve(
        context,
        en: 'Backup, 2FA, and device security',
        pt: 'Backup, 2FA e seguranca do aparelho',
        es: 'Respaldo, 2FA y seguridad del dispositivo',
      );
    }
    return _resolve(
      context,
      en: 'Initial deposit and account confirmation',
      pt: 'Deposito inicial e confirmacao da conta',
      es: 'Deposito inicial y confirmación de la cuenta',
    );
  }

  static String signupFlowStepTitle(
    BuildContext context, {
    required int step,
    required String securityOption,
  }) {
    if (securityOption == 'slip39' && step == 3) {
      return _resolve(
        context,
        en: 'Store your shares',
        pt: 'Guarde suas partes',
        es: 'Guarda tus partes',
      );
    }
    if (securityOption == 'slip39' && step == 4) {
      return _resolve(
        context,
        en: 'Review your shares',
        pt: 'Revise suas partes',
        es: 'Revisa tus partes',
      );
    }
    if (securityOption == 'multisig2fa' && step == 3) {
      return _resolve(
        context,
        en: 'Store your vault keys',
        pt: 'Guarde as chaves do cofre',
        es: 'Guarda las claves de la bóveda',
      );
    }
    if (securityOption == 'multisig2fa' && step == 4) {
      return _resolve(
        context,
        en: 'Verify the primary seed',
        pt: 'Verifique a seed principal',
        es: 'Verifica la seed principal',
      );
    }

    switch (step) {
      case 0:
        return _resolve(context,
            en: 'Before you start',
            pt: 'Antes de comecar',
            es: 'Antes de empezar');
      case 1:
        return _resolve(context,
            en: 'How you will store access',
            pt: 'Como voce vai guardar o acesso',
            es: 'Como vas a guardar el acceso');
      case 2:
        return _resolve(context,
            en: 'Username', pt: 'Nome de usuario', es: 'Nombre de usuario');
      case 3:
        return _resolve(context,
            en: 'Store your phrase',
            pt: 'Guarde sua frase',
            es: 'Guarda tu frase');
      case 4:
        return _resolve(context,
            en: 'Confirm your backup',
            pt: 'Confirme seu backup',
            es: 'Confirma tu respaldo');
      case 5:
        return _resolve(context,
            en: 'Prepare secure access',
            pt: 'Preparar acesso seguro',
            es: 'Preparar acceso seguro');
      case 6:
        return _resolve(context,
            en: 'Preparing your account',
            pt: 'Preparando sua conta',
            es: 'Preparando tu cuenta');
      case 7:
        return _resolve(context,
            en: 'Set up authenticator',
            pt: 'Configurar autenticador',
            es: 'Configurar autenticador');
      case 8:
        return _resolve(context,
            en: 'Protect this device',
            pt: 'Proteger este aparelho',
            es: 'Proteger este dispositivo');
      default:
        return _resolve(context,
            en: 'Activate account', pt: 'Ativar conta', es: 'Activar cuenta');
    }
  }

  static String signupFlowStepDescription(
    BuildContext context, {
    required int step,
    required String securityOption,
  }) {
    if (securityOption == 'slip39' && step == 3) {
      return _resolve(
        context,
        en: 'Your main phrase will be split into SLIP-39 shares. Store each share separately.',
        pt: 'Sua frase principal sera dividida em partes SLIP-39. Salve cada parte separadamente.',
        es: 'Tu frase principal se dividira en partes SLIP-39. Guarda cada parte por separado.',
      );
    }
    if (securityOption == 'slip39' && step == 4) {
      return _resolve(
        context,
        en: 'Confirm that you understand how many shares are required to recover the account.',
        pt: 'Confirme que voce entendeu quantas partes sao necessarias para recuperar a conta.',
        es: 'Confirma que entendiste cuantas partes son necesarias para recuperar la cuenta.',
      );
    }
    if (securityOption == 'multisig2fa' && step == 3) {
      return _resolve(
        context,
        en: 'The vault now generates a primary seed and a separate sovereignty recovery seed. They must not be stored together.',
        pt: 'O cofre agora gera uma seed principal e uma seed de recuperacao soberana separada. Elas nao devem ser guardadas juntas.',
        es: 'La bóveda ahora genera una seed principal y una seed de recuperación soberana separada. No deben guardarse juntas.',
      );
    }
    if (securityOption == 'multisig2fa' && step == 4) {
      return _resolve(
        context,
        en: 'Validate the primary seed before moving on, while keeping the recovery seed stored separately for emergency use.',
        pt: 'Valide a seed principal antes de seguir, mantendo a seed de recuperacao guardada separadamente para emergencias.',
        es: 'Valida la seed principal antes de seguir, manteniendo la seed de recuperación guardada por separado para emergencias.',
      );
    }

    switch (step) {
      case 0:
        return _resolve(
          context,
          en: 'Review what you need nearby to finish without interruptions.',
          pt: 'Confira o que voce precisa ter por perto para terminar sem interrupcoes.',
          es: 'Revisa lo que necesitas tener cerca para terminar sin interrupciones.',
        );
      case 1:
        return _resolve(
          context,
          en: 'Choose the backup model you can realistically operate day to day.',
          pt: 'Escolha o modelo de backup que voce realmente consegue operar no dia a dia.',
          es: 'Elige el modelo de respaldo que realmente puedas operar en el dia a dia.',
        );
      case 2:
        return _resolve(
          context,
          en: 'Define how you will sign in and be identified inside the platform.',
          pt: 'Defina como voce vai entrar e ser reconhecido dentro da plataforma.',
          es: 'Define como vas a iniciar sesion y ser reconocido dentro de la plataforma.',
        );
      case 3:
        return _resolve(
          context,
          en: 'Write your recovery data offline. It cannot be shown again later.',
          pt: 'Anote sua recuperacao offline. Ela nao podera ser exibida de novo depois.',
          es: 'Anota tu recuperacion offline. No podra mostrarse de nuevo despues.',
        );
      case 4:
        return _resolve(
          context,
          en: 'Run a quick check to avoid moving forward with the wrong backup.',
          pt: 'Faca uma checagem rapida para evitar seguir com o backup errado.',
          es: 'Haz una revision rapida para evitar avanzar con el respaldo equivocado.',
        );
      case 5:
        return _resolve(
          context,
          en: 'Review your setup before creating the secure access credentials.',
          pt: 'Revise sua configuracao antes de criar as credenciais de acesso.',
          es: 'Revisa tu configuracion antes de crear las credenciales de acceso.',
        );
      case 6:
        return _resolve(
          context,
          en: 'The device completes the required technical step before unlocking 2FA.',
          pt: 'O aparelho conclui a etapa tecnica exigida antes de liberar o 2FA.',
          es: 'El dispositivo completa el paso técnico requerido antes de liberar el 2FA.',
        );
      case 7:
        return _resolve(
          context,
          en: 'Scan, store the codes, and validate 2FA before continuing.',
          pt: 'Escaneie, guarde seus codigos e valide o 2FA antes de continuar.',
          es: 'Escanea, guarda tus códigos y valida el 2FA antes de continuar.',
        );
      case 8:
        return _resolve(
          context,
          en: 'Enable biometrics or device lock to protect access on this device.',
          pt: 'Ative biometria ou bloqueio local para proteger o acesso neste dispositivo.',
          es: 'Activa biometria o bloqueo local para proteger el acceso en este dispositivo.',
        );
      default:
        return _resolve(
          context,
          en: 'Finish the passkey step to complete signup.',
          pt: 'Finalize a etapa de passkey para concluir o cadastro.',
          es: 'Finaliza la etapa de passkey para completar el registro.',
        );
    }
  }

  static String signupFlowSecurityLabel(
    BuildContext context, {
    required String option,
  }) {
    switch (option) {
      case 'slip39':
        return 'SLIP-39';
      case 'multisig2fa':
        return signupSecurityMultisigTitle.resolve(context);
      default:
        return signupSecurityStandardTitle.resolve(context);
    }
  }

  static String signupFlowHeroHighlightLabel(
    BuildContext context, {
    required bool hasPaymentRequired,
    required int currentStep,
    required bool hasUsername,
  }) {
    if (hasPaymentRequired) {
      return _resolve(context,
          en: 'Deposit inside the app',
          pt: 'Depósito no app',
          es: 'Depósito en la app');
    }
    if (currentStep >= 8) {
      return _resolve(context,
          en: 'Security active', pt: 'Seguranca ativa', es: 'Seguridad activa');
    }
    if (hasUsername) {
      return _resolve(context,
          en: 'Account in progress',
          pt: 'Conta em criacao',
          es: 'Cuenta en creación');
    }
    return _resolve(context,
        en: 'Average time', pt: 'Tempo medio', es: 'Tiempo medio');
  }

  static String signupFlowHeroHighlightValue(
    BuildContext context, {
    required bool hasPaymentRequired,
    String? paymentAmountBtc,
    required int currentStep,
    String? username,
  }) {
    if (hasPaymentRequired && paymentAmountBtc != null) {
      return '$paymentAmountBtc BTC';
    }
    if (currentStep >= 8) {
      return _resolve(context,
          en: 'Biometrics on this device',
          pt: 'Biometria neste aparelho',
          es: 'Biometria en este dispositivo');
    }
    if (username != null && username.isNotEmpty) {
      return '@$username';
    }
    if (currentStep <= 2) {
      return _resolve(context,
          en: 'Under 2 min', pt: 'Menos de 2 min', es: 'Menos de 2 min');
    }
    if (currentStep <= 5) {
      return _resolve(context,
          en: 'About 4 min', pt: 'Cerca de 4 min', es: 'Cerca de 4 min');
    }
    return _resolve(context,
        en: 'Guided step', pt: 'Etapa guiada', es: 'Paso guiado');
  }

  static String signupFlowHeroHighlightHint(
    BuildContext context, {
    required bool hasPaymentRequired,
    required int currentStep,
    required bool hasUsername,
  }) {
    if (hasPaymentRequired) {
      return _resolve(
        context,
        en: 'Copy the amount exactly as shown to avoid mismatches.',
        pt: 'Copie o valor exatamente como exibido para evitar divergencias.',
        es: 'Copia el importe exactamente como se muestra para evitar diferencias.',
      );
    }
    if (currentStep >= 8) {
      return _resolve(
        context,
        en: 'Your access now requires local confirmation from this device.',
        pt: 'Seu acesso passa a exigir confirmacao local deste dispositivo.',
        es: 'Tu acceso ahora exige confirmación local de este dispositivo.',
      );
    }
    if (hasUsername) {
      return _resolve(
        context,
        en: 'This identifier will be used to sign in to your account.',
        pt: 'Esse identificador sera usado para entrar na sua conta.',
        es: 'Este identificador se usara para entrar en tu cuenta.',
      );
    }
    return _resolve(
      context,
      en: 'The flow is linear and only shows what matters at each step.',
      pt: 'O fluxo e linear e mostra so o que importa em cada etapa.',
      es: 'El flujo es lineal y solo muestra lo que importa en cada paso.',
    );
  }

  static String signupFlowStepProgress(
    BuildContext context, {
    required int current,
    required int total,
  }) {
    return _resolve(
      context,
      en: 'Step $current of $total',
      pt: 'Etapa $current de $total',
      es: 'Paso $current de $total',
    );
  }

  static String transactionAuthProfileSubtitle(
    BuildContext context, {
    required bool isMultisig,
    required int multisigThreshold,
    required bool isPasskeyOnly,
  }) {
    if (isMultisig) {
      return _resolve(
        context,
        en: multisigThreshold >= 3
            ? 'This policy uses passphrase, TOTP, and passkey to release critical operations.'
            : 'This policy uses passphrase and TOTP to release critical operations.',
        pt: multisigThreshold >= 3
            ? 'Esta politica usa passphrase, TOTP e passkey para liberar operacoes criticas.'
            : 'Esta politica usa passphrase e TOTP para liberar operacoes criticas.',
        es: multisigThreshold >= 3
            ? 'Esta politica usa passphrase, TOTP y passkey para liberar operaciones criticas.'
            : 'Esta politica usa passphrase y TOTP para liberar operaciones criticas.',
      );
    }

    if (isPasskeyOnly) {
      return _resolve(
        context,
        en: 'Final confirmation will be requested with your passkey.',
        pt: 'A confirmacao final sera solicitada com sua passkey.',
        es: 'La confirmacion final se solicitara con tu passkey.',
      );
    }

    return _resolve(
      context,
      en: 'Provide the required factors to complete this operation.',
      pt: 'Forneca os fatores exigidos para concluir esta operacao.',
      es: 'Proporciona los factores requeridos para completar esta operacion.',
    );
  }

  static String transactionAuthShamirRecoveryError(
    BuildContext context, {
    required int threshold,
  }) {
    return _resolve(
      context,
      en: 'Enter $threshold full shares to reconstruct the passphrase.',
      pt: 'Informe $threshold shares completas para reconstruir a passphrase.',
      es: 'Ingresa $threshold shares completas para reconstruir la passphrase.',
    );
  }

  static String transactionAuthShamirReconstructFailed(
    BuildContext context,
  ) {
    return _resolve(
      context,
      en: 'The passphrase could not be reconstructed. Review the shares and try again.',
      pt: 'Nao foi possivel reconstruir a passphrase. Revise as shares e tente novamente.',
      es: 'No fue posible reconstruir la passphrase. Revisa las shares e intenta de nuevo.',
    );
  }

  static String transactionAuthShamirSubtitle(
    BuildContext context, {
    required int threshold,
    required int totalShares,
  }) {
    return _resolve(
      context,
      en: 'Reconstruct the passphrase with $threshold of $totalShares shares before releasing the operation.',
      pt: 'Reconstrua a passphrase com $threshold de $totalShares shares antes de liberar a operacao.',
      es: 'Reconstruye la passphrase con $threshold de $totalShares shares antes de liberar la operacion.',
    );
  }

  static String transactionAuthShareLabel(
    BuildContext context, {
    required int index,
  }) {
    return _resolve(
      context,
      en: 'Share $index',
      pt: 'Share $index',
      es: 'Share $index',
    );
  }
}
