import '../localized_copy.dart';

class AppCopyPart3 {
  AppCopyPart3._();

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
}
