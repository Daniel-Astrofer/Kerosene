// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Kerosene';

  @override
  String get home => 'Inicio';

  @override
  String get market => 'Mercado';

  @override
  String get totalBalance => 'Saldo Total (BTC)';

  @override
  String get totalBalanceGeneric => 'Saldo Total';

  @override
  String get myWallets => 'Mis Billeteras';

  @override
  String get actions => 'Acciones';

  @override
  String get send => 'Enviar';

  @override
  String get receive => 'Recibir';

  @override
  String get addFunds => 'Agregar Fondos';

  @override
  String get addCard => 'AGREGAR TARJETA';

  @override
  String get manual => 'MANUAL';

  @override
  String get qrCode => 'Código QR';

  @override
  String get nfc => 'NFC';

  @override
  String get howMuchToReceive => '¿Cuánto quieres recibir?';

  @override
  String get fixedAmountByRequest => 'VALOR FIJADO POR SOLICITUD';

  @override
  String get recipientData => 'DATOS DEL DESTINATARIO';

  @override
  String get recipientHint => 'Usuario o dirección BTC';

  @override
  String get descriptionHint => 'Descripción (opcional)';

  @override
  String get next => 'SIGUIENTE';

  @override
  String get reviewSend => 'REVISAR ENVÍO';

  @override
  String get recipient => 'Destinatario';

  @override
  String get description => 'DESCRIPCIÓN';

  @override
  String get networkFee => 'Tarifa de Red';

  @override
  String get free => 'GRATIS';

  @override
  String get confirm => 'CONFIRMAR';

  @override
  String get securityTotp => 'SEGURIDAD (TOTP)';

  @override
  String get destinationAddressHint => 'Dirección BTC de destino';

  @override
  String get totpHint => '6 dígitos de tu autenticador';

  @override
  String get confirmWithdraw => 'CONFIRMAR RETIRO';

  @override
  String get recentTransactions => 'Transacciones Recientes';

  @override
  String get viewAll => 'Ver Todas';

  @override
  String get noTransactions => 'No se encontraron transacciones';

  @override
  String get bitcoinTrading => 'Comercio Bitcoin';

  @override
  String get marketStats => 'Estadísticas del Mercado';

  @override
  String get high24h => 'Máximo 24h';

  @override
  String get low24h => 'Mínimo 24h';

  @override
  String get totalVolume24h => 'Volumen Total (24h)';

  @override
  String get fiatVolume => 'Volumen Fiat';

  @override
  String get security => 'Seguridad';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get language => 'Idioma';

  @override
  String get logout => 'Cerrar Sesión';

  @override
  String get wallets => 'Billeteras';

  @override
  String get totalVolume => 'Volumen Total';

  @override
  String get depositAddress => 'Dirección de Depósito';

  @override
  String get platformDepositAddress => 'Dirección de Depósito de la Plataforma';

  @override
  String get amount => 'Cantidad';

  @override
  String get sourceWallet => 'Billetera de Origen';

  @override
  String get generatePaymentLink => 'Generar Enlace de Pago';

  @override
  String get paymentInstructions => 'Instrucciones de Pago';

  @override
  String get sendExactAmount =>
      'Envíe exactamente esta cantidad a la dirección a continuación:';

  @override
  String get fundsWillBeCredited =>
      'Los fondos se acreditarán después de la confirmación de la red';

  @override
  String get close => 'Cerrar';

  @override
  String get addressCopied => '¡Dirección copiada!';

  @override
  String get destinationAddress => 'Dirección de Destino';

  @override
  String get estimatedFee => 'Tarifa Estimada';

  @override
  String get total => 'Total';

  @override
  String get confirmSend => 'Confirmar y Enviar';

  @override
  String get scanQR => 'Escanear QR';

  @override
  String get pasteAddress => 'Pegar Dirección';

  @override
  String get transactionDetails => 'Detalles de la Transacción';

  @override
  String get status => 'Estado';

  @override
  String get value => 'Valor';

  @override
  String get fee => 'Tarifa';

  @override
  String get hash => 'Hash';

  @override
  String get date => 'Fecha';

  @override
  String get confirmed => 'Confirmada';

  @override
  String get pending => 'Pendiente';

  @override
  String get failed => 'Fallida';

  @override
  String helloUser(String name) {
    return 'Hola, $name!';
  }

  @override
  String get welcome => 'Bienvenido';

  @override
  String get getStarted => 'Comenzar';

  @override
  String get login => 'Iniciar Sesión';

  @override
  String get register => 'Registrarse';

  @override
  String get email => 'Correo Electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get confirmPassword => 'Confirmar Contraseña';

  @override
  String get name => 'Nombre';

  @override
  String get error => 'Error';

  @override
  String get success => 'Éxito';

  @override
  String get loading => 'Cargando';

  @override
  String get retry => 'Reintentar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get goBack => 'Volver';

  @override
  String get goToHome => 'Ir al inicio';

  @override
  String get done => 'Hecho';

  @override
  String get save => 'Guardar';

  @override
  String get continueButton => 'CONTINUAR';

  @override
  String get invalidAmount => 'Cantidad inválida';

  @override
  String get insufficientFunds => 'Fondos insuficientes';

  @override
  String get pleaseEnterAmount => 'Por favor, ingrese una cantidad';

  @override
  String get pleaseCompleteFields => 'Por favor, complete todos los campos';

  @override
  String get depositInitiated => '¡Depósito Iniciado!';

  @override
  String get depositSuccess =>
      'Su transacción de depósito ha sido transmitida. Se acreditará una vez confirmada.';

  @override
  String get errorLoadingData => 'Error al cargar datos';

  @override
  String get tryAgain => 'Intentar de nuevo';

  @override
  String get noChartData => 'Sin datos del gráfico';

  @override
  String get walletSettings => 'Configuración de la Billetera';

  @override
  String get spendingLimit => 'Límite de Gasto';

  @override
  String get exportPrivateKey => 'Exportar Clave Privada';

  @override
  String get removeWallet => 'Eliminar Billetera';

  @override
  String currencyQuotation(Object value) {
    return '1 BRL = $value USD';
  }

  @override
  String approximateValue(Object currency, Object value) {
    return '≈ $value $currency';
  }

  @override
  String get paymentLinks => 'Enlaces de Pago';

  @override
  String get youWillReceive => 'Recibirás';

  @override
  String get confirmationTime => 'Tiempo de confirmación';

  @override
  String get walletName => 'Nombre de la Billetera';

  @override
  String get setSpendingLimit => 'Establecer Límite de Gasto';

  @override
  String get amountInBtc => 'Cantidad en BTC';

  @override
  String get getStartedDescription =>
      'Crea tu primera billetera Bitcoin para comenzar.';

  @override
  String get welcomeSlogan =>
      'El primer banco internacional de Bitcoin centrado en la privacidad del mundo.';

  @override
  String get welcomeHeaderTitleCustody => 'Custodia institucional.\n';

  @override
  String get welcomeHeaderTitleSimplicity => 'Simplicidad absoluta.';

  @override
  String get welcomeHeaderSubtitle =>
      'Seguridad de nivel superior para su patrimonio digital. Diseñado para quienes exigen lo mejor.';

  @override
  String get welcomeCreateAccountButton => 'Crear cuenta';

  @override
  String get welcomeAlreadyHaveAccountButton => 'Ya tengo cuenta';

  @override
  String get loginTitle => 'Entrar';

  @override
  String get loginSubtitle =>
      'Ingresa usuario y contraseña. Luego se confirma la llave del dispositivo.';

  @override
  String get loginPasswordRequired => 'Ingresa tu contraseña.';

  @override
  String get loginTotpRequired => 'Ingresa el código de 6 dígitos.';

  @override
  String get loginConfirmCodeTitle => 'Confirma el código';

  @override
  String get loginConfirmCodeSubtitle =>
      'Ingresa el código de tu autenticador para terminar el acceso.';

  @override
  String get loginConfirmAccessButton => 'Confirmar acceso';

  @override
  String get loginLostAccessButton => 'Perdí el acceso a la cuenta';

  @override
  String get loginNewHere => '¿Nuevo por aquí?';

  @override
  String get loginCreateAccount => 'Crear cuenta';

  @override
  String get loginUsernameLabel => 'Nombre de usuario';

  @override
  String get loginContinueButton => 'Continuar';

  @override
  String get signIn => 'Iniciar Sesión';

  @override
  String get createAccount => 'Crear Cuenta';

  @override
  String get welcomeBack => 'Bienvenido de Nuevo';

  @override
  String get signInToAccess => 'Inicia sesión para acceder a tu billetera';

  @override
  String get username => 'Usuario';

  @override
  String get passphrase => 'Frase de contraseña';

  @override
  String get required => 'Requerido';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get settingsScreenSubtitle =>
      'Administra tu cuenta, seguridad y dispositivos';

  @override
  String get currency => 'Moneda';

  @override
  String get selectLanguage => 'Seleccionar Idioma';

  @override
  String get selectCurrency => 'Seleccionar Moneda';

  @override
  String get selectWalletToSend => 'Seleccione una billetera para enviar.';

  @override
  String get errorLoadingWallets => 'Error al cargar carteras';

  @override
  String get add => 'Añadir';

  @override
  String get deposit => 'Depositar';

  @override
  String get sentTo => 'Enviado a';

  @override
  String get receivedFrom => 'Recibido de';

  @override
  String get showLess => 'Ver Menos';

  @override
  String get copy => 'COPIAR';

  @override
  String get share => 'COMPARTIR';

  @override
  String get waitingConnection => 'Esperando conexión...';

  @override
  String get offlineRetryHint => 'Desliza hacia abajo o toca reintentar.';

  @override
  String get nfcUnavailable => 'NFC NO DISPONIBLE';

  @override
  String get processing => 'PROCESANDO...';

  @override
  String get nfcInDevelopment => 'NFC NO DISPONIBLE EN ESTE DISPOSITIVO';

  @override
  String get amountToReceive => 'VALOR A RECIBIR';

  @override
  String get approachToSend => 'ACERCA PARA ENVIAR';

  @override
  String get approachToRead => 'ACERCA PARA LEER';

  @override
  String get nfcInstructions =>
      'Mantén tu dispositivo cerca del lector o de otro smartphone para procesar.';

  @override
  String get cancelOperation => 'CANCELAR OPERACIÓN';

  @override
  String get confirming => 'Confirmando';

  @override
  String get sendBitcoin => 'ENVIAR BITCOIN';

  @override
  String get receiveBitcoin => 'RECIBIR BITCOIN';

  @override
  String get onChain => 'ON-CHAIN';

  @override
  String get lightning => 'LIGHTNING';

  @override
  String get transactionAmount => 'VALOR DE LA TRANSACCIÓN';

  @override
  String get approximateNfc => 'ACERCAR NFC';

  @override
  String get createLink => 'CREAR LINK';

  @override
  String get history => 'HISTORIAL';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get secureAccess => 'Acceso seguro';

  @override
  String get newHere => '¿Nuevo por aquí?';

  @override
  String get signUpNow => 'Regístrate';

  @override
  String get amountToSend => 'VALOR A ENVIAR';

  @override
  String get processingDuration => 'PROCESAMIENTO: ~15 MIN';

  @override
  String get withdrawConfirmButton => 'CONFIRMAR Y ENVIAR';

  @override
  String get secureWithdrawal => 'RETIRO SEGURO';

  @override
  String get totalToReceive => 'TOTAL A RECIBIR';

  @override
  String get sovereignKeyVerification => 'VERIFICACIÓN CON PASSKEY';

  @override
  String get readyToScan => 'LISTO PARA ESCANEAR';

  @override
  String get sovereigntyStatusTitle => 'ESTADO DE SEGURIDAD';

  @override
  String get liveAttestationReport => 'REPORTE DE SEGURIDAD';

  @override
  String get systemSovereign => 'SISTEMA DE SEGURIDAD';

  @override
  String get integrityAlert => 'ALERTA DE INTEGRIDAD';

  @override
  String get hardwareAttestation => 'VERIFICACIÓN DEL DISPOSITIVO';

  @override
  String get networkConsensus => 'CONFIRMACIONES DE LA RED';

  @override
  String get ledgerIntegrity => 'INTEGRIDAD FINANCIERA';

  @override
  String get memoryProtection => 'PROTECCIÓN LOCAL';

  @override
  String get serverUptime => 'Disponibilidad del servicio';

  @override
  String get realtimeReportInfo => 'Reporte generado en tiempo real';

  @override
  String get analyzingSovereignty => 'VERIFICANDO SEGURIDAD…';

  @override
  String get chooseUniqueHandle => 'Elige tu identificador único';

  @override
  String get chooseUniqueHandleDesc =>
      'Este será tu identificador único en la red Kerosene. Úsalo para recibir transferencias de otros usuarios.';

  @override
  String get handleLabel => 'IDENTIFICADOR (VISIBLE EN EL APP)';

  @override
  String get handleHint => 'ej.: satoshi_99';

  @override
  String get errUsernameRequired => 'Ingresa un nombre de usuario';

  @override
  String get errUsernameTooShort => 'Mínimo de 3 caracteres';

  @override
  String get errUsernameInvalid =>
      'Solo letras minúsculas, números y guion bajo (_)';

  @override
  String get generatePaymentRequest => 'GENERAR COBRO';

  @override
  String get notificationChannels => 'CANALES';

  @override
  String get notificationAlerts => 'ALERTAS';

  @override
  String get pushNotifications => 'Notificaciones push';

  @override
  String get pushNotificationsDesc => 'Recibe alertas en tu dispositivo';

  @override
  String get emailNotifications => 'Notificaciones por email';

  @override
  String get emailNotificationsDesc => 'Recibe actualizaciones por email';

  @override
  String get transactionUpdates => 'Actualizaciones de transacciones';

  @override
  String get transactionUpdatesDesc => 'Transacciones de entrada y salida';

  @override
  String get securityAlertsTitle => 'Alertas de seguridad';

  @override
  String get securityAlertsDesc =>
      'Intentos de inicio de sesión y cambios de contraseña';

  @override
  String get marketingNews => 'Novedades';

  @override
  String get marketingNewsDesc => 'Mantente al día con las novedades';

  @override
  String get sovereigntyStatus => 'Estado de seguridad';

  @override
  String get sovereigntyStatusDesc =>
      'Protección de la cuenta y salud del servicio';

  @override
  String get biometricAuth => 'Autenticación biométrica';

  @override
  String get biometricAuthDesc => 'Usa Face ID o huella para desbloquear';

  @override
  String get changePin => 'Cambiar PIN';

  @override
  String get changePinDesc => 'Actualiza tu código de acceso de 6 dígitos';

  @override
  String get changePassword => 'Cambiar contraseña';

  @override
  String get changePasswordDesc => 'Actualiza la contraseña de tu cuenta';

  @override
  String get twoFactorAuth => 'Autenticación de dos factores';

  @override
  String get twoFactorAuthDesc => 'Agrega una capa extra de seguridad';

  @override
  String get enableTwoFactorInfo =>
      'Activa 2FA para proteger tus fondos contra accesos no autorizados.';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get typeSend => 'Envío';

  @override
  String get typeReceive => 'Recepción';

  @override
  String get typeSwap => 'Intercambio';

  @override
  String get typeFee => 'Tarifa';

  @override
  String get hashCopied => '¡Hash copiado!';

  @override
  String get transactionSentSuccess => '¡Transacción enviada con éxito!';

  @override
  String get selectRecipient => 'Seleccionar Destinatario';

  @override
  String get searchAddress => 'Buscar o pegar dirección';

  @override
  String get noRecentContacts => 'Sin contactos recientes';

  @override
  String get unknown => 'Desconocido';

  @override
  String fromWallet(Object name) {
    return 'De: $name';
  }

  @override
  String get yourBitcoinAddress => 'Tu Dirección Bitcoin';

  @override
  String get addressNotAvailable => 'Dirección no disponible';

  @override
  String get copyAddress => 'Copiar Dirección';

  @override
  String get receiveMethod => 'Método de Recepción';

  @override
  String get generateQrCodeDescription =>
      'Generar un código para ser escaneado';

  @override
  String get nfcBeam => 'NFC Beam';

  @override
  String get nfcTagDescription => 'Escribe la solicitud en una etiqueta NFC';

  @override
  String get scanToPay => 'Escanear para Pagar';

  @override
  String get approachPhoneToNfc => 'Acerca el teléfono a la etiqueta NFC';

  @override
  String get nfcTagNotSupported => 'La etiqueta no soporta NDEF';

  @override
  String get nfcTagNotWritable => 'Etiqueta no grabable';

  @override
  String get nfcTagCapacityError =>
      'Solicitud mayor que la capacidad de la etiqueta';

  @override
  String get nfcTagWrittenSuccess => '¡Etiqueta grabada con éxito!';

  @override
  String get nfcTagInvalid =>
      'Esta etiqueta no contiene una solicitud de pago legible.';

  @override
  String get nfcPaymentNotFound =>
      'No se encontró una solicitud de pago compatible en esta etiqueta.';

  @override
  String get nfcCouldNotProcess =>
      'No fue posible procesar esta etiqueta NFC. Inténtalo de nuevo.';

  @override
  String get writeNfcTag => 'Grabar Etiqueta NFC';

  @override
  String errorWriting(Object error) {
    return 'Error al grabar: $error';
  }

  @override
  String get typeWithdrawal => 'Retiro';

  @override
  String get typeDeposit => 'Depósito';

  @override
  String get rememberMe => 'Recordarme';

  @override
  String get torOnionActive => 'Protocolo Onion Activo (Kerosene Core)';

  @override
  String get signupFeeTitle => 'Tarifa de Activación';

  @override
  String get signupFeeSubtitle =>
      'Se requiere una tarifa única de 0,003 BTC para activar tu cuenta y prevenir el spam.';

  @override
  String get signupFeeWhyTitle => '¿Por qué una tarifa?';

  @override
  String get signupFeeWhyBody =>
      'Kerosene no tiene formulario de registro ni correo electrónico. La tarifa ayuda a proteger la red de bots y cuentas falsas.';

  @override
  String get signupFeeNotRefundable => 'No reembolsable';

  @override
  String get signupFeeNotRefundableBody =>
      'Una vez transmitida, la tarifa no puede recuperarse. Asegúrate de estar listo antes de continuar.';

  @override
  String get signupFeeContinue => 'Entendido, Continuar';

  @override
  String get seedSecurityTitle => 'Seguridad de la Semilla';

  @override
  String get seedSecuritySubtitle =>
      'Elige cómo proteger tu frase de recuperación de la billetera.';

  @override
  String get seedStandardTitle => 'Estándar';

  @override
  String get seedStandardDesc =>
      'Una frase de recuperación de 12, 18 o 24 palabras. Ideal para uso general y simplicidad.';

  @override
  String get seedSlip39Title => 'Shamir SLIP-39 (Multi-parte)';

  @override
  String get seedSlip39Desc =>
      'Divide tu semilla en múltiples partes. Requiere un mínimo para recuperar (ej: 3-de-5). Ideal para almacenamiento físico distribuído.';

  @override
  String get seedMultisigTitle => 'Bóveda Multisig 2FA';

  @override
  String get seedMultisigDesc =>
      'Una billetera Multisig 2-de-3. Kerosene co-firma transacciones vía TOTP. Protege contra el robo del dispositivo.';

  @override
  String get seedSlip39ConfigTitle => 'Configuración SLIP-39';

  @override
  String get seedSlip39TotalShares => 'Total de Partes (Piezas)';

  @override
  String get seedSlip39Threshold => 'Umbral Requerido';

  @override
  String seedSlip39Summary(Object threshold, Object total) {
    return 'Requiere $threshold de $total partes para restaurar la billetera.';
  }

  @override
  String get passphraseTitle => 'Tu Frase Secreta';

  @override
  String get passphraseSubtitle =>
      'Anota estas 18 palabras en un papel físico. Nunca las guardes digitalmente.';

  @override
  String get passphraseWrittenDown => 'Ya Lo Anoté';

  @override
  String get passphraseWarning =>
      'Si pierdes estas palabras, perderás permanentemente el acceso a tu cuenta y fondos.';

  @override
  String get passphraseVerifyTitle => 'Verificar Frase';

  @override
  String get passphraseVerifySubtitle =>
      'Escribe tu frase secreta para confirmar que tienes una copia de seguridad correcta.';

  @override
  String get passphraseVerifyHint => 'palabra1 palabra2 palabra3...';

  @override
  String get passphraseVerifyError =>
      'Frase incorrecta. Por favor, inténtalo de nuevo.';

  @override
  String get passphraseVerifyContinue => 'Verificar y Continuar';

  @override
  String get passphraseGoBack => 'Volver para ver la frase';

  @override
  String get passphraseEnterWords => 'Ingresa tus 18 palabras';

  @override
  String get slip39SharesTitle => 'Tus Partes SLIP-39';

  @override
  String slip39SharesSubtitle(Object threshold, Object total) {
    return 'Tu semilla está dividida en $total piezas. Necesitas $threshold de ellas para recuperar tu billetera.';
  }

  @override
  String slip39ShareLabel(Object index, Object total) {
    return 'Parte $index de $total';
  }

  @override
  String slip39ShareCopied(Object index) {
    return 'Parte $index copiada';
  }

  @override
  String slip39VerifyShareTitle(Object index) {
    return 'Verificar Parte';
  }

  @override
  String slip39VerifyShareSubtitle(Object index) {
    return 'Escribe las palabras de la Parte $index exactamente como las anotaste.';
  }

  @override
  String slip39ConfirmShare(Object index) {
    return 'Confirmar Parte $index';
  }

  @override
  String get slip39AllConfirmedContinue =>
      'Todas las Partes Confirmadas — Continuar';

  @override
  String slip39ConfirmAllPending(Object total) {
    return 'Confirma las $total partes para continuar';
  }

  @override
  String slip39Warning(Object threshold) {
    return 'NO almacenes todas las partes en el mismo lugar. Si un atacante encuentra suficientes piezas, puede recuperar tu billetera.';
  }

  @override
  String get twoFaPrimaryTitle => 'Tu Semilla Principal';

  @override
  String get twoFaPrimaryBadge => 'Clave 1 de 3 — Solo en tu dispositivo';

  @override
  String get twoFaPrimarySubtitle =>
      'Esta frase de 18 palabras es tu clave privada principal. Sola, NO es suficiente para firmar transacciones — siempre se requiere una autorización TOTP de Kerosene.';

  @override
  String get twoFaPrimaryWritten => 'Ya Lo Anoté';

  @override
  String get twoFaBackupTitle => 'Tu Semilla de Recuperación';

  @override
  String get twoFaBackupBadge => 'Clave 3 de 3 — Emergencia / Recuperación';

  @override
  String get twoFaBackupSubtitle =>
      'Guarda este respaldo de 12 palabras separado de tu frase principal. Juntos, ayudan a recuperar el acceso en una emergencia.';

  @override
  String get twoFaCoSignerNote =>
      'La Clave 2 de 3 está cifrada en Kerosene y se usa solo para co-firmar transacciones cuando proporcionas un código TOTP válido.';

  @override
  String get twoFaBothStored => 'Guardé Ambas Semillas';

  @override
  String get twoFaBackToPrimary => 'Volver a Semilla Principal';

  @override
  String get twoFaVerifyTitle => 'Verificar Semilla Principal';

  @override
  String get twoFaVerifySubtitle =>
      'Confirma tu Clave Principal (18 palabras) para demostrar que está guardada de forma segura.';

  @override
  String get twoFaVerifyHint => 'palabra1 palabra2 palabra3...';

  @override
  String get twoFaVerifyError =>
      'Incorrecto. Por favor, revisa tu Semilla Principal.';

  @override
  String get twoFaVerifyActivate => 'Verificar y Activar Bóveda 2FA';

  @override
  String get twoFaBackToBackup => 'Volver a Semilla de Recuperación';

  @override
  String get totpSetupTitle => 'Configurar Autenticador';

  @override
  String get totpSetupSubtitle =>
      'Escanea el código QR con tu app autenticadora, luego ingresa el código de 6 dígitos para verificar.';

  @override
  String get totpCodeLabel => 'Ingresa el código de 6 dígitos';

  @override
  String get totpVerifyButton => 'Verificar y Continuar';

  @override
  String get totpErrorInvalid =>
      'Código inválido. Por favor, inténtalo de nuevo.';

  @override
  String get passkeyTitle => 'Registrar Passkey';

  @override
  String get passkeySubtitle =>
      'Registra una passkey biométrica para habilitar el inicio de sesión rápido sin contraseña en este dispositivo.';

  @override
  String get passkeyRegisterButton => 'Registrar Passkey (Biometría)';

  @override
  String get passkeySuccessMessage => '¡Passkey registrada con éxito!';

  @override
  String get passkeySkip => 'Omitir por ahora';

  @override
  String get usernameTitle => 'Elige tu Apodo';

  @override
  String get usernameSubtitle =>
      'Elige un nombre de usuario único. Esta es tu identidad pública en Kerosene.';

  @override
  String get usernameFieldLabel => 'Usuario';

  @override
  String get usernameFieldHint => '@tu_usuario';

  @override
  String get usernameCheckButton => 'Verificar Disponibilidad';

  @override
  String get usernameAvailable => '¡Usuario disponible!';

  @override
  String get usernameTaken => 'El usuario ya está en uso.';

  @override
  String get usernameContinue => 'Reservar Usuario y Continuar';

  @override
  String get paymentTitle => 'Pago de Activación';

  @override
  String get paymentSubtitle =>
      'Envía exactamente la cantidad que se muestra a continuación para activar tu cuenta.';

  @override
  String get paymentTimeLeft => 'Tiempo restante';

  @override
  String get paymentExpired => 'La ventana de pago expirou';

  @override
  String get paymentExpiredMessage =>
      'No completaste el pago en la ventana de 15 minutos. Tus datos temporales serán borrados y debes empezar de nuevo.';

  @override
  String get paymentWaiting => 'Esperando pago...';

  @override
  String get paymentAmountLabel => 'Cantidad';

  @override
  String get paymentAddressLabel => 'Dirección de Depósito';

  @override
  String get paymentCopyAddress => 'Copiar Dirección';

  @override
  String get paymentAddressCopied => '¡Dirección copiada!';

  @override
  String get confirmationsTitle => 'Esperando Confirmaciones';

  @override
  String get confirmationsSubtitle =>
      'Tu pago fue detectado. Esperando 3 confirmaciones de la red Bitcoin para finalizar tu cuenta.';

  @override
  String confirmationsProgress(Object current, Object total) {
    return '$current / $total confirmaciones';
  }

  @override
  String get confirmationsDone => '¡Cuenta Activada!';

  @override
  String get presentationSlide1Title =>
      'Infraestructura Segura desde el Primer Acceso';

  @override
  String get presentationSlide1Body =>
      'Kerosene opera con arquitectura tecnológica avanzada en un entorno protegido a través de la red onion. Esta estructura refuerza la privacidad, la resiliencia y la protección contra interferencias externas.\n\nLa seguridad no es una característica adicional.\nEs la base del sistema.';

  @override
  String get presentationSlide2Title =>
      'Creación de Cuenta con Mecanismo de Protección Estructural';

  @override
  String get presentationSlide2Body =>
      'Para preservar la integridad de la infraestructura, la creación de cuenta requiere enviar 0.003 BTC.\nEste monto permanece íntegramente en tu cuenta.\nDurante el registro, solo se deduce la tarifa de transacción de red necesaria para confirmar la operación.\nEste requisito técnico existe para:\n\n• Evitar la creación automatizada de cuentas\n• Reducir los vectores de ataque distribuidos\n• Mantener la estabilidad operativa\n• Proteger a todos los usuarios de la plataforma\n\nNo es una tarifa mensual.\nNo es un cargo recurrente.\nEs un mecanismo de protección estructural.';

  @override
  String get presentationSlide3Title =>
      'Estructura de Tarifas Clara y Objetiva';

  @override
  String get presentationSlide3Body =>
      'Nuestra política es simple:\n\n• Los depósitos y retiros externos usan la tarifa de la tarjeta de la billetera\n• Bronze: 0.9%\n• White: 0.8%\n• Black: 0.7%\n• 0% para transferencias internas\n\nLas transferencias entre usuarios de Kerosene son instantáneas y gratuitas.\n\nSin tarifas ocultas.';

  @override
  String get presentationSlide4Title => 'Compromiso con la Previsibilidad';

  @override
  String get presentationSlide4Body =>
      'Kerosene fue diseñado para operar con:\n\n• Estabilidad técnica\n• Transparencia operativa\n• Seguridad estructural\n• Previsibilidad de costos\n\nNuestra prioridad es mantener una infraestructura sólida, protegida y sostenible a largo plazo.';

  @override
  String get presentationSkip => 'Omitir';

  @override
  String get presentationNext => 'Siguiente';

  @override
  String get presentationStart => 'Acceder a Kerosene';

  @override
  String get signupScreenTitle => 'Crear Billetera';

  @override
  String get signupScreenSubtitle =>
      'Configura tu usuario y clave de seguridad.';

  @override
  String get signupUsernameHelper => 'Solo a-z, 0-9 y _';

  @override
  String get signupUsernameHint => 'letras minúsculas, números y _';

  @override
  String get signupUsernameMinChars => 'Mín. 3 caracteres';

  @override
  String get signupUsernameInvalid => 'Caracteres inválidos';

  @override
  String get signupMnemonicLabel => 'TU FRASE SECRETA (BIP39)';

  @override
  String get signupMnemonicWarning =>
      'Guarda esta frase de forma segura. Es la ÚNICA forma de recuperar tu cuenta.';

  @override
  String get signupMnemonicCopySuccess => '¡Frase copiada de forma segura!';

  @override
  String get signupMnemonicCopy => 'Copiar';

  @override
  String get signupMnemonicGenerateNew => 'Generar Nueva';

  @override
  String get signupMnemonicError =>
      'Error al generar la frase, intenta de nuevo';

  @override
  String get feeExplanationTitle => 'Tarifa de Red Segura';

  @override
  String get feeExplanationSubtitle =>
      'Para evitar el spam y garantizar la solidez de la red Kerosene, la creación de cuenta requiere una pequeña tarifa anti-spam de 0.003 BTC.';

  @override
  String get feeExplanationWhereGoesTitle => '¿A dónde va?';

  @override
  String get feeExplanationWhereGoesSubtitle =>
      'El monto total de 0.003 BTC va directamente a tu billetera una vez que se crea la cuenta.';

  @override
  String get feeExplanationContinue => 'Entiendo, Continuar';

  @override
  String get seedSecurityContinue => 'Continuar';

  @override
  String get totpTitle => 'Autenticación de Dos Factores';

  @override
  String get totpSubtitle =>
      'Escanea este código QR con tu aplicación de autenticación (ej: Google Authenticator, Authy).';

  @override
  String get totpSecretCopied => 'Secreto copiado al portapapeles';

  @override
  String get totpEnterCodeHint => '000000';

  @override
  String get totpEnter6Digits => 'Ingresa 6 dígitos';

  @override
  String get totpInvalidCode => 'Código inválido. Intenta de nuevo.';

  @override
  String get totpVerifyContinue => 'Verificar y Continuar';

  @override
  String get totpVerifying => 'Verificando código...';

  @override
  String get totpAuthenticating => 'Autenticando...';

  @override
  String get totpEstablishingSession => 'Estableciendo Sesión...';

  @override
  String get passkeySessionNotFound =>
      'Sesión no encontrada. Por favor, reinicia el proceso.';

  @override
  String get passkeyNoBiometrics =>
      'Configura biometría o un bloqueo de pantalla en este dispositivo para usar la llave del dispositivo.';

  @override
  String passkeyErrorStarting(String message) {
    return 'Error al iniciar el registro: $message';
  }

  @override
  String get passkeyBiometricReason =>
      'Crea una Passkey para proteger tu billetera Kerosene';

  @override
  String passkeyErrorFinishing(String message) {
    return 'Error al finalizar el registro: $message';
  }

  @override
  String get passkeyAuthFailed => 'Autenticación cancelada o fallida.';

  @override
  String passkeyUnexpectedError(String error) {
    return 'Error inesperado: $error';
  }

  @override
  String get passkeyVerificationUserNotFound => 'Usuario no encontrado';

  @override
  String get passkeyVerificationNoLocal => 'Sin passkey en este dispositivo';

  @override
  String get passkeyVerificationCancelled => 'Verificación cancelada';

  @override
  String get passkeyVerificationChallengeExpired => 'Tiempo expirado';

  @override
  String get passkeyVerificationRejected => 'Passkey rechazada';

  @override
  String get passkeyVerificationFailed => 'No fue posible validar la passkey';

  @override
  String get passkeyVerificationBodyPreparing =>
      'Iniciando confirmación segura.';

  @override
  String get passkeyVerificationBodySending =>
      'Esperando aprobación en este dispositivo.';

  @override
  String get passkeyVerificationBodySuccess =>
      'Credencial aceptada. Continuando automáticamente.';

  @override
  String get passkeyLoadingInitBiom => 'Inicializando Biometría...';

  @override
  String get passkeyLoadingSecuring => 'Asegurando Dispositivo...';

  @override
  String get passkeyLoadingRegistering => 'Registrando Passkey...';

  @override
  String get usernameHintChars => 'a-z, 0-9 y _';

  @override
  String get usernameHelperLength => 'Debe tener entre 3 y 15 caracteres';

  @override
  String get usernameErrorMin => 'Mínimo 3 caracteres';

  @override
  String get usernameErrorMax => 'Máximo 15 caracteres';

  @override
  String get usernameErrorInvalidChars => 'Caracteres inválidos';

  @override
  String get usernameLoadingPow => 'Verificando protección...';

  @override
  String get usernameLoadingKeys => 'Asegurando Llaves...';

  @override
  String get usernameLoadingInvoice => 'Generando Factura...';

  @override
  String get usernameLoadingNetwork => 'Conectando a la Red...';

  @override
  String get paymentExpiredLabel => 'EXPIRADO';

  @override
  String get confNetworkError => 'Error de Red';

  @override
  String get confNetworkVerified => '¡Red Verificada!';

  @override
  String get confConfirming => 'Confirmando en Blockchain';

  @override
  String get confErrorMsg =>
      'No pudimos finalizar la creación de tu cuenta. Reinicia la configuración de forma segura.';

  @override
  String get confVerifiedMsg =>
      'Tu cuenta ha sido creada oficialmente y tu tarifa añadida a tu saldo. Entrando a la pasarela...';

  @override
  String get confWaitingMsg =>
      'Esperando 3 confirmaciones de la red Bitcoin. Esto puede tomar alrededor de 30 minutos, pero puedes salir de la aplicación de forma segura; te notificaremos cuando esté listo.';

  @override
  String get confRestartSignup => 'Reiniciar Registro';

  @override
  String get confNotificationNotice =>
      'Recibirás una notificación push cuando llegue la 3ª confirmación.';

  @override
  String get homePlatformLiquidity => 'LIQUIDEZ DE LA PLATAFORMA';

  @override
  String get homeDeposits => 'DEPÓSITOS';

  @override
  String get homeWithdrawals => 'RETIROS';

  @override
  String get authRequired => 'Autenticación requerida';

  @override
  String get unlock => 'Desbloquear';

  @override
  String get pendingDeposits => 'Depósitos Pendientes';

  @override
  String get saqueAction => 'Retirar';

  @override
  String get detailsTransaction => 'Detalles de la Transacción';

  @override
  String get detailsClose => 'Cerrar';

  @override
  String get noWalletsFound => 'No se encontraron carteras';

  @override
  String get createWalletPrompt =>
      'Crea una cartera para comenzar a monitorear transacciones';

  @override
  String get createWalletAction => 'Crear Cartera';

  @override
  String get withdrawExternalBtc => 'Retiro Externo de BTC';

  @override
  String get withdrawExternalBtcDesc =>
      'Mueve fondos de tu cartera Kerosene a una dirección Bitcoin externa.';

  @override
  String get withdrawAddressLabel => 'Dirección Bitcoin (toAddress)';

  @override
  String get withdrawAmountLabel => 'Cantidad en BTC';

  @override
  String get withdrawDescLabel => 'Descripción (Opcional)';

  @override
  String get withdrawDescHint => 'Ej: Transferencia a Hardware Wallet';

  @override
  String get withdrawCancel => 'CANCELAR';

  @override
  String get withdrawAction => 'RETIRAR AHORA';

  @override
  String get errorAddressRequired => 'La dirección es obligatoria';

  @override
  String get errorAmountRequired => 'La cantidad es obligatoria';

  @override
  String get errorAmountInvalid => 'Cantidad inválida';

  @override
  String get txSent => 'Transferencia Enviada';

  @override
  String get txReceived => 'Transferencia Recibida';

  @override
  String get loginTotpTitle => 'Verificación de Dispositivo';

  @override
  String get loginTotpDesc =>
      'Este dispositivo es nuevo. Por favor ingresa el código de 6 dígitos de tu aplicación de autenticación para autorizarlo.';

  @override
  String get loginTotpAction => 'VERIFICAR E INICIAR SESIÓN';

  @override
  String get createWalletNameRequired => 'Nombre obligatorio';

  @override
  String get createWalletNameChars => 'Solo se permiten letras y números';

  @override
  String get sendDescriptionLabel =>
      'Descripción (opcional, ej: Pago de pizza)';

  @override
  String sendInsufficientBalance(String amount) {
    return 'Saldo insuficiente. Faltan $amount BTC para completar este envío.';
  }

  @override
  String get sendSelectWallet => 'Seleccionar Cartera';

  @override
  String get sendReviewTitle => 'Revisar Transacción';

  @override
  String get sendTrackedReviewTitle => 'Confirmar Pago Rastreado';

  @override
  String get sendRecipientLabel => 'Destinatario';

  @override
  String get sendNetworkFeeLabel => 'Tarifa de Red';

  @override
  String get sendTotalLabel => 'Total';

  @override
  String get sendConfirmAction => 'Confirmar';

  @override
  String get sendPayNowAction => 'Pagar Ahora';

  @override
  String get sendEnterAddressError =>
      'Por favor, ingresa un nombre de usuario o dirección de destino válido';

  @override
  String get sendEnterAmountError => 'Por favor, ingresa una cantidad válida';

  @override
  String get sendPaymentSuccess => '¡Pago realizado con éxito!';

  @override
  String get receiveReceivingWallet => 'Cartera de Recepción';

  @override
  String get receiveExpirationLabel => 'Expiración del Enlace de Pago';

  @override
  String get receiveNoExpiration => 'Sin Expiración';

  @override
  String get receive15Min => '15 Minutos';

  @override
  String get receive1Hour => '1 Hora';

  @override
  String get receive24Hours => '24 Horas';

  @override
  String get receiveGenAction => 'Generar Enlace de Pago';

  @override
  String get receiveQrMethod => 'QR Code';

  @override
  String get receiveNfcMethod => 'NFC Beam';

  @override
  String get receiveScanToPay => 'Escanea para Pagar';

  @override
  String get receiveReadyToBeam => 'Listo para Transmitir';

  @override
  String get receiveWriteNfc => 'Grabar en Tag NFC';

  @override
  String get unknownDeviceTitle => 'Autorizar Nuevo Dispositivo';

  @override
  String get unknownDeviceDesc =>
      'Este dispositivo no ha sido vinculado a tu cuenta.\nIngresa el código de 6 dígitos de tu aplicación de autenticación para autorizarlo.';

  @override
  String get unknownDeviceBanner => 'Nuevo dispositivo detectado';

  @override
  String get unknownDeviceInputHint => '000000';

  @override
  String get unknownDeviceInputErrorEmpty => 'Ingresa el código de 6 dígitos';

  @override
  String get unknownDeviceInputErrorLength => 'El código debe tener 6 dígitos';

  @override
  String get unknownDeviceHelper =>
      'Abre tu aplicación de autenticación e ingresa el código actual.';

  @override
  String get unknownDeviceAction => 'AUTORIZAR INICIAR SESIÓN';

  @override
  String get unknownDeviceSecurityNote =>
      'Si no intentaste iniciar sesión, tus credenciales pueden estar comprometidas. Cambia tu passphrase de inmediato.';

  @override
  String get createWalletTitle => 'Nueva Cartera';

  @override
  String get createWalletSuccess => '¡Cartera creada exitosamente!';

  @override
  String get createWalletErrorGenFirst =>
      'Por favor genera una contraseña primero.';

  @override
  String get createWalletIdentity => 'IDENTIDAD DE LA CARTERA';

  @override
  String get createWalletNameHint => 'Ahorros, Diario, etc.';

  @override
  String get createWalletSecurity => 'SEGURIDAD DE PASSPHRASE';

  @override
  String createWalletWords(int count) {
    return '$count Palabras';
  }

  @override
  String get createWalletActionGen => 'Generar Llave de Seguridad';

  @override
  String get createWalletActionCreate => 'CREAR CARTERA';

  @override
  String get createWalletCopyAction => 'Copiar';

  @override
  String get createWalletCopySuccess => '¡Copiado!';

  @override
  String get createWalletNewAction => 'Nueva';

  @override
  String get createWalletWarning =>
      'Guarda bien estas palabras. Sin ellas, tus fondos se perderán.';

  @override
  String get bitcoinAccountsTitle => 'Cuentas Bitcoin';

  @override
  String get bitcoinAccountsSubtitle =>
      'Mantén tu tarjeta Kerosene y tus billeteras frías en una vista simple. Las claves privadas quedan fuera de la app salvo durante la creación de una nueva billetera fría.';

  @override
  String get bitcoinAccountsErrorTitle => 'Cuentas Bitcoin no disponibles';

  @override
  String get bitcoinAccountsErrorMessage =>
      'No pudimos cargar tus cuentas ahora. Inténtalo de nuevo en unos instantes.';

  @override
  String get bitcoinAccountsCreateColdWallet => 'Crear billetera fría';

  @override
  String get bitcoinAccountsNewKeroseneCard => 'Nueva tarjeta Kerosene';

  @override
  String get bitcoinAccountsEmptyTitle => 'Aún no hay cuenta Bitcoin';

  @override
  String get bitcoinAccountsEmptyMessage =>
      'Crea una billetera fría para guardar a largo plazo o agrega una tarjeta Kerosene para recibir en el día a día.';

  @override
  String get bitcoinAccountsKeroseneCardSection => 'Tarjeta Kerosene';

  @override
  String get bitcoinAccountsColdWalletSection => 'Billeteras frías';

  @override
  String get bitcoinAccountsNoKeroseneCard =>
      'Aún no hay ninguna tarjeta Kerosene activa.';

  @override
  String get bitcoinAccountsNoColdWallet =>
      'Aún no se está observando ninguna billetera fría.';

  @override
  String get bitcoinAccountsKeroseneCardBadge => 'Tarjeta Kerosene';

  @override
  String get bitcoinAccountsColdWalletBadge => 'Solo lectura';

  @override
  String get bitcoinAccountsUnnamedAccount => 'Cuenta Bitcoin';

  @override
  String get bitcoinAccountsAvailableBalance => 'Saldo disponible';

  @override
  String get bitcoinAccountsObservedBalance => 'Saldo observado';

  @override
  String get bitcoinAccountsKeroseneCardNote =>
      'Usa esta tarjeta para recibir Bitcoin dentro de Kerosene y mover fondos rápidamente.';

  @override
  String get bitcoinAccountsColdWalletNote =>
      'Kerosene solo observa esta billetera. Para gastar, aún necesitas tus palabras de recuperación o tu dispositivo sin conexión.';

  @override
  String get bitcoinAccountsPendingBalance => 'Esperando';

  @override
  String get bitcoinAccountsReservedBalance => 'Reservado';

  @override
  String get bitcoinAccountsReviewBalance => 'En revisión';

  @override
  String get bitcoinAccountsReceiveBtc => 'Recibir BTC';

  @override
  String get bitcoinAccountsStatusActive => 'Lista';

  @override
  String get bitcoinAccountsStatusPending => 'Preparando';

  @override
  String get bitcoinAccountsStatusDisabled => 'Pausada';

  @override
  String get bitcoinAccountsStatusReady => 'Disponible';

  @override
  String get bitcoinAccountsCreateCardTitle => 'Nueva tarjeta Kerosene';

  @override
  String get bitcoinAccountsCardNameLabel => 'Nombre de la tarjeta';

  @override
  String get bitcoinAccountsCardNameHint => 'Diario, Reserva, Viaje';

  @override
  String get bitcoinAccountsCreateCardNotice =>
      'Esta tarjeta es para fondos que quieres tener disponibles dentro de Kerosene.';

  @override
  String get bitcoinAccountsCreateCardAction => 'Crear tarjeta';

  @override
  String get bitcoinAccountsCreateCardErrorTitle => 'Tarjeta no creada';

  @override
  String get bitcoinAccountsCreateCardErrorMessage =>
      'No pudimos crear esta tarjeta ahora. Revisa el nombre e inténtalo de nuevo.';

  @override
  String get bitcoinAccountsCustodyInternalTitle => 'Billetera Interna';

  @override
  String get bitcoinAccountsCustodyInternalSubtitle =>
      'Saldo custodiado, transferencias instantáneas y tarifas reducidas.';

  @override
  String get bitcoinAccountsCustodyOnchainTitle => 'Custodial On-chain';

  @override
  String get bitcoinAccountsCustodyOnchainSubtitle =>
      'Aseguramos tus claves, validamos y firmamos tus transacciones con tu autorización.';

  @override
  String get bitcoinAccountsCustodyWatchOnlyTitle => 'Kerosene Watch-Only';

  @override
  String get bitcoinAccountsCustodyWatchOnlySubtitle =>
      'Las claves privadas las gestionas tú; más complejo y lento, pero sin depender de nuestro servicio.';

  @override
  String get coldWalletCreateTitle => 'Crear billetera fría';

  @override
  String get coldWalletCreateSubtitle =>
      'Genera las palabras de recuperación en este dispositivo, anótalas con calma y Kerosene guardará solo lo necesario para mostrar saldos.';

  @override
  String get coldWalletNameLabel => 'Nombre de la billetera';

  @override
  String get coldWalletNameHint => 'Bóveda, Reserva familiar, Largo plazo';

  @override
  String get coldWalletSecurityLevelTitle => 'Nivel de seguridad';

  @override
  String get coldWalletLevelEssentialTitle => 'Esencial';

  @override
  String get coldWalletLevelEssentialBody =>
      '12 palabras de recuperación. Más fácil de anotar, adecuada para saldos menores.';

  @override
  String get coldWalletLevelRecommendedTitle => 'Recomendado';

  @override
  String get coldWalletLevelRecommendedBody =>
      '24 palabras de recuperación. Mejor opción predeterminada para guardar Bitcoin a largo plazo.';

  @override
  String get coldWalletLevelMaximumTitle => 'Máximo';

  @override
  String get coldWalletLevelMaximumBody =>
      '24 palabras más una palabra extra. Perder cualquiera de ellas significa perder el acceso.';

  @override
  String get coldWalletExtraWordLabel => 'Palabra extra';

  @override
  String get coldWalletExtraWordHint => 'No reutilices una contraseña';

  @override
  String get coldWalletExtraWordWarning =>
      'Kerosene no puede recuperar la palabra extra. Guárdala separada de las palabras de recuperación.';

  @override
  String get coldWalletChecklistTitle => 'Antes de generar';

  @override
  String get coldWalletChecklistPaper =>
      'Tengo papel o respaldo metálico preparado.';

  @override
  String get coldWalletChecklistPrivate =>
      'Estoy en un lugar privado, sin cámaras cerca.';

  @override
  String get coldWalletChecklistOffline =>
      'Apagué Wi-Fi y datos móviles manualmente.';

  @override
  String get coldWalletChecklistNoPhotos => 'No tomaré capturas ni fotos.';

  @override
  String get coldWalletGenerateAction => 'Generar palabras';

  @override
  String get coldWalletBackupTitle => 'Anota estas palabras';

  @override
  String get coldWalletBackupSubtitle =>
      'Estas palabras controlan la billetera. Kerosene no puede recuperarlas después y no las guardará.';

  @override
  String get coldWalletWordsHidden =>
      'Las palabras están ocultas hasta que decidas mostrarlas.';

  @override
  String get coldWalletShowWords => 'Mostrar palabras';

  @override
  String get coldWalletHideWords => 'Ocultar palabras';

  @override
  String get coldWalletBackupDoneAction => 'Ya las anoté';

  @override
  String get coldWalletVerifySubtitle =>
      'Escribe las palabras solicitadas antes de importar la clave pública de observación.';

  @override
  String coldWalletVerifyWordLabel(int index) {
    return 'Palabra $index';
  }

  @override
  String get coldWalletVerifyFailedTitle => 'Respaldo no confirmado';

  @override
  String get coldWalletVerifyFailedMessage =>
      'Revisa las palabras e inténtalo de nuevo.';

  @override
  String get coldWalletImportAction => 'Finalizar y observar';

  @override
  String get coldWalletImportingAction => 'Importando...';

  @override
  String get coldWalletImportedTitle => 'Billetera fría agregada';

  @override
  String get coldWalletImportedMessage =>
      'Solo se importó la clave pública de observación.';

  @override
  String get coldWalletImportErrorTitle => 'Billetera fría no agregada';

  @override
  String get coldWalletImportErrorMessage =>
      'Reconéctate a internet e inténtalo de nuevo. Tus palabras de recuperación no fueron enviadas.';

  @override
  String get bitcoinAdvancedTitle => 'Bitcoin Advanced';

  @override
  String get bitcoinAdvancedNewPsbtAction => 'Nueva PSBT';

  @override
  String get bitcoinAdvancedRefreshAction => 'Actualizar';

  @override
  String get bitcoinAdvancedUtxosTitle => 'UTXOs monitoreados';

  @override
  String get bitcoinAdvancedUtxosUnavailableTitle => 'UTXOs no disponibles';

  @override
  String get bitcoinAdvancedUtxosUnavailableMessage =>
      'No se pudieron cargar los outputs observados.';

  @override
  String get bitcoinAdvancedPsbtsTitle => 'Flujos PSBT';

  @override
  String get bitcoinAdvancedPsbtsUnavailableTitle => 'PSBTs no disponibles';

  @override
  String get bitcoinAdvancedPsbtsUnavailableMessage =>
      'No se pudieron cargar los flujos de firma.';

  @override
  String get bitcoinAdvancedPsbtCopiedTitle => 'PSBT copiada';

  @override
  String get bitcoinAdvancedSignExternallyMessage =>
      'Firma esta PSBT en tu billetera externa.';

  @override
  String get bitcoinAdvancedNoUtxos =>
      'No hay UTXO observado para esta billetera.';

  @override
  String get bitcoinAdvancedSpendableForPsbt => 'Disponible para PSBT';

  @override
  String bitcoinAdvancedHiddenUtxos(int count) {
    return '+$count UTXOs ocultos';
  }

  @override
  String get bitcoinAdvancedNoPsbts =>
      'No hay PSBT creada para esta billetera.';

  @override
  String bitcoinAdvancedHiddenPsbts(int count) {
    return '+$count PSBTs antiguas';
  }

  @override
  String get bitcoinAdvancedFeePrefix => 'Comisión';

  @override
  String get bitcoinAdvancedCopyUnsignedAction => 'Copiar unsigned';

  @override
  String get bitcoinAdvancedSubmitSignatureAction => 'Enviar firma';

  @override
  String get bitcoinAdvancedUtxoStatusUnspent => 'Libre';

  @override
  String get bitcoinAdvancedUtxoStatusLocked => 'Reservado';

  @override
  String get bitcoinAdvancedUtxoStatusSpent => 'Gastado';

  @override
  String get bitcoinAdvancedPsbtStatusDraft => 'Borrador';

  @override
  String get bitcoinAdvancedPsbtStatusUnsignedCreated => 'Unsigned creada';

  @override
  String get bitcoinAdvancedPsbtStatusWaitingSignature => 'Esperando firma';

  @override
  String get bitcoinAdvancedPsbtStatusValidated => 'Validada';

  @override
  String get bitcoinAdvancedPsbtStatusBroadcasted => 'Transmitida';

  @override
  String get bitcoinAdvancedPsbtStatusRejectedTampered =>
      'Rechazada por cambio';

  @override
  String get bitcoinAdvancedPsbtStatusRejectedPolicy =>
      'Rechazada por política';

  @override
  String get bitcoinAdvancedPsbtStatusFailedSafe => 'Protegida';

  @override
  String get bitcoinAdvancedCreatePsbtTitle => 'Nueva PSBT watch-only';

  @override
  String get bitcoinAdvancedPsbtCreatedTitle => 'PSBT creada';

  @override
  String get bitcoinAdvancedCreatePsbtIntro =>
      'Kerosene arma la transacción sin firmar. Firma fuera de la app y envía la PSBT firmada para validación.';

  @override
  String get bitcoinAdvancedDestinationLabel => 'Dirección de destino';

  @override
  String get bitcoinAdvancedAmountSatsLabel => 'Monto en sats';

  @override
  String get bitcoinAdvancedFeeRateOptionalLabel => 'Fee rate opcional';

  @override
  String get bitcoinAdvancedOptionalUtxosTitle => 'UTXOs opcionales';

  @override
  String get bitcoinAdvancedAutoUtxosMessage =>
      'Sin selección manual, el backend elige suficientes UTXOs automáticamente.';

  @override
  String get bitcoinAdvancedNoSpendableUtxos =>
      'No hay UTXO disponible. La creación depende del saldo observado.';

  @override
  String get bitcoinAdvancedAutoUtxosFallback =>
      'Todavía puedes dejar la selección automática.';

  @override
  String get bitcoinAdvancedCreatePsbtAction => 'Crear PSBT';

  @override
  String get bitcoinAdvancedCreatingPsbtAction => 'Creando...';

  @override
  String get bitcoinAdvancedCreatedReviewMessage =>
      'Revisa destino y monto en la billetera externa antes de firmar. Kerosene rechaza firmas que cambien inputs, destino, monto o política de cambio.';

  @override
  String get bitcoinAdvancedDestinationMetric => 'Destino';

  @override
  String get bitcoinAdvancedAmountMetric => 'Monto';

  @override
  String get bitcoinAdvancedEstimatedFeeMetric => 'Comisión estimada';

  @override
  String get bitcoinAdvancedCopyUnsignedPsbtAction => 'Copiar unsigned PSBT';

  @override
  String get bitcoinAdvancedIncompleteDataTitle => 'Datos incompletos';

  @override
  String get bitcoinAdvancedIncompleteDataMessage =>
      'Ingresa destino y monto en sats.';

  @override
  String get bitcoinAdvancedCreateFailedTitle => 'PSBT no creada';

  @override
  String get bitcoinAdvancedCreateFailedMessage =>
      'Revisa saldo, destino y conexión antes de intentar de nuevo.';

  @override
  String get bitcoinAdvancedSubmitPsbtTitle => 'Enviar PSBT firmada';

  @override
  String get bitcoinAdvancedPsbtValidatedTitle => 'PSBT validada';

  @override
  String get bitcoinAdvancedSubmitPsbtIntro =>
      'Pega la PSBT firmada por la billetera externa. Kerosene valida inputs, destino, monto, cambio y comisión antes de transmitir.';

  @override
  String get bitcoinAdvancedSignedPsbtLabel => 'PSBT firmada';

  @override
  String get bitcoinAdvancedSignedPsbtHint => 'Pega la firma aquí';

  @override
  String get bitcoinAdvancedBroadcastAfterValidationTitle =>
      'Transmitir después de validar';

  @override
  String get bitcoinAdvancedBroadcastAfterValidationSubtitle =>
      'Desactiva para validar la firma sin broadcast.';

  @override
  String get bitcoinAdvancedValidatePsbtAction => 'Validar PSBT';

  @override
  String get bitcoinAdvancedValidatingPsbtAction => 'Validando...';

  @override
  String get bitcoinAdvancedDoneAction => 'Concluir';

  @override
  String get bitcoinAdvancedSignatureRequiredTitle => 'Firma obligatoria';

  @override
  String get bitcoinAdvancedSignatureRequiredMessage =>
      'Pega la PSBT firmada antes de validar.';

  @override
  String get bitcoinAdvancedPsbtRejectedTitle => 'PSBT rechazada';

  @override
  String get bitcoinAdvancedPsbtRejectedMessage =>
      'La firma no pasó las validaciones de seguridad.';

  @override
  String get bitcoinTaxReportsTitle => 'Informes fiscales';

  @override
  String get taxEventsUnavailableTitle => 'Eventos no disponibles';

  @override
  String get taxEventsUnavailableMessage =>
      'No se pudieron cargar los eventos temporales.';

  @override
  String get bitcoinTaxNoEventsTitle => 'Ningún evento temporal.';

  @override
  String get bitcoinTaxNoEventsMessage =>
      'Depósitos, envíos y comisiones recientes aparecerán aquí temporalmente.';

  @override
  String bitcoinTaxHiddenEvents(int count) {
    return '+$count eventos ocultos.';
  }

  @override
  String get bitcoinTaxClassifyTooltip => 'Clasificar evento';

  @override
  String get bitcoinTaxClassificationUpdatedTitle =>
      'Clasificación actualizada';

  @override
  String get bitcoinTaxClassificationNotSavedTitle =>
      'Clasificación no guardada';

  @override
  String get bitcoinTaxRetryLaterMessage => 'Intenta de nuevo en instantes.';

  @override
  String get bitcoinTaxExportJsonAction => 'Exportar JSON';

  @override
  String get bitcoinTaxExportCsvAction => 'Exportar CSV';

  @override
  String get bitcoinTaxReportCopiedTitle => 'Informe copiado';

  @override
  String get bitcoinTaxExportUnavailableTitle => 'Exportación no disponible';

  @override
  String get bitcoinTaxExportUnavailableMessage =>
      'No se pudo generar el informe ahora.';

  @override
  String get bitcoinTaxEventDepositInternal => 'Depósito interno';

  @override
  String get bitcoinTaxEventDepositExternal => 'Depósito externo';

  @override
  String get bitcoinTaxEventWithdrawal => 'Retiro';

  @override
  String get bitcoinTaxEventSpend => 'Gasto';

  @override
  String get bitcoinTaxEventFee => 'Comisión';

  @override
  String get bitcoinTaxClassSelfTransfer => 'Transferencia propia';

  @override
  String get bitcoinTaxClassThirdPartyDeposit => 'Depósito de tercero';

  @override
  String get bitcoinTaxClassSpend => 'Gasto';

  @override
  String get bitcoinTaxClassFee => 'Comisión';

  @override
  String get bitcoinTaxClassUnknown => 'Indefinido';

  @override
  String get bitcoinTaxClassPending => 'Clasificación pendiente';

  @override
  String get adminLoginMissingFields =>
      'Ingresa usuario, passphrase y clave administrativa';

  @override
  String get adminLoginApprovalRegistered =>
      'Acceso administrativo registrado.';

  @override
  String get adminLoginAccessNotApproved =>
      'El acceso administrativo no fue aprobado.';

  @override
  String get adminLoginInvalidTotp =>
      'Ingresa un código TOTP válido de 6 dígitos';

  @override
  String get adminLoginSessionExpired =>
      'Sesión expirada. Inicia sesión de nuevo.';

  @override
  String get adminLoginUsernameHint => 'Usuario';

  @override
  String get adminLoginPassphraseHint => 'Passphrase';

  @override
  String get adminLoginAdminKeyHint => 'Clave admin';

  @override
  String get adminLoginSignInAction => 'ENTRAR';

  @override
  String get adminLoginSecureAccessFooter => 'Acceso seguro vía onion service';

  @override
  String get adminLoginTotpTitle => 'AUTENTICACIÓN DE DOS FACTORES';

  @override
  String get adminLoginTotpSubtitle =>
      'Ingresa el código de 6 dígitos de tu app autenticadora';

  @override
  String adminLoginTotpAuthenticatingAs(String username) {
    return 'Autenticando como $username';
  }

  @override
  String get adminLoginVerifyAction => 'VERIFICAR';

  @override
  String get adminLoginBackToLoginAction => 'Volver al login';

  @override
  String get adminLoginConsoleSubtitle => 'Consola de gestión empresarial';

  @override
  String get adminLoginApprovalPending =>
      'Esperando aprobación en la app móvil.';

  @override
  String get adminConnectionOnionBrowser => 'Conectado vía Onion Service';

  @override
  String get adminConnectionOnionApi => 'API enrutada hacia Onion Service';

  @override
  String get adminConnectionGateway =>
      'Ruta directa/gateway - onion no verificado por el navegador';

  @override
  String get adminShellNavOverview => 'VISTA GENERAL';

  @override
  String get adminShellNavOperations => 'OPERACIONES';

  @override
  String get adminShellNavManagement => 'GESTIÓN';

  @override
  String get adminShellSystemOperational => 'Sistema operando con normalidad';

  @override
  String get adminShellIntegrityOnly => 'Solo integridad';

  @override
  String get adminRouteDashboard => 'Panel';

  @override
  String get adminRouteMonitoring => 'Monitoreo';

  @override
  String get adminRouteTransactions => 'Pruebas de integridad';

  @override
  String get adminRouteLightning => 'Lightning';

  @override
  String get adminRouteOnchain => 'On-chain';

  @override
  String get adminRouteChecks => 'Hash Chain';

  @override
  String get adminRoutePaymentLinks => 'Métricas de pago';

  @override
  String get adminRouteAnalytics => 'Analítica';

  @override
  String get adminRouteVolatility => 'Volatilidad';

  @override
  String get adminRouteCompanies => 'Infraestructura';

  @override
  String get adminRouteAudit => 'Auditoría y seguridad';

  @override
  String get adminRouteAuthenticatedDevices => 'Dispositivos autenticados';

  @override
  String get adminRouteNotifications => 'Notificaciones';

  @override
  String get adminRouteSettings => 'Configuración';

  @override
  String get adminActionRefresh => 'Actualizar';

  @override
  String get adminValueTor => 'Tor';

  @override
  String get adminValueDirect => 'Directo';

  @override
  String get adminValueAuthenticated => 'Autenticado';

  @override
  String get adminValueChecking => 'Verificando';

  @override
  String get adminValueAdminContext => 'contexto admin';

  @override
  String get adminValueMobileUnknown => 'móvil desconocido';

  @override
  String get adminValueCheckingRelease => 'verificando release';

  @override
  String get adminValueReleaseUnavailable => 'release no disponible';

  @override
  String get adminValueEnabled => 'activado';

  @override
  String get adminValueDisabled => 'desactivado';

  @override
  String get adminValueNotConfigured => 'no configurado';

  @override
  String get adminValueNotSet => 'no definido';

  @override
  String get adminValueAbsent => 'ausente';

  @override
  String get adminValueBackend => 'backend';

  @override
  String get adminValueTrue => 'true';

  @override
  String get adminValueFalse => 'false';

  @override
  String get adminStatusAuthorized => 'AUTORIZADO';

  @override
  String get adminStatusBlocked => 'BLOQUEADO';

  @override
  String get adminWaitingForResponse => 'esperando respuesta';

  @override
  String get adminBackendError => 'error del backend';

  @override
  String get adminColumnEntity => 'Entidad';

  @override
  String get adminColumnRole => 'Rol';

  @override
  String get adminColumnEnvironment => 'Entorno';

  @override
  String get adminColumnHealth => 'Salud';

  @override
  String get adminColumnDetail => 'Detalle';

  @override
  String get adminColumnName => 'Nombre';

  @override
  String get adminColumnEndpoint => 'Endpoint';

  @override
  String get adminColumnId => 'ID';

  @override
  String get adminColumnReference => 'Referencia';

  @override
  String get adminColumnAmount => 'Importe';

  @override
  String get adminColumnStatus => 'Estado';

  @override
  String get adminColumnRail => 'Rail';

  @override
  String get adminColumnCreated => 'Creado';

  @override
  String get adminColumnSettled => 'Liquidado';

  @override
  String get adminLabelPrimarySource => 'Fuente primaria';

  @override
  String get adminLabelNetwork => 'Red';

  @override
  String get adminLabelBlockHeight => 'Altura del bloque';

  @override
  String get adminLabelBestHash => 'Mejor hash';

  @override
  String get adminLabelMempoolTxs => 'Transacciones en mempool';

  @override
  String get adminLabelIndexer => 'Indexador';

  @override
  String get adminLabelStatus => 'Estado';

  @override
  String get adminLabelSession => 'Sesión';

  @override
  String get adminLabelAlias => 'Alias';

  @override
  String get adminLabelVersion => 'Versión';

  @override
  String get adminLabelSyncedChain => 'Cadena sincronizada';

  @override
  String get adminLabelSyncedGraph => 'Grafo sincronizado';

  @override
  String get adminLabelBlockHash => 'Hash del bloque';

  @override
  String get adminLabelPeers => 'Peers';

  @override
  String get adminLabelActiveChannels => 'Canales activos';

  @override
  String get adminLabelPendingChannels => 'Canales pendientes';

  @override
  String get adminLabelLocalBalance => 'Saldo local';

  @override
  String get adminLabelRemoteBalance => 'Saldo remoto';

  @override
  String get adminLabelWalletBalance => 'Saldo de billetera';

  @override
  String get adminLabelManifest => 'Manifiesto';

  @override
  String get adminLabelImageDigest => 'Digest de imagen';

  @override
  String get adminLabelCodeHash => 'Hash del código';

  @override
  String get adminLabelConfigHash => 'Hash de configuración';

  @override
  String get adminLabelAuthorized => 'Autorizado';

  @override
  String get adminLabelReason => 'Motivo';

  @override
  String get adminLabelCommit => 'Commit';

  @override
  String get adminLabelMobileVersion => 'Versión móvil';

  @override
  String get adminLabelPlatform => 'Plataforma';

  @override
  String get adminLabelActiveNode => 'Nodo activo';

  @override
  String get adminLabelApiRoute => 'Ruta API';

  @override
  String get adminLabelTorEnabled => 'Tor activado';

  @override
  String get adminLabelChecked => 'Verificado';

  @override
  String get adminLabelUser => 'Usuario';

  @override
  String get adminLabelRole => 'Rol';

  @override
  String get adminLabelJwtRefreshHeader => 'Header de refresh JWT';

  @override
  String get adminLabelPasskeyRp => 'RP de passkey';

  @override
  String get adminLabelDebugLogs => 'Logs de debug';

  @override
  String get adminLabelApiUrl => 'URL de API';

  @override
  String get adminLabelOnionBase => 'Base onion';

  @override
  String get adminLabelConnectionTimeout => 'Timeout de conexión';

  @override
  String get adminLabelReceiveTimeout => 'Timeout de recepción';

  @override
  String get adminLabelPasskeyRelyingParty => 'relying party de passkey';

  @override
  String get adminSettingsSubtitle =>
      'Enrutamiento de API, postura de sesión, preferencias de seguridad y versión de release.';

  @override
  String get adminSettingsApiRoutingTitle => 'Enrutamiento de API';

  @override
  String get adminSettingsSessionSecurityTitle => 'Sesión y seguridad';

  @override
  String get adminSettingsCurrentSessionError =>
      'No se pudo cargar la sesión admin actual.';

  @override
  String get adminSettingsReleaseTitle => 'Release';

  @override
  String get adminSettingsReleaseAttestationUnavailable =>
      'Atestación de release no disponible.';

  @override
  String get adminSettingsMobileReleaseUnavailable =>
      'Release móvil no disponible.';

  @override
  String get adminMonitoringSubtitle =>
      'Salud real de servicios, estado on-chain de Bitcoin Core, estado Lightning de LND, quórum Vault Raft, atestación de release y logs operacionales saneados.';

  @override
  String get adminMonitoringMetricServices => 'Servicios';

  @override
  String get adminMonitoringMetricVaultRaft => 'Vault Raft';

  @override
  String get adminMonitoringBitcoinPanel => 'Monitor Bitcoin';

  @override
  String get adminMonitoringLightningPanel => 'Monitor Lightning';

  @override
  String get adminMonitoringReleasePanel => 'Atestación de release';

  @override
  String get adminMonitoringHealthPanel => 'Salud de servicios';

  @override
  String get adminMonitoringLogsPanel => 'Logs operacionales saneados';

  @override
  String get adminMonitoringRelevantTransactions => 'Transacciones relevantes';

  @override
  String get adminMonitoringNoRelevantTransactions =>
      'Ninguna transacción on-chain monitoreada requiere acción en este momento.';

  @override
  String get adminMonitoringNoHealthChecks => 'No se reportaron health checks.';

  @override
  String get adminMonitoringNoLogs =>
      'Aún no se registraron eventos operacionales.';

  @override
  String adminMonitoringBlockchainError(String error) {
    return 'Error al cargar monitor blockchain: $error';
  }

  @override
  String adminMonitoringLightningError(String error) {
    return 'Error al cargar monitor Lightning: $error';
  }

  @override
  String adminMonitoringReleaseError(String error) {
    return 'Error al cargar snapshot de release: $error';
  }

  @override
  String adminMonitoringHealthError(String error) {
    return 'Error al cargar salud: $error';
  }

  @override
  String adminMonitoringLogsError(String error) {
    return 'Error al cargar logs: $error';
  }

  @override
  String get adminCompaniesSubtitle =>
      'Entidades operacionales, entornos, enrutamiento de nodos y dependencias críticas.';

  @override
  String get adminCompaniesMetricControlPlane => 'Plano de control';

  @override
  String get adminCompaniesMetricVaultRaft => 'Vault/Raft';

  @override
  String get adminCompaniesOperationalEntities => 'Entidades operacionales';

  @override
  String get adminCompaniesRoutingDependencies => 'Enrutamiento y dependencias';

  @override
  String get adminCompaniesRemoteNodes => 'Nodos remotos';

  @override
  String get adminCompaniesOverviewUnavailable => 'Overview no disponible.';

  @override
  String get adminCompaniesEntityKeroseneApi => 'API Kerosene';

  @override
  String get adminCompaniesEntityReleaseGate => 'Gate de release';

  @override
  String get adminCompaniesRoleControlPlane => 'Plano de control';

  @override
  String get adminCompaniesRoleOnchainSource => 'Fuente on-chain';

  @override
  String get adminCompaniesRoleLightningRouting => 'Enrutamiento Lightning';

  @override
  String get adminCompaniesRoleReleaseQuorum => 'Quórum de release';

  @override
  String get adminCompaniesRoleDeploymentAttestation => 'Atestación de deploy';

  @override
  String get adminPaymentLinksSubtitle =>
      'Volumen de enlaces de pago, conversión, fallas y últimos eventos de ciclo de vida.';

  @override
  String get adminPaymentLinksLinksCreated => 'Enlaces creados';

  @override
  String get adminPaymentLinksObservedVolume => 'Volumen observado';

  @override
  String get adminPaymentLinksConversion => 'Conversión';

  @override
  String get adminPaymentLinksFailures => 'Fallas';

  @override
  String get adminPaymentLinksLatestEvents =>
      'Últimos eventos de enlaces de pago';

  @override
  String get adminPaymentLinksLoadError =>
      'No se pudieron cargar los enlaces de pago.';

  @override
  String get adminPaymentLinksEmptyTitle => 'Aún no hay enlaces de pago';

  @override
  String get adminPaymentLinksEmptySubtitle =>
      'Los enlaces creados aparecerán aquí con estado y metadatos de liquidación.';

  @override
  String get adminPaymentLinksUnlabeled => 'Enlace sin etiqueta';

  @override
  String get adminPaymentLinksWaitingList => 'esperando respuesta de la lista';

  @override
  String get adminPaymentLinksExpiredCancelled => 'expirado o cancelado';

  @override
  String adminPaidOpen(String paid, String open) {
    return '$paid pagados | $open abiertos';
  }

  @override
  String adminLinksLoaded(String count) {
    return '$count enlaces cargados';
  }

  @override
  String adminSettledRatio(String paid, String created) {
    return '$paid/$created liquidados';
  }

  @override
  String adminHeightValue(String height) {
    return 'altura $height';
  }

  @override
  String adminVotersValue(String current, String expected) {
    return '$current/$expected votantes';
  }

  @override
  String adminActiveChannelsValue(String count) {
    return '$count canales activos';
  }

  @override
  String adminPeersValue(String alias, String peers) {
    return '$alias | peers $peers';
  }

  @override
  String adminConfirmationsValue(String count) {
    return '$count confirmaciones';
  }

  @override
  String adminLogBody(
      String createdAt, String reference, String userRef, String payloadRef) {
    return '$createdAt · ref $reference · usuario $userRef · payload $payloadRef';
  }

  @override
  String get bitcoinReceiveTitle => 'Recibir BTC';

  @override
  String get bitcoinReceiveAmountOptional => 'Monto opcional en sats';

  @override
  String get bitcoinReceiveOneTime => 'Dirección de un solo uso';

  @override
  String get bitcoinReceiveOneTimeSubtitle =>
      'Recomendado para privacidad y seguimiento limpio.';

  @override
  String get bitcoinReceiveGenerateAddress => 'Generar dirección';

  @override
  String get bitcoinReceiveGenerating => 'Generando...';

  @override
  String get bitcoinReceiveRefresh => 'Actualizar';

  @override
  String get bitcoinReceiveCreateErrorTitle => 'No se pudo generar';

  @override
  String get bitcoinReceiveCreateErrorMessage =>
      'Revisa los datos e intenta una nueva dirección.';

  @override
  String get bitcoinReceiveStatusErrorTitle => 'Estado no disponible';

  @override
  String get bitcoinReceiveStatusErrorMessage =>
      'No pudimos actualizar esta recepción ahora.';

  @override
  String get bitcoinReceiveCopiedTitle => 'Copiado';

  @override
  String get bitcoinReceiveCopiedMessage => 'Dirección Bitcoin copiada.';

  @override
  String get bitcoinReceiveStatusActive => 'Esperando';

  @override
  String get bitcoinReceiveRequestsTitle => 'Solicitudes de recepción';

  @override
  String get bitcoinReceiveRequestsLoadErrorTitle =>
      'No se pudieron cargar las solicitudes.';

  @override
  String get bitcoinReceiveRequestsOfflineTitle => 'Offline.';

  @override
  String get bitcoinReceiveRequestsLoadErrorMessage =>
      'Kerosene no pudo actualizar las solicitudes de recepción de esta cuenta.';

  @override
  String get bitcoinReceiveRequestsOfflineMessage =>
      'Reconecta e intenta de nuevo para cargar las solicitudes de recepción.';

  @override
  String get bitcoinReceiveRequestsEmptyTitle => 'No hay solicitudes activas.';

  @override
  String get bitcoinReceiveRequestsEmptyMessage =>
      'Las solicitudes Bitcoin generadas aparecerán aquí.';

  @override
  String get bitcoinReceiveRequestsFlexibleAmount => 'Monto flexible';

  @override
  String get bitcoinReceiveRequestsNoExpiry => 'sin expiración';

  @override
  String get bitcoinReceiveStatusDetected => 'Detectado';

  @override
  String get bitcoinReceiveStatusConfirming => 'Confirmando';

  @override
  String get bitcoinReceiveStatusPaid => 'Pagado';

  @override
  String get bitcoinReceiveStatusExpired => 'Expirado';

  @override
  String get bitcoinReceiveStatusLate => 'Pago tardío';

  @override
  String get bitcoinReceiveStatusReview => 'En revisión';

  @override
  String get bitcoinReceiveStatusAction => 'Necesita revisión';

  @override
  String get bitcoinReceiveStatusProtected => 'Protegido';

  @override
  String get bitcoinReceiveStatusWaiting => 'Esperando';

  @override
  String get bitcoinReceiveMessageActive =>
      'Envía BTC a esta dirección. Actualizaremos esta pantalla cuando la red vea el pago.';

  @override
  String get bitcoinReceiveMessageDetected =>
      'El pago apareció en la red Bitcoin y espera confirmaciones.';

  @override
  String get bitcoinReceiveMessageConfirming =>
      'La transacción entró en un bloque y sigue confirmando.';

  @override
  String get bitcoinReceiveMessagePaid =>
      'Pago confirmado y agregado al saldo de tu tarjeta Kerosene.';

  @override
  String get bitcoinReceiveMessageExpired =>
      'Esta solicitud expiró. Genera una nueva dirección para continuar.';

  @override
  String get bitcoinReceiveMessageLate =>
      'Un pago llegó después de la expiración y será revisado con seguridad.';

  @override
  String get bitcoinReceiveMessageReview =>
      'Tu confirmación fue recibida. Esperamos la condición segura de liberación.';

  @override
  String get bitcoinReceiveMessageAction =>
      'Confirma este pago para terminar la recepción con seguridad.';

  @override
  String get bitcoinReceiveMessageProtected =>
      'Esta recepción quedó protegida tras un problema de sincronización. Actualiza más tarde.';

  @override
  String get bitcoinReceiveMessageWaiting => 'Esperando la red Bitcoin.';

  @override
  String get onchainDepositTitle => 'Depósito on-chain';

  @override
  String get onchainDepositSubtitle =>
      'Escanea el código QR o copia la dirección Bitcoin exactamente como se muestra.';

  @override
  String get onchainDepositPreparingSubtitle =>
      'Preparando tu dirección de recepción.';

  @override
  String get onchainDepositLoadingTitle => 'Cargando';

  @override
  String get onchainDepositLoadingMessage =>
      'Consultando la cotización actual antes de crear la dirección.';

  @override
  String get onchainDepositAddressUnavailable =>
      'No pudimos crear una dirección Bitcoin válida. Inténtalo de nuevo.';

  @override
  String get onchainDepositTrackingUnavailable =>
      'No pudimos iniciar el seguimiento de este depósito. Inténtalo de nuevo.';

  @override
  String get onchainDepositAddressCopied => 'Dirección Bitcoin copiada.';

  @override
  String get onchainDepositSelectedWallet => 'Billetera seleccionada';

  @override
  String get onchainDepositLocalNetwork => 'Red local de prueba';

  @override
  String get onchainDepositStatusCompleted => 'Completado';

  @override
  String get onchainDepositStatusConfirmed => 'Confirmado';

  @override
  String get onchainDepositStatusDetected => 'Detectado';

  @override
  String get onchainDepositStatusWaiting => 'Esperando pago';

  @override
  String get onchainDepositStatusFailed => 'Falló';

  @override
  String get onchainDepositStatusCancelled => 'Cancelado';

  @override
  String get onchainDepositStatusExpired => 'Expirado';

  @override
  String get onchainDepositDescriptionCancelled =>
      'Este depósito fue cancelado. Crea una nueva dirección si todavía quieres depositar.';

  @override
  String onchainDepositDescriptionWaiting(String network) {
    return 'Esta dirección está reservada para este depósito en la red $network.';
  }

  @override
  String get onchainDepositDescriptionConfirmed =>
      'La red Bitcoin confirmó este depósito.';

  @override
  String onchainDepositDescriptionConfirming(int current, int total) {
    return 'Pago detectado. Esperando $current/$total confirmaciones.';
  }

  @override
  String onchainDepositDetectedNotice(int current, int total) {
    return 'Pago detectado. Siguiendo $current/$total confirmaciones.';
  }

  @override
  String get onchainDepositConfirmedNotice => 'Depósito confirmado.';

  @override
  String get onchainDepositCancelTitle => 'Cancelar depósito';

  @override
  String get onchainDepositCancelMessage =>
      'Esta dirección dejará de usarse para este depósito si todavía no se detectó ningún pago.';

  @override
  String get onchainDepositCancelAction => 'Cancelar depósito';

  @override
  String get onchainDepositCancelling => 'Cancelando...';

  @override
  String get onchainDepositCancelledNotice => 'Depósito cancelado.';

  @override
  String get onchainDepositGettingAddressTitle => 'Creando dirección';

  @override
  String get onchainDepositGettingAddressMessage =>
      'Después del pago, el saldo se actualizará cuando lleguen las confirmaciones Bitcoin.';

  @override
  String get onchainDepositErrorTitle => 'No se pudo preparar el depósito';

  @override
  String get onchainDepositTotalLabel => 'Total a depositar';

  @override
  String onchainDepositNetworkTag(String network) {
    return 'Dirección $network';
  }

  @override
  String get onchainDepositTrackingTitle => 'Seguimiento del pago';

  @override
  String get onchainDepositConfirmationsLabel => 'Confirmaciones';

  @override
  String get onchainDepositTxidLabel => 'Código de transacción';

  @override
  String get onchainDepositObservedAmountLabel => 'Monto visto';

  @override
  String get onchainDepositAmountCheckLabel => 'Revisión del monto';

  @override
  String get onchainDepositAmountCheckOk => 'Monto correcto';

  @override
  String get onchainDepositAmountCheckDifferent => 'Monto diferente';

  @override
  String get onchainDepositQrTitle => 'Dirección Bitcoin';

  @override
  String get onchainDepositQuoteLabel => 'Cotización BTC';

  @override
  String get onchainDepositDestinationWalletLabel => 'Llegará a';

  @override
  String get onchainDepositNetworkLabel => 'Red';

  @override
  String get onchainDepositExpectedAmountLabel => 'Monto esperado';

  @override
  String get onchainDepositReceivedAmountLabel => 'Monto recibido';

  @override
  String get onchainDepositMinimumConfirmationsLabel =>
      'Confirmaciones mínimas';

  @override
  String onchainDepositMinimumConfirmationsValue(int count) {
    return '$count bloques';
  }

  @override
  String get onchainDepositCustodyLabel => 'Tipo de billetera';

  @override
  String get onchainDepositCustodySelf => 'Billetera fría en observación';

  @override
  String get onchainDepositCustodyKerosene => 'Tarjeta Kerosene';

  @override
  String get onchainDepositSecuritySelf =>
      'Kerosene solo observa esta dirección. Para gastar, sigues usando tus palabras de recuperación o tu dispositivo sin conexión.';

  @override
  String get onchainDepositSecurityKerosene =>
      'Esta dirección fue creada para tu tarjeta Kerosene y será observada hasta que el depósito confirme.';

  @override
  String get errUnexpected => 'Ha ocurrido un error inesperado.';

  @override
  String get errAuthUserAlreadyExists =>
      'Este nombre de usuario ya está em uso.';

  @override
  String get errAuthUsernameMissing => 'El nombre de usuario es obligatorio.';

  @override
  String get errAuthPassphraseMissing => 'La contraseña es obligatoria.';

  @override
  String get errAuthInvalidUsernameFormat =>
      'Formato de nombre de usuario no válido.';

  @override
  String get errAuthCharLimitExceeded => 'Límite de caracteres excedido.';

  @override
  String get errAuthUserNotFound =>
      'Usuario no encontrado. Por favor, verifica tu spelling.';

  @override
  String get errAuthInvalidPassphraseFormat =>
      'La contraseña no cumple con los requisitos.';

  @override
  String get errAuthIncorrectTotp =>
      'El código TOTP es incorrecto o ha expirado.';

  @override
  String get errAuthInvalidCredentials =>
      'Nombre de usuario o contraseña incorrectos.';

  @override
  String get errAuthUnrecognizedDevice =>
      'Dispositivo no reconocido. Por favor, autorízalo.';

  @override
  String get errAuthTotpTimeout =>
      'El tiempo para ingresar el código ha expirado.';

  @override
  String get errLedgerNotFound =>
      'Cuenta financiera no encontrada. Asegúrate de que tu registro esté completo.';

  @override
  String get errLedgerAlreadyExists =>
      'La cuenta ya tiene registros financieros.';

  @override
  String get errLedgerInsufficientBalance =>
      'No tienes suficiente saldo para realizar esta transacción.';

  @override
  String get errLedgerInvalidOperation => 'Intento de operación no válido.';

  @override
  String get errLedgerReceiverNotFound => 'Dirección no disponible';

  @override
  String get errLedgerGeneric => 'No pudimos completar este movimiento ahora.';

  @override
  String get errLedgerPaymentRequestNotFound => 'Enlace de pago no encontrado.';

  @override
  String get errLedgerPaymentRequestExpired =>
      'Este enlace de pago ha expirado.';

  @override
  String get errLedgerPaymentRequestAlreadyPaid =>
      'Este enlace de pago ya ha sido pagado.';

  @override
  String get errLedgerPaymentRequestSelfPay =>
      'No puedes pagar un enlace creado por ti mismo.';

  @override
  String get errWalletAlreadyExists => 'Ya existe una cartera con este nombre.';

  @override
  String get errWalletNotFound => 'No se encontró la cartera especificada.';

  @override
  String get errWalletGeneric => 'No pudimos validar esta billetera ahora.';

  @override
  String get errNotifMissingToken => 'Falta el token de notificación.';

  @override
  String get errNotifMissingFields =>
      'Faltan campos obligatorios en la notificación.';

  @override
  String get errInternalServer => 'Kerosene no está disponible temporalmente.';

  @override
  String get errSessionExpired =>
      'Tu sesión ha expirado. Por favor, inicia sesión de nuevo.';

  @override
  String get errForbidden => 'Acceso denegado o dispositivo no reconocido.';

  @override
  String get errTooManySignupAttempts =>
      'Demasiados intentos de registro. Por favor, inténtalo más tarde.';

  @override
  String get errNoInternet =>
      'Sin conexión a internet. Verifica tu conexión e inténtalo de nuevo.';

  @override
  String get errTimeout =>
      'La conexión expiró. Verifica tu internet e inténtalo de nuevo.';

  @override
  String get errCommFailure => 'No pudimos conectar con Kerosene ahora.';

  @override
  String get errInvalidBtcAddress =>
      'La dirección Bitcoin proporcionada no es válida.';

  @override
  String get withdrawInvalidFields =>
      'Por favor, ingresa una dirección y monto válidos.';

  @override
  String get withdrawAuthReason => 'Autentícate para confirmar el retiro.';

  @override
  String get withdrawAuthCancelled => 'Autenticación cancelada.';

  @override
  String get withdrawSuccess => '¡Retiro enviado con éxito a la red Bitcoin!';

  @override
  String get withdrawFeeSection => 'DIFICULTAD DE LA RED (TASA)';

  @override
  String get withdrawFeeFast => 'Rápido';

  @override
  String get withdrawFeeMedium => 'Medio';

  @override
  String get withdrawFeeSlow => 'Lento';

  @override
  String get withdrawErrorFee => 'Error al estimar las tasas de la red.';

  @override
  String get verifyingDevice => 'VERIFICANDO DISPOSITIVO';

  @override
  String get connectingToServer => 'CONECTANDO AL SERVIDOR';

  @override
  String get sendingData => 'ENVIANDO DATOS';

  @override
  String get apiDisplayActive => 'Activo';

  @override
  String get apiDisplayWaiting => 'En espera';

  @override
  String get apiDisplayBeingChecked => 'En revisión';

  @override
  String get apiDisplayDetected => 'Detectado';

  @override
  String get apiDisplayConfirming => 'Confirmando';

  @override
  String get apiDisplayCompleted => 'Completado';

  @override
  String get apiDisplayExpired => 'Expirado';

  @override
  String get apiDisplayCancelled => 'Cancelado';

  @override
  String get apiDisplayNotCompleted => 'No completado';

  @override
  String get apiDisplayProtected => 'Protegido';

  @override
  String get apiDisplayAvailable => 'Disponible';

  @override
  String get apiDisplayUnavailable => 'No disponible';

  @override
  String get apiDisplayHealthy => 'Saludable';

  @override
  String get apiDisplayNeedsAttention => 'Requiere atención';

  @override
  String get apiDisplayActionNeeded => 'Acción necesaria';

  @override
  String get apiDisplayInReview => 'En revisión';

  @override
  String get apiDisplayBeingTracked => 'En seguimiento';

  @override
  String get apiDisplayAutomatic => 'Automático';

  @override
  String get apiDisplayManualConfirmation => 'Confirmación manual';

  @override
  String get apiDisplayPrivate => 'Privado';

  @override
  String get apiDisplayShareable => 'Compartible';

  @override
  String get apiDisplayWatchedColdWallet => 'Billetera fría en seguimiento';

  @override
  String get apiDisplayKeroseneCard => 'Tarjeta Kerosene';

  @override
  String get apiDisplayBitcoinWallet => 'Billetera Bitcoin';

  @override
  String get apiDisplayDeviceKey => 'Llave del dispositivo';

  @override
  String get apiDisplayAuthenticatorCode => 'Código del autenticador';

  @override
  String get apiDisplayAccessPassword => 'Contraseña de acceso';

  @override
  String get apiDisplayRecoveryCodes => 'Códigos de recuperación';

  @override
  String get apiDisplaySecureConfirmation => 'Confirmación segura';

  @override
  String get apiDisplayGenericActionError =>
      'No pudimos completar esta acción ahora. Inténtalo de nuevo.';

  @override
  String get apiDisplayLightningUnavailable =>
      'Lightning no está disponible para esta billetera en este momento.';

  @override
  String get apiDisplayDepositAddressCreateFailed =>
      'No pudimos crear una dirección para este depósito.';

  @override
  String get apiDisplaySecureConfirmationStartFailed =>
      'No pudimos iniciar la confirmación segura. Inténtalo de nuevo.';

  @override
  String get apiDisplayInformationUnavailable => 'Información no disponible';

  @override
  String get apiDisplayAddressUnavailable => 'Dirección no disponible';

  @override
  String get apiDisplayCopied => 'Copiado';

  @override
  String get apiDisplayDataCopied => 'Datos copiados';

  @override
  String get apiDisplayTransactionSummaryCopied =>
      'Resumen de la transacción copiado al portapapeles.';

  @override
  String get apiDisplayReceiveCancelled => 'Recepción cancelada.';

  @override
  String get detailReference => 'Referencia';

  @override
  String get detailRequestCode => 'Código del pedido';

  @override
  String get detailConfirmationCode => 'Código de confirmación';

  @override
  String get detailLightningCode => 'Código Lightning';

  @override
  String get detailType => 'Tipo';

  @override
  String get detailBtcAmount => 'BTC';

  @override
  String get detailPaymentLink => 'Pago por enlace';

  @override
  String get detailExternalWithdrawal => 'Retiro externo';

  @override
  String get detailInternalMovement => 'Movimiento interno';

  @override
  String get detailBitcoinNetwork => 'Red Bitcoin';

  @override
  String get qrScannerInstruction => 'Alinea el código QR dentro del marco.';

  @override
  String get errorPopupSuccessTitle => 'Listo';

  @override
  String get errorPopupTransactionTitle =>
      'No pudimos completar la transacción';

  @override
  String get errorPopupBalanceTitle => 'Saldo necesario';

  @override
  String get errorPopupNetworkTitle => 'Conexión no disponible';

  @override
  String get errorPopupAccessTitle => 'Falló la verificación de acceso';

  @override
  String get errInvalidNetworkAddress =>
      'Esta dirección Bitcoin no coincide con la red de esta billetera. Revísala e inténtalo de nuevo.';

  @override
  String get errCustodyProviderUnavailable =>
      'Esta opción de movimiento no está disponible en este momento. Prueba otra opción o vuelve más tarde.';

  @override
  String get errPayloadTooLarge =>
      'Este contenido es demasiado grande para enviarlo con seguridad.';

  @override
  String get errPasskeyDeviceNotLinked =>
      'Este dispositivo no está vinculado a tu cuenta para confirmar con passkey. Vincula este dispositivo e inténtalo de nuevo.';

  @override
  String get errPasskeyRequired =>
      'Se requiere una passkey compatible con este acceso para completar esta operación.';

  @override
  String get errPasskeyWrongDevice =>
      'Esta passkey no sirve para este acceso. Entra con contraseña y código del autenticador, luego vincula una nueva passkey en este dispositivo.';

  @override
  String get errPasskeyRejected =>
      'La passkey fue rechazada en esta operación. Si el problema persiste, vincula otra passkey compatible.';

  @override
  String get errPasskeyLinkGuidance =>
      'Entra con contraseña y código del autenticador, luego vincula una passkey compatible con este dispositivo.';

  @override
  String get errReceiverNotReady =>
      'Este usuario todavía no está listo para recibir fondos.';

  @override
  String get errOnchainReceiverMethodNotFound =>
      'Este usuario no tiene una billetera on-chain registrada para recibir.';

  @override
  String get errOnchainInvalidAddress =>
      'La dirección Bitcoin informada no es válida para esta red.';

  @override
  String get errOnchainAmountBelowDust =>
      'El monto es demasiado bajo para enviarlo on-chain después de las comisiones.';

  @override
  String get errOnchainInsufficientFundsForFee =>
      'Saldo insuficiente para cubrir el monto y la comisión de red.';

  @override
  String get errLightningInsufficientLiquidity =>
      'No hay suficiente liquidez Lightning para completar este envío ahora. Prueba otro método o un monto menor.';

  @override
  String get errLightningRouteNotFound =>
      'No encontramos una ruta Lightning confiable para este pago.';

  @override
  String get errLightningReceiverMethodNotFound =>
      'Este usuario todavía no configuró recepción Lightning.';

  @override
  String get errQuoteExpired =>
      'La cotización expiró. Genera una nueva antes de confirmar.';

  @override
  String get errQuoteChanged =>
      'La cotización cambió. Revisa los valores actualizados antes de confirmar.';

  @override
  String get errNetAmountNegative =>
      'El monto neto quedaría por debajo de cero después de las comisiones.';

  @override
  String get errInsufficientBalanceForFees =>
      'Saldo insuficiente para cubrir el monto y las comisiones.';

  @override
  String get homeTxReceived => 'Recibido';

  @override
  String get homeTxSent => 'Enviado';

  @override
  String get homeTxPaid => 'Pagado';

  @override
  String get homeNow => 'ahora';

  @override
  String homeMinutesAgo(int count) {
    return 'hace $count min';
  }

  @override
  String homeHoursAgo(int count) {
    return 'hace $count h';
  }

  @override
  String homeYesterdayAt(String time) {
    return 'Ayer a las $time';
  }

  @override
  String get homeWalletRequiredTitle => 'Billetera necesaria';

  @override
  String get homeWalletRequiredMessage =>
      'Selecciona o crea una billetera antes de usar esta acción.';

  @override
  String get homeNfcUnavailable =>
      'NFC no está disponible en este dispositivo en este momento.';

  @override
  String get homeSendInternalLabel => 'Enviar dentro de Kerosene';

  @override
  String get homeSendInternalSubtitle =>
      'Transferencia inmediata entre cuentas';

  @override
  String get homeSendOnchainLabel => 'Enviar on-chain';

  @override
  String get homeSendOnchainSubtitle => 'A una dirección Bitcoin';

  @override
  String get homeSendLightningLabel => 'Enviar por Lightning';

  @override
  String get homeSendLightningSubtitle => 'Invoice, LNURL o Lightning Address';

  @override
  String get homeSendMethodOnchainLabel => 'On-chain';

  @override
  String get homeSendMethodOnchainSubtitle =>
      'Envía a cualquier dirección Bitcoin en la red.';

  @override
  String get homeSendMethodLightningLabel => 'Lightning';

  @override
  String get homeSendMethodLightningSubtitle =>
      'Envía instantáneamente por Lightning Network.';

  @override
  String get homeSendMethodInternalLabel => 'Interno Kerosene';

  @override
  String get homeSendMethodInternalSubtitle =>
      'Transferencia instantánea y sin tarifa.';

  @override
  String get homeScanQrLabel => 'Escanear QR';

  @override
  String get homeScanQrSubtitle => 'Leer cobro o dirección';

  @override
  String get homePaymentLinkLabel => 'Enlace de pago';

  @override
  String get homePaymentLinkSubtitle =>
      'Pega un enlace interno, URI on-chain, pedido Lightning o ID de cobro.';

  @override
  String get homeNfcPayLabel => 'Pagar por NFC';

  @override
  String get homeNfcPaySubtitle => 'Acerca el dispositivo para iniciar';

  @override
  String get homeSendTitle => 'Enviar';

  @override
  String get homePrimaryNoWalletTitle => 'Configura tu billetera principal';

  @override
  String get homePrimaryNoWalletSubtitle =>
      'Crea una billetera para recibir, enviar y seguir tu saldo con seguridad.';

  @override
  String get homePrimaryReadyNoBalanceTitle => 'Billetera lista para usar';

  @override
  String get homePrimaryReadyNoBalanceSubtitle =>
      'Deposita cuando quieras. Seguimos la confirmación de red en tiempo real.';

  @override
  String get homePrimaryReadyTitle => 'Listo para mover fondos';

  @override
  String get homePrimaryReadySubtitle =>
      'Accede a las principales acciones de la billetera con confirmación clara antes de cada pago.';

  @override
  String get homeCreateWalletAction => 'Crear billetera';

  @override
  String get homeDepositFundsAction => 'Depositar fondos';

  @override
  String get homeSendBtcAction => 'Enviar BTC';

  @override
  String get homeReceiveBtcAction => 'Recibir BTC';

  @override
  String get homeViewDepositsAction => 'Ver depósitos';

  @override
  String get homePendingLinkTitle => 'Esperando datos';

  @override
  String get homePendingLinkMessage =>
      'Pega un enlace, pedido Lightning, dirección Bitcoin o código Kerosene.';

  @override
  String get homeLightningPaymentTitle => 'Pago Lightning';

  @override
  String get homeOnchainPaymentTitle => 'Pago on-chain';

  @override
  String get homeInternalTransferTitle => 'Transferencia interna';

  @override
  String get homeInvalidLinkTitle => 'Código inválido';

  @override
  String get homeInvalidLinkMessage =>
      'Elimina espacios o saltos de línea e inténtalo de nuevo.';

  @override
  String get homeInternalLinkTitle => 'Enlace interno';

  @override
  String get homeInvoiceOrLnurl => 'Invoice o LNURL';

  @override
  String get homeBitcoinAddress => 'Dirección Bitcoin';

  @override
  String get homeKeroseneUser => 'Usuario Kerosene';

  @override
  String get homePaymentId => 'ID del pago';

  @override
  String get homePaymentLinkTitle => 'Enlace de pago';

  @override
  String get homePayloadLabel => 'Datos del pago';

  @override
  String get homePayloadHint =>
      'Enlace Kerosene, bitcoin:..., lightning:... o ID';

  @override
  String get homePasteAction => 'Pegar';

  @override
  String get homePayloadActionContinueOnchain => 'Continuar on-chain';

  @override
  String get homePayloadActionContinueLightning => 'Continuar Lightning';

  @override
  String get homePayloadActionContinueInternal => 'Continuar interno';

  @override
  String get homePayloadActionLoadLink => 'Cargar enlace';

  @override
  String get homePayloadActionContinue => 'Continuar';

  @override
  String get homeAmountFromLink => 'Definido por el enlace';

  @override
  String get homeAmountNotProvided => 'No informado';

  @override
  String get homeDestinationLocked => 'Destino protegido';

  @override
  String get homeLoadingLinkData => 'Cargando datos del enlace';

  @override
  String get homeLinkValidationLater =>
      'Los detalles se validarán al continuar';

  @override
  String get homeNetworkLabel => 'Red';

  @override
  String get homeDestinationLabel => 'Destino';

  @override
  String get homeAmountLabel => 'Monto';

  @override
  String get homeNetworkInternal => 'Interno';

  @override
  String get homeNetworkOnchain => 'On-chain';

  @override
  String get homeNetworkLightning => 'Lightning';

  @override
  String get homeNetworkInvalid => 'Inválido';

  @override
  String get homeNetworkWaiting => 'Esperando';

  @override
  String get homeEmptyNoWalletTitle => 'Crea tu primera billetera';

  @override
  String get homeEmptyNoWalletDescription =>
      'Necesitas una billetera para empezar a mover fondos.';

  @override
  String get homeEmptyNoBalanceTitle => 'Agrega saldo para comenzar';

  @override
  String get homeEmptyNoBalanceDescription =>
      'Cuando llegue el primer depósito, tus movimientos aparecerán aquí.';

  @override
  String get homeEmptyNoTransactionsTitle => 'Sin transacciones recientes';

  @override
  String get homeEmptyNoTransactionsDescription =>
      'Los nuevos movimientos aparecerán automáticamente en esta área.';

  @override
  String get homeDepositAction => 'Depositar';

  @override
  String get homeRefreshAction => 'Actualizar';

  @override
  String get homeFullHistory => 'Ver historial completo';

  @override
  String get homeLoadingTransactionsTitle => 'Cargando';

  @override
  String get homeLoadingTransactionsSubtitle =>
      'Sincronizando tus movimientos.';

  @override
  String get homeOpenReceiveScreen => 'Abrir pantalla de recepción';

  @override
  String get homeReceiveActionShort => 'Recibir';

  @override
  String homeGreetingMorning(String name) {
    return 'Buen día, $name';
  }

  @override
  String homeGreetingAfternoon(String name) {
    return 'Buenas tardes, $name';
  }

  @override
  String homeGreetingEvening(String name) {
    return 'Buenas noches, $name';
  }

  @override
  String get homeBalanceTotalLabel => 'SALDO TOTAL';

  @override
  String get homeLiveQuoteLabel => 'Cotización activa';

  @override
  String get homeKeroseneWalletLabel => 'BILLETERA KEROSENE';

  @override
  String get homeOnchainWalletLabel => 'BILLETERA ON-CHAIN';

  @override
  String get homeOtherWalletsLabel => 'OTROS';

  @override
  String get homeSecurityBannerTitle => 'Bitcoins bajo tu control.';

  @override
  String get homeSecurityBannerSubtitle =>
      'Seguridad de punta para proteger lo que es tuyo.';

  @override
  String get homeLearnMoreAction => 'Saber más';

  @override
  String get homeSendBitcoinTitle => 'Enviar Bitcoin';

  @override
  String get homeSendBitcoinSubtitle =>
      'Elige cómo quieres enviar tus bitcoins.';

  @override
  String homeTodayAt(String time) {
    return 'Hoy, $time';
  }

  @override
  String get homeCounterpartyTo => 'para';

  @override
  String get homeCounterpartyFrom => 'de';

  @override
  String get authAccountAccessTitle => 'Acceso a la cuenta';

  @override
  String get authAccountPasswordLabel => 'Contraseña de la cuenta';

  @override
  String get authUsernameRequiredMessage =>
      'Ingresa el nombre de usuario de la cuenta.';

  @override
  String get authAccessEyebrow => 'Acceder a la cuenta';

  @override
  String get authUsernameStepSubtitle =>
      'Primero ingresa tu nombre de usuario.';

  @override
  String get authUsernameHint => 'Nombre de usuario';

  @override
  String get authPasskeyFirstNoteTitle => 'Acceso protegido';

  @override
  String get authPasskeyFirstNoteBody =>
      'Kerosene verifica primero la llave de este dispositivo.';

  @override
  String get authPrivateAccessEyebrow => 'Acceso privado';

  @override
  String get authAccountPasswordTitle => 'Contraseña de la cuenta';

  @override
  String get authAccountPasswordHint => 'Ingresa tu contraseña';

  @override
  String get authCredentialSendingTitle => 'Entrando';

  @override
  String get authCredentialTitle => 'Credencial';

  @override
  String get authCredentialSendingBody =>
      'Estamos protegiendo tu entrada. Espera un momento.';

  @override
  String get authCredentialBody =>
      'Usa la contraseña de la cuenta para continuar. Tus llaves de billetera nunca se solicitan en este acceso.';

  @override
  String get authSignInAction => 'Entrar';

  @override
  String get authFlowInterruptedTitle => 'No pudimos continuar';

  @override
  String get authInvalidUsernameTitle => 'Nombre de usuario inválido';

  @override
  String get authWeakPasswordTitle => 'Contraseña débil';

  @override
  String get authInvalidConfirmationTitle => 'Confirmación inválida';

  @override
  String get authPasswordMismatchMessage =>
      'La confirmación de contraseña no coincide.';

  @override
  String get authConfirmationRequiredTitle => 'Confirmación necesaria';

  @override
  String get authPasswordRiskRequiredMessage =>
      'Confirma que entiendes la importancia de guardar la contraseña de la cuenta.';

  @override
  String get authAccountEyebrow => 'Cuenta';

  @override
  String get authCreateAccountTitle => 'Crear cuenta';

  @override
  String get authCreateAccountSubtitle =>
      'Elige tus credenciales de acceso a Kerosene.';

  @override
  String get authSignupUsernameSubtitleDetailed =>
      'Elige un nombre de usuario. Se usará para identificarte en Kerosene.';

  @override
  String get authSignupUsernameLabel => 'Nombre de usuario';

  @override
  String get authSignupUsernameRuleMin => 'Mínimo de 3 caracteres';

  @override
  String get authSignupUsernameRuleCharset =>
      'Solo letras minúsculas (a-z), números (0-9) y guion bajo (_)';

  @override
  String get authSignupUsernameRuleLowercase => 'Se mostrará en minúsculas';

  @override
  String get authUsernameMinError => 'Usa al menos 3 caracteres.';

  @override
  String get authUsernameCharsError =>
      'Usa solo letras minúsculas, números y guion bajo.';

  @override
  String get authPasswordStrengthMessage =>
      'Usa al menos 12 caracteres con mayúscula, minúscula, número y símbolo.';

  @override
  String get authSignupPassphraseTitle => 'Crea una passphrase fuerte';

  @override
  String get authSignupPassphraseSubtitle =>
      'Protege tu cuenta y tus activos. Nadie en Kerosene tiene acceso a ella.';

  @override
  String get authSignupPassphraseLabel => 'Passphrase';

  @override
  String get authSignupPassphraseRuleMin => 'Mínimo de 12 caracteres';

  @override
  String get authSignupPassphraseRuleUppercase => 'Al menos 1 letra mayúscula';

  @override
  String get authSignupPassphraseRuleLowercase => 'Al menos 1 letra minúscula';

  @override
  String get authSignupPassphraseRuleNumber => 'Al menos 1 número';

  @override
  String get authSignupPassphraseRuleSymbol => 'Al menos 1 símbolo';

  @override
  String get authSignupConfirmPassphraseTitle => 'Confirma tu passphrase';

  @override
  String get authSignupConfirmPassphraseSubtitle =>
      'Escríbela de nuevo para confirmar.';

  @override
  String get authSignupConfirmPassphraseLabel => 'Confirmar passphrase';

  @override
  String get authSignupPassphraseRiskAcknowledgement =>
      'Entiendo que mi passphrase es la única forma de acceder a mi cuenta. Kerosene no puede restablecerla ni recuperarla. Si pierdo mi passphrase, puedo perder acceso a mis activos permanentemente.';

  @override
  String get authSignupCreatingTitle => 'Creando tu cuenta de forma segura';

  @override
  String get authSignupCreatingSubtitle => 'Esto puede tardar unos segundos.';

  @override
  String get authSignupCreatingChallenge => 'Obteniendo desafío de seguridad';

  @override
  String get authSignupCreatingPow => 'Resolviendo prueba de trabajo';

  @override
  String get authSignupCreatingAccount => 'Creando tu cuenta';

  @override
  String get authSignupPowNote =>
      'La prueba de trabajo ayuda a proteger nuestra red contra abusos y bots.';

  @override
  String get authSignupTotpOptionalTitle =>
      'Protege aún más tu cuenta (opcional)';

  @override
  String get authSignupTotpOptionalSubtitle =>
      'Activa TOTP para una capa extra de seguridad.';

  @override
  String get authSignupTotpScanInstruction =>
      'Escanea el código QR con tu app autenticadora';

  @override
  String get authSignupTotpCodeLabel => 'Código de 6 dígitos';

  @override
  String get authSignupRecoveryCodesTitle => 'Códigos de recuperación';

  @override
  String get authSignupRecoveryCodesBody =>
      'Guárdalos en un lugar seguro. Pueden usarse para recuperar tu cuenta.';

  @override
  String get authSignupSkipForNowAction => 'Omitir por ahora';

  @override
  String get authSignupConfirmTotpAction => 'Confirmar TOTP';

  @override
  String get authSignupPasskeyTitle => 'Registrar passkey en este dispositivo';

  @override
  String get authSignupPasskeySubtitle =>
      'La passkey es obligatoria para garantizar acceso seguro a tu cuenta.';

  @override
  String get authSignupPasskeyBiometricBullet =>
      'Usa tu biometría o bloqueo de pantalla';

  @override
  String get authSignupPasskeyPasswordBullet =>
      'Más seguro que las contraseñas tradicionales';

  @override
  String get authSignupPasskeyDeviceBullet =>
      'Solo este dispositivo tendrá acceso';

  @override
  String get authSignupRegisterPasskeyAction => 'Registrar passkey';

  @override
  String get authSignupSuccessTitle => 'Cuenta creada con éxito';

  @override
  String get authSignupSuccessPreparingSubtitle =>
      'Preparando tu acceso con seguridad.';

  @override
  String get authSignupSuccessSubtitle => 'Redirigiendo a tu billetera...';

  @override
  String get authSignupTotpCodeRequiredMessage =>
      'Ingresa el código TOTP de 6 dígitos para confirmar.';

  @override
  String get authAccountCredentialsTitle => 'Cuenta y credenciales';

  @override
  String get authAccountCredentialsBody =>
      'Elige tu identificador público. La contraseña se define en la próxima etapa.';

  @override
  String get authCustodyNoteTitle => 'Guárdalo con cuidado';

  @override
  String get authCustodyNoteBody =>
      'Si pierdes la contraseña sin códigos de recuperación, podrías perder el acceso a la cuenta. Guarda los códigos en un lugar seguro.';

  @override
  String get authStrongPasswordTitle => 'Contraseña fuerte';

  @override
  String get authStrongPasswordBody =>
      'Usa una contraseña larga, única y difícil de adivinar.';

  @override
  String get authPasswordReadyTitle => 'Lista';

  @override
  String get authPasswordMinimumTitle => 'Regla mínima';

  @override
  String get authPasswordRuleBody =>
      '12 caracteres o más, con mayúscula, minúscula, número y símbolo.';

  @override
  String get authBackAction => 'Volver';

  @override
  String get authReadyAction => 'Listo';

  @override
  String get authConfirmPasswordTitle => 'Confirmar contraseña';

  @override
  String get authConfirmPasswordBody =>
      'Repite la contraseña y confirma que sabes dónde guardarla.';

  @override
  String get authConfirmPasswordLabel => 'Confirmar contraseña';

  @override
  String get authPasswordRiskAcknowledgement =>
      'Entiendo que perder la contraseña puede impedir mi acceso a la cuenta.';

  @override
  String get authCreateAction => 'Crear';

  @override
  String get authPasskeyRegisterTitle => 'Registrar llave del dispositivo';

  @override
  String get authPasskeyRegisterBody =>
      'Finaliza creando la llave segura de este dispositivo para proteger el acceso.';

  @override
  String get authDeviceTitle => 'Dispositivo';

  @override
  String get authDeviceBody =>
      'La llave de este dispositivo ayuda a confirmar que eres tú al entrar en la cuenta.';

  @override
  String get authRegisterPasskeyAction => 'Registrar llave';

  @override
  String get authPasskeyStepLabel => 'Llave';

  @override
  String get authSignupStepFallbackLabel => 'Registro';

  @override
  String get authSignupStepUsernameTitle => 'Nombre de usuario';

  @override
  String get authSignupStepPasswordTitle => 'Contraseña';

  @override
  String get authSignupStepConfirmationTitle => 'Confirmación';

  @override
  String get authSignupStepCreationTitle => 'Creación';

  @override
  String get authPasswordLongHint => '12 caracteres o más';

  @override
  String get authSessionInterruptedTitle => 'Sesión interrumpida';

  @override
  String get authSignupSessionExpiredMessage =>
      'Tu sesión de registro expiró. Reinicia la creación de cuenta para continuar con seguridad.';

  @override
  String get authSecurityPreparingTitle => 'Preparando seguridad';

  @override
  String get authSecurityPreparingMessage =>
      'La protección de la cuenta aún se está preparando. Inténtalo de nuevo en unos segundos.';

  @override
  String get homeFallbackUser => 'Usuario';

  @override
  String get walletEditNameAction => 'Editar nombre';

  @override
  String get securityCopiedTitle => 'Copiado';

  @override
  String securityCopiedMessage(String label) {
    return '$label copiado al portapapeles.';
  }

  @override
  String get securityTotpFailureTitle =>
      'No pudimos actualizar el autenticador';

  @override
  String get securityInvalidCodeTitle => 'Código inválido';

  @override
  String get securityTotpCodeRequiredMessage =>
      'Ingresa los 6 dígitos del autenticador.';

  @override
  String get securityTotpEnabledTitle => 'Autenticador activado';

  @override
  String get securityTotpEnabledMessage =>
      'Tu cuenta ahora tiene una capa adicional de protección.';

  @override
  String get securityTotpDisableFailedTitle =>
      'No pudimos desactivar el autenticador';

  @override
  String get securityTotpDisabledTitle => 'Autenticador desactivado';

  @override
  String get securityTotpDisabledMessage =>
      'La protección por autenticador fue eliminada de esta cuenta.';

  @override
  String get securityBackupRegenerateFailedTitle =>
      'No pudimos generar nuevos códigos';

  @override
  String get securityBackupCodesTitle => 'Códigos de recuperación';

  @override
  String get securityBackupCodesBody =>
      'Guarda estos códigos fuera de este dispositivo. Pueden ayudar a recuperar el acceso.';

  @override
  String get securityBackupCodesCopyLabel => 'Códigos de recuperación';

  @override
  String get securityBackupCodesCopyAction => 'Copiar códigos';

  @override
  String get securityRegisterDeviceFailedTitle =>
      'No pudimos registrar el dispositivo';

  @override
  String get securityDeviceRegisteredTitle => 'Dispositivo registrado';

  @override
  String get securityDeviceRegisteredMessage =>
      'Este dispositivo ahora está vinculado a tu cuenta.';

  @override
  String get securityDeviceInventoryLoadingSubtitle =>
      'La cuenta tiene un dispositivo autenticado, pero los detalles aún se están cargando.';

  @override
  String get securityRegisterDeviceSubtitle =>
      'Registra este dispositivo como dispositivo autenticado.';

  @override
  String get securityCompatibleDeviceOne =>
      'Existe 1 dispositivo compatible con este acceso.';

  @override
  String securityCompatibleDeviceMany(int count) {
    return 'Existen $count dispositivos compatibles con este acceso.';
  }

  @override
  String get securityLegacyDeviceSubtitle =>
      'Algunos dispositivos antiguos tienen compatibilidad limitada. Vincula este dispositivo otra vez si el acceso falla.';

  @override
  String get securityNoCompatibleDeviceSubtitle =>
      'Los dispositivos registrados no son compatibles con este acceso. Entra con contraseña y autenticador para vincular otro.';

  @override
  String get securityScreenTitle => 'Seguridad';

  @override
  String get securityScreenSubtitle =>
      'Dispositivos autenticados, autenticador, códigos de recuperación y PIN de este dispositivo.';

  @override
  String get securityUnprotectedTitle => 'Cuenta no protegida';

  @override
  String get securityUnprotectedFallback =>
      'Activa el autenticador para agregar una capa opcional de protección.';

  @override
  String get securityPinEntryTitle => 'PIN de entrada';

  @override
  String get securityPinLoadError =>
      'No pudimos consultar el PIN de este dispositivo.';

  @override
  String get securityAuthenticatedDevicesTitle => 'Dispositivos autenticados';

  @override
  String get securityRegisteredDeviceSubtitle =>
      'Este dispositivo está registrado para esta cuenta.';

  @override
  String get securityRegisterThisDeviceSubtitle => 'Registra este dispositivo.';

  @override
  String get securityLinkNewDeviceAction => 'Vincular nuevo dispositivo';

  @override
  String get securityRegisterDeviceAction => 'Registrar dispositivo';

  @override
  String get securityDeviceCompatibilityError =>
      'No pudimos consultar la compatibilidad de los dispositivos para este acceso.';

  @override
  String get securityTotpOptionalTitle => 'Autenticador opcional';

  @override
  String get securityTotpEnabledSubtitle =>
      'Autenticador activo. El aviso de cuenta no protegida no aparece.';

  @override
  String get securityTotpDisabledSubtitle =>
      'Sin autenticador. La cuenta queda marcada como no protegida.';

  @override
  String get securityDisableTotpAction => 'Desactivar autenticador';

  @override
  String get securityEnableTotpAction => 'Activar autenticador';

  @override
  String securityBackupCodesRemaining(int count) {
    return '$count códigos restantes. Guárdalos en un lugar seguro.';
  }

  @override
  String get securityBackupCodesLockedSubtitle =>
      'Activa el autenticador para liberar códigos de recuperación.';

  @override
  String get securityRegenerateCodesAction => 'Generar nuevos códigos';

  @override
  String get securityWaitingTotpAction => 'Esperando autenticador';

  @override
  String get securityViewLatestAction => 'Ver últimos';

  @override
  String get securityBackupCodesLoadError =>
      'No pudimos consultar los códigos de recuperación.';

  @override
  String get securityStatusLoadError =>
      'No pudimos consultar el estado de seguridad de la cuenta.';

  @override
  String get securityCurrentStatusTitle => 'Estado actual';

  @override
  String get securityStrongPasswordPill => 'Contraseña fuerte';

  @override
  String get securityDevicePill => 'Dispositivo';

  @override
  String get securityInboundPill => 'Recepción';

  @override
  String get securityAppPinPill => 'PIN de entrada';

  @override
  String get securityLocalBiometricsPill => 'Biometría local';

  @override
  String get securityCurrentHostLabel => 'Dispositivo actual';

  @override
  String get securityCurrentRpLabel => 'Dominio de acceso';

  @override
  String get securityLegacyCredentialsTitle =>
      'Credenciales antiguas detectadas';

  @override
  String get securityLegacyCredentialsBody =>
      'Existen dispositivos antiguos con detalles incompletos. Sustitúyelos por una nueva llave cuando sea posible.';

  @override
  String get securityNoAuthenticatedDevice =>
      'Ningún dispositivo autenticado fue vinculado para esta cuenta en este contexto.';

  @override
  String get securityDeviceDetailsUnavailable =>
      'El dispositivo está activo, pero los detalles aún no están disponibles.';

  @override
  String get securityInventoryNotLoaded =>
      'Los detalles de los dispositivos aún no se cargaron.';

  @override
  String get securityInventoryNone =>
      'Ningún dispositivo autenticado registrado para esta cuenta.';

  @override
  String get securityInventoryCompatible =>
      'Al menos un dispositivo autenticado puede usarse para este acceso.';

  @override
  String get securityInventoryLegacy =>
      'Algunos dispositivos tienen detalles incompletos. Revisa la lista antes de depender de ellos.';

  @override
  String get securityInventoryIncompatible =>
      'Los dispositivos vinculados actualmente no sirven para este acceso.';

  @override
  String get securityInventoryUnknownBanner =>
      'No pudimos determinar si este acceso tiene un dispositivo utilizable.';

  @override
  String get securityInventoryRegisterBanner =>
      'Vincula este dispositivo para liberar confirmaciones y acceso compatibles.';

  @override
  String securityInventoryCompatibleCount(int count) {
    return '$count dispositivos pueden confirmar este acceso ahora.';
  }

  @override
  String get securityInventoryCompatibleFallback =>
      'Existe al menos un dispositivo compatible con este acceso.';

  @override
  String get securityInventoryLegacyBanner =>
      'Hay credenciales antiguas. Si este acceso falla, entra con contraseña y autenticador para vincular este dispositivo otra vez.';

  @override
  String get securityInventoryIncompatibleBanner =>
      'No se encontró ningún dispositivo compatible para este acceso. Entra con contraseña y autenticador para vincular otro.';

  @override
  String get securityPinActiveLockedSubtitle =>
      'PIN de entrada activo. Está bloqueado temporalmente en este dispositivo.';

  @override
  String securityPinActiveAttemptsSubtitle(int count) {
    return 'PIN de entrada activo. Quedan $count intentos antes del bloqueo.';
  }

  @override
  String get securityPinDisabledSubtitle =>
      'Protege la entrada al app en este dispositivo con un PIN independiente de tu contraseña principal.';

  @override
  String get securityChangePinAction => 'Cambiar PIN';

  @override
  String get securityEnablePinAction => 'Activar PIN';

  @override
  String get securityDisableAction => 'Desactivar';

  @override
  String get securityPinMismatchError =>
      'El nuevo PIN y la confirmación deben coincidir.';

  @override
  String get securityPinEnableTitle => 'Activar PIN de entrada';

  @override
  String get securityPinChangeTitle => 'Cambiar PIN de este dispositivo';

  @override
  String get securityPinDisableTitle => 'Desactivar PIN de entrada';

  @override
  String get securityPinEnableBody =>
      'El PIN será solicitado cada vez que el app se abra con esta sesión en este dispositivo.';

  @override
  String get securityPinChangeBody =>
      'Usa el PIN actual o un código del autenticador para registrar un nuevo PIN.';

  @override
  String get securityPinDisableBody =>
      'Usa el PIN actual o un código del autenticador para quitar esta barrera de entrada del dispositivo.';

  @override
  String get securityCurrentPinLabel => 'PIN actual o código del autenticador';

  @override
  String get securityTotpCodeLabel => 'Código del autenticador';

  @override
  String securityNewPinLabel(int min, int max) {
    return 'Nuevo PIN ($min-$max dígitos)';
  }

  @override
  String get securityConfirmNewPinLabel => 'Confirmar nuevo PIN';

  @override
  String get securityDisablePinAction => 'Desactivar PIN';

  @override
  String get securitySavePinAction => 'Guardar PIN';

  @override
  String get securityDeviceBrandLabel => 'Marca';

  @override
  String get securityDeviceModelLabel => 'Modelo';

  @override
  String get securityDeviceSerialLabel => 'Número de serie';

  @override
  String get securityDeviceInstallIdLabel => 'ID de instalación';

  @override
  String get securityDeviceBrowserLabel => 'Navegador';

  @override
  String get securityDeviceSystemLabel => 'Sistema';

  @override
  String get securityDeviceStatusLabel => 'Estado';

  @override
  String get securityDeviceFirstAccessLabel => 'Primer acceso';

  @override
  String get securityDeviceLastAccessLabel => 'Último acceso';

  @override
  String get securityDeviceOriginLabel => 'Origen';

  @override
  String get securityDeviceRelyingPartyLabel => 'Dominio de acceso';

  @override
  String get securityDeviceCanUse => 'Puede usarse en este acceso.';

  @override
  String get securityDeviceCannotUse => 'No puede usarse en el acceso actual.';

  @override
  String get securityDeviceUnknownUse =>
      'Compatibilidad aún no determinada para esta credencial.';

  @override
  String get securityDeviceBlockAction => 'Bloquear';

  @override
  String get securityDeviceRevokeAction => 'Revocar';

  @override
  String get securityDeviceBlockFailedTitle =>
      'No pudimos bloquear el dispositivo';

  @override
  String get securityDeviceRevokeFailedTitle =>
      'No pudimos revocar el dispositivo';

  @override
  String get securityDeviceBlockedTitle => 'Dispositivo bloqueado';

  @override
  String get securityDeviceBlockedMessage =>
      'Esta credencial no podrá confirmar nuevos accesos hasta que sea reactivada en el backend.';

  @override
  String get securityDeviceRevokedTitle => 'Dispositivo revocado';

  @override
  String get securityDeviceRevokedMessage =>
      'Esta credencial fue removida del conjunto de dispositivos autenticados.';

  @override
  String get securityStatusPending => 'Pendiente';

  @override
  String get securityStatusBlocked => 'Bloqueado';

  @override
  String get securityStatusRevoked => 'Revocado';

  @override
  String get securityStatusActive => 'Activo';

  @override
  String get securityCompatibleBadge => 'Compatible';

  @override
  String get securityIncompatibleBadge => 'Incompatible';

  @override
  String get securityUnknownBadge => 'Desconocido';

  @override
  String get securityTotpSetupTitle => 'Activar autenticador';

  @override
  String get securityCopySecretAction => 'Copiar secreto';

  @override
  String get securityValidateTotpAction => 'Validar código';

  @override
  String get settingsUiSecurityAccessSection => 'Seguridad y acceso';

  @override
  String get settingsUiEnterpriseAccessSection => 'Acceso empresarial';

  @override
  String get settingsUiPrivacySection => 'Privacidad';

  @override
  String get settingsUiAccountAccessSection => 'Cuenta y acceso';

  @override
  String get settingsUiNotificationsSection => 'Notificaciones';

  @override
  String get settingsUiAppearanceSection => 'Apariencia';

  @override
  String get settingsUiLocaleCurrencySection => 'Idioma y moneda';

  @override
  String get settingsUiSessionSection => 'Sesión';

  @override
  String get settingsUiOperationalSummaryTitle => 'Resumen operativo';

  @override
  String get settingsUiAlertsLabel => 'Alertas';

  @override
  String get settingsUiAlertsBackgroundActive => 'Segundo plano activo';

  @override
  String get settingsUiDisabled => 'Desactivado';

  @override
  String get settingsUiThemeLabel => 'Tema';

  @override
  String get settingsUiChecking => 'Verificando';

  @override
  String get settingsUiActive => 'Activa';

  @override
  String get settingsUiInactive => 'Desactivada';

  @override
  String get settingsUiUnavailable => 'No disponible';

  @override
  String get settingsUiDecimalPrecisionTitle => 'Precisión decimal';

  @override
  String settingsUiDecimalPrecisionSubtitle(int count) {
    return 'Mostrando $count decimales';
  }

  @override
  String get settingsUiHideBalanceTitle => 'Ocultar saldo';

  @override
  String get settingsUiBalanceHiddenSubtitle =>
      'Valores ocultos en la interfaz principal';

  @override
  String get settingsUiBalanceVisibleSubtitle =>
      'Valores visibles en pantallas operativas';

  @override
  String get settingsUiSovereigntyReportTitle => 'Reporte de soberanía';

  @override
  String get settingsUiSovereigntyReportSubtitle =>
      'Abrir el panel de atestación, consenso e integridad operativa';

  @override
  String get settingsUiSecurityUnprotectedSubtitle =>
      'Cuenta no protegida. Revisa autenticador y códigos de recuperación.';

  @override
  String get settingsUiSecurityProtectedSubtitle =>
      'Cuenta protegida con contraseña fuerte, dispositivos autenticados y factores opcionales.';

  @override
  String get settingsUiSecurityLoadingSubtitle =>
      'Consultando estado de la cuenta';

  @override
  String get settingsUiSecurityErrorSubtitle =>
      'No pudimos consultar la seguridad de la cuenta';

  @override
  String get settingsUiPasskeyRegisteredSubtitle =>
      'Dispositivo autenticado ya registrado para esta cuenta';

  @override
  String get settingsUiPasskeyRegisterSubtitle =>
      'Registrar este dispositivo con biometría';

  @override
  String get settingsUiPasskeyLoadingSubtitle => 'Consultando dispositivos';

  @override
  String get settingsUiPasskeyErrorSubtitle =>
      'No pudimos consultar dispositivos';

  @override
  String get settingsUiUnprotectedBannerTitle => 'Cuenta no protegida';

  @override
  String get settingsUiUnprotectedBannerBody =>
      'El autenticador está apagado. Abre el centro de seguridad para activar la protección y revisar los códigos de recuperación.';

  @override
  String get settingsUiBiometricUnlockTitle => 'Desbloqueo biométrico';

  @override
  String get settingsUiBiometricUnlockSubtitle =>
      'Usa huella o rostro para desbloquear';

  @override
  String get settingsUiSecurityCenterTitle => 'Centro de seguridad';

  @override
  String get settingsUiSessionsActiveTitle => 'Sesiones activas';

  @override
  String get settingsUiSessionsActiveSubtitle =>
      'Ver y revocar sesiones del dispositivo';

  @override
  String get settingsUiSessionsActiveMessage =>
      'Tus sesiones se protegen automáticamente. Cierra el acceso de este dispositivo si ya no está contigo.';

  @override
  String get settingsUiEnterpriseIntro =>
      'Para uso empresarial, genera una llave de acceso en este dispositivo y guárdala con seguridad.';

  @override
  String get settingsUiEnterpriseKeyLoading =>
      'Consultando llave empresarial...';

  @override
  String get settingsUiEnterpriseKeyLoadError =>
      'No pudimos consultar la llave empresarial.';

  @override
  String get settingsUiEnterpriseCreateKeyTitle => 'Crear llave empresarial';

  @override
  String get settingsUiEnterpriseCreateKeySubtitle =>
      'Genera una llave fuerte en este dispositivo y registra solo la confirmación segura';

  @override
  String get settingsUiEnterpriseRotateKeyTitle => 'Cambiar llave';

  @override
  String get settingsUiEnterpriseRotateKeySubtitle =>
      'Revoca la llave actual y crea una nueva';

  @override
  String get settingsUiEnterpriseRevokeKeyTitle => 'Revocar llave';

  @override
  String get settingsUiEnterpriseRevokeKeySubtitle =>
      'Impide nuevos accesos empresariales hasta crear una nueva llave';

  @override
  String get settingsUiEnterpriseCreateDialogMessage =>
      'Esta llave autoriza el acceso empresarial junto con usuario y contraseña. Guárdala con seguridad. Kerosene nunca pedirá tu seed o frase de recuperación.';

  @override
  String get settingsUiEnterpriseCreateKeyAction => 'Crear llave';

  @override
  String get settingsUiEnterpriseCreateKeyFailed => 'No pudimos crear la llave';

  @override
  String get settingsUiEnterpriseRevokeDialogMessage =>
      'La llave actual dejará de autorizar el acceso empresarial. Crea una nueva en este dispositivo cuando necesites reactivarlo.';

  @override
  String get settingsUiEnterpriseRevokeAction => 'Revocar';

  @override
  String get settingsUiEnterpriseRevokeFailed => 'No pudimos revocar';

  @override
  String get settingsUiEnterpriseKeyRevokedTitle => 'Llave revocada';

  @override
  String get settingsUiEnterpriseKeyRevokedMessage =>
      'El acceso empresarial requerirá una nueva llave.';

  @override
  String get settingsUiEnterpriseDecisionFailed =>
      'No pudimos registrar la decisión';

  @override
  String get settingsUiEnterpriseAccessAllowedTitle => 'Acceso permitido';

  @override
  String get settingsUiEnterpriseDeviceBlockedTitle => 'Dispositivo bloqueado';

  @override
  String get settingsUiEnterpriseAccessAllowedMessage =>
      'El acceso empresarial podrá continuar en el navegador.';

  @override
  String get settingsUiEnterpriseDeviceBlockedMessage =>
      'Nuevos intentos de este dispositivo fueron bloqueados.';

  @override
  String get settingsUiEnterpriseKeyCreatedTitle => 'Llave creada';

  @override
  String get settingsUiEnterpriseKeyCreatedMessage =>
      'Esta llave se mostrará solo ahora. Guárdala con seguridad.';

  @override
  String get settingsUiEnterpriseKeyCopiedMessage =>
      'Llave empresarial copiada.';

  @override
  String get settingsUiCopyAction => 'Copiar';

  @override
  String get settingsUiCloseAction => 'Cerrar';

  @override
  String get settingsUiEnterpriseKeyActive =>
      'Llave activa para acceso empresarial.';

  @override
  String get settingsUiEnterpriseKeyMissing =>
      'Ninguna llave empresarial activa.';

  @override
  String get settingsUiEnterpriseAttemptTitle =>
      'Hubo un intento de acceso empresarial.';

  @override
  String get settingsUiBrowserLabel => 'Navegador';

  @override
  String get settingsUiDeviceLabel => 'Dispositivo';

  @override
  String get settingsUiTimeLabel => 'Horario';

  @override
  String get settingsUiAllowAction => 'Permitir';

  @override
  String get settingsUiBlockAction => 'Bloquear';

  @override
  String get settingsUiAuthenticatedLabel => 'Autenticado';

  @override
  String get settingsUiDeleteAccountTitle => 'Eliminar cuenta';

  @override
  String get settingsUiDeleteAccountSubtitle =>
      'Elimina permanentemente todos los datos';

  @override
  String get settingsUiDeleteAccountDialogTitle => '¿Eliminar cuenta?';

  @override
  String get settingsUiDeleteAccountDialogMessage =>
      'Esto eliminará permanentemente tu cuenta, billeteras y fondos. Esta acción no se puede deshacer.\n\nPara proteger tus recursos, retira todos los saldos antes de eliminar la cuenta.';

  @override
  String get settingsUiDeleteForeverAction => 'Eliminar para siempre';

  @override
  String get settingsUiTransactionSecurityAlertsTitle =>
      'Alertas de transacción y seguridad';

  @override
  String get settingsUiBackgroundAlertsOnSubtitle =>
      'Activo. El app permanece en segundo plano para mostrar transacciones y alertas de seguridad.';

  @override
  String get settingsUiBackgroundAlertsOffSubtitle =>
      'Activa para mantener el app en segundo plano y recibir transacciones y alertas de seguridad.';

  @override
  String get settingsUiInAppBannersTitle => 'Banners dentro del app';

  @override
  String get settingsUiInAppBannersOnSubtitle =>
      'Muestra alertas contextuales en la sesión actual.';

  @override
  String get settingsUiInAppBannersOffSubtitle =>
      'Mantiene el feed, pero no interrumpe la navegación con banners.';

  @override
  String get settingsUiFinancialEventsTitle => 'Eventos financieros';

  @override
  String get settingsUiFinancialEventsOnSubtitle =>
      'Recepciones, envíos, depósitos y enlaces entran en el feed.';

  @override
  String get settingsUiFinancialEventsOffSubtitle =>
      'Oculta alertas de operación financiera en el feed de la sesión.';

  @override
  String get settingsUiSecurityEventsTitle => 'Eventos de seguridad';

  @override
  String get settingsUiSecurityEventsOnSubtitle =>
      'Accesos, recuperación y eventos sensibles siguen destacados.';

  @override
  String get settingsUiSecurityEventsOffSubtitle =>
      'Oculta solo alertas de seguridad de la inbox de la sesión.';

  @override
  String get settingsUiUpdatingBackgroundAlerts =>
      'Actualizando el monitoreo en segundo plano.';

  @override
  String settingsUiBackgroundAlertsInfo(int count) {
    return 'Cuando está activo, Kerosene mantiene un servicio en segundo plano para monitorear envíos, recepciones y eventos críticos de seguridad. En Android, una notificación persistente del sistema quedará visible mientras el monitoreo esté activo. $count alertas aún no fueron leídas en esta sesión.';
  }

  @override
  String get settingsUiPermissionRequiredTitle => 'Permiso necesario';

  @override
  String get settingsUiPermissionRequiredMessage =>
      'El sistema no liberó las notificaciones. Autoriza el app para activar el monitoreo en segundo plano.';

  @override
  String get settingsUiMonitoringActiveTitle => 'Monitoreo activo';

  @override
  String get settingsUiMonitoringInactiveTitle => 'Monitoreo desactivado';

  @override
  String get settingsUiMonitoringActiveMessage =>
      'El app continuará en segundo plano para mostrar transacciones y alertas de seguridad.';

  @override
  String get settingsUiMonitoringInactiveMessage =>
      'Kerosene ya no mantendrá el servicio en segundo plano para alertas.';

  @override
  String get settingsUiAlertsUpdateFailedTitle =>
      'No pudimos actualizar alertas';

  @override
  String get settingsUiAlertsUpdateFailedMessage =>
      'No pudimos cambiar el monitoreo en segundo plano ahora.';

  @override
  String get settingsUiLogoutTitle => 'Cerrar sesión';

  @override
  String get settingsUiLogoutSubtitle => 'Cierra la sesión actual';

  @override
  String get settingsUiLogoutDialogTitle => '¿Cerrar sesión?';

  @override
  String get settingsUiLogoutDialogMessage =>
      'Necesitarás autenticarte de nuevo para acceder a la cuenta.';

  @override
  String get settingsUiAuthenticatedDevicesBody =>
      'Este registro usa el sensor biométrico del dispositivo como llave física de seguridad. Los detalles mostrados usan datos auditables del dispositivo, sin exponer información sensible.';

  @override
  String get settingsUiRegisterNewDeviceAction => 'Registrar nuevo dispositivo';

  @override
  String get settingsUiLearnMoreAction => 'Saber más';

  @override
  String get settingsUiBackgroundAlertsTitle => 'Alertas en segundo plano';

  @override
  String get settingsUiBackgroundAlertsConsentBody =>
      'Al activar esta opción, Kerosene seguirá ejecutándose en segundo plano para mostrar transacciones recibidas, enviadas y alertas críticas de seguridad. En Android, el sistema mantendrá una notificación persistente mientras el monitoreo esté activo.';

  @override
  String get settingsUiEnableMonitoringAction => 'Activar monitoreo';

  @override
  String get settingsUiUnderstoodAction => 'Entendido';

  @override
  String get transactionVisualCancelled => 'Cancelado';

  @override
  String get transactionVisualRefund => 'Reembolso';

  @override
  String get transactionVisualFailed => 'No completado';

  @override
  String get transactionVisualSwap => 'Conversión';

  @override
  String get transactionVisualFee => 'Comisión';

  @override
  String get transactionVisualLightningDeposit => 'Depósito Lightning';

  @override
  String get transactionVisualLightningPayment => 'Pago Lightning';

  @override
  String get transactionVisualLightningReceive => 'Recepción Lightning';

  @override
  String get transactionVisualDeposit => 'Depósito';

  @override
  String get transactionVisualWithdrawal => 'Retiro';

  @override
  String get transactionVisualNfcReceive => 'Recepción por NFC';

  @override
  String get transactionVisualNfcPayment => 'Pago por NFC';

  @override
  String get transactionVisualQrReceive => 'Recepción por QR';

  @override
  String get transactionVisualQrPayment => 'Pago por QR';

  @override
  String get transactionVisualPaymentLinkReceive => 'Recepción por enlace';

  @override
  String get transactionVisualPaymentLinkPayment => 'Pago por enlace';

  @override
  String get transactionVisualInternalReceive => 'Recepción Kerosene';

  @override
  String get transactionVisualInternalSend => 'Envío Kerosene';

  @override
  String get transactionVisualEvent => 'Movimiento';

  @override
  String get transactionVisualOnChainReceive => 'Recepción on-chain';

  @override
  String get transactionVisualOnChainSend => 'Envío on-chain';

  @override
  String get withdrawUiColdWalletSendBlocked =>
      'Esta billetera fría solo se monitorea en el app. Para enviar, firma la transacción en el dispositivo donde guardas tus llaves.';

  @override
  String get withdrawUiLightningDestinationRequired =>
      'Ingresa una solicitud Lightning o LNURL para continuar.';

  @override
  String get withdrawUiLightningDestinationRequiredForFlow =>
      'Ingresa una solicitud Lightning o LNURL para este envío.';

  @override
  String get withdrawUiLightningDestinationWrongFlow =>
      'El destino informado es Lightning. Abre el envío Lightning para continuar.';

  @override
  String get withdrawUiOnchainDestinationWrongFlow =>
      'Este campo recibió una dirección on-chain. Usa una solicitud Lightning o LNURL.';

  @override
  String get withdrawUiLightningFieldWrongFlow =>
      'Este campo recibió una solicitud Lightning. Usa el envío Lightning para continuar.';

  @override
  String withdrawUiConfiguredNetworkMismatch(String network) {
    return 'La dirección informada no pertenece a la red $network configurada para esta billetera.';
  }

  @override
  String withdrawUiNetworkMismatch(String detected, String expected) {
    return 'Esta dirección pertenece a $detected, pero la billetera opera en $expected.';
  }

  @override
  String get withdrawUiWaitFeeEstimate =>
      'Espera la estimación de la comisión de red antes de revisar el total del envío.';

  @override
  String get withdrawUiFeeEstimateUnavailable =>
      'No pudimos estimar la comisión de red ahora. Intenta de nuevo en instantes.';

  @override
  String get withdrawUiSecurityTotpRequired =>
      'La transacción exige el código del autenticador y los factores de seguridad configurados en tu cuenta.';

  @override
  String get withdrawUiSecurityPasskeyRequired =>
      'La transacción exige confirmación por passkey antes del envío.';

  @override
  String get withdrawUiDetailNetwork => 'Red';

  @override
  String get withdrawUiDetailSourceWallet => 'Billetera de origen';

  @override
  String get withdrawUiDetailCard => 'Tarjeta';

  @override
  String get withdrawUiDetailType => 'Tipo';

  @override
  String get withdrawUiDetailExecution => 'Ejecución';

  @override
  String get withdrawUiLightningPayment => 'Pago Lightning';

  @override
  String get withdrawUiOnchainWithdrawal => 'Retiro on-chain';

  @override
  String get withdrawUiLightningLiquidityChecking =>
      'Liquidez Lightning en verificación';

  @override
  String get withdrawUiSecureWalletSignature => 'Firma segura de la billetera';

  @override
  String get withdrawUiAmountBtc => 'Valor en BTC';

  @override
  String withdrawUiPlatformFeeWithRate(String rate) {
    return 'Comisión Kerosene ($rate)';
  }

  @override
  String get withdrawUiRoutingFeeCap => 'Límite de enrutamiento';

  @override
  String get withdrawUiEstimatedNetworkFee => 'Comisión de red estimada';

  @override
  String get withdrawUiNetworkFeeRate => 'Comisión de red';

  @override
  String get withdrawUiTotalDebited => 'Total debitado';

  @override
  String get withdrawUiBalanceBefore => 'Saldo anterior';

  @override
  String get withdrawUiBalanceAfter => 'Saldo estimado después';

  @override
  String get withdrawUiFinalReview => 'Revisión final';

  @override
  String get withdrawUiSourceFrom => 'De';

  @override
  String get withdrawUiLightningReviewNotice =>
      'Revisa la solicitud Lightning y el límite de enrutamiento. El pago se enviará por la mejor ruta disponible.';

  @override
  String get withdrawUiOnchainReviewNotice =>
      'Revisa la dirección on-chain con atención. Después de transmitida, una transacción Bitcoin no se puede deshacer.';

  @override
  String get withdrawUiAuthIncomplete =>
      'La autenticación fue cancelada o quedó incompleta.';

  @override
  String get withdrawUiWalletLoadingSubtitle =>
      'Cargando billetera para iniciar el envío.';

  @override
  String get withdrawUiLightningSubtitle =>
      'Ingresa la solicitud Lightning, revisa el valor y confirma el pago.';

  @override
  String get withdrawUiOnchainSubtitle =>
      'Ingresa la dirección Bitcoin, revisa comisiones y confirma el retiro.';

  @override
  String get withdrawUiRecentLightning => 'Últimas solicitudes Lightning';

  @override
  String get withdrawUiRecentOnchain => 'Últimas direcciones';

  @override
  String get withdrawUiContinue => 'Continuar';

  @override
  String get withdrawUiTreasuryLiquidity => 'Liquidez Lightning';

  @override
  String get withdrawUiTreasuryUnavailable =>
      'No pudimos validar la liquidez en tiempo real en este intento. Intenta de nuevo en instantes.';

  @override
  String get withdrawUiTreasuryState => 'Estado';

  @override
  String get withdrawUiTreasuryAvailableLightning => 'Disponible LN';

  @override
  String get withdrawUiTreasuryOutbound => 'Salida disponible';

  @override
  String get withdrawUiTreasuryOnchainReserve => 'Reserva on-chain';

  @override
  String get withdrawUiFeeEstimating => 'Estimando...';

  @override
  String get withdrawUiUnavailable => 'Indisponible';

  @override
  String get withdrawUiFeeWaiting => 'Esperando comisión';

  @override
  String get withdrawUiSelectedNetwork => 'Red seleccionada';

  @override
  String get withdrawUiRoutingFeeMax => 'Comisión máxima de enrutamiento';

  @override
  String get withdrawUiFeeEstimateUnavailableLong =>
      'No pudimos estimar la comisión de red ahora. Revisa de nuevo en instantes antes de confirmar el envío.';

  @override
  String get withdrawUiEnterAmountForFees =>
      'Ingresa un valor para calcular el costo total antes de confirmar.';

  @override
  String withdrawUiEquivalentTo(String amount) {
    return 'Equivale a $amount';
  }

  @override
  String get withdrawUiColdWalletTitle => 'Billetera fría';

  @override
  String get withdrawUiColdWalletBody =>
      'Esta billetera fría se monitorea para recibir, pero las llaves de retiro permanecen fuera de Kerosene.';

  @override
  String get withdrawUiOperationalExecution => 'Ejecución operativa';

  @override
  String get withdrawUiOnchainOperationalBody =>
      'Los envíos on-chain se preparan para firma segura antes de enviarse a la red Bitcoin.';

  @override
  String get withdrawUiTreasuryLoadingBody =>
      'Cargando liquidez y reserva antes de liberar el pago Lightning.';

  @override
  String get withdrawUiDestinationEmptyOnchain =>
      'Ingresa una dirección Bitcoin on-chain o URI bitcoin: para continuar.';

  @override
  String get withdrawUiDestinationValidLightning =>
      'Solicitud Lightning o LNURL válida para este envío.';

  @override
  String get withdrawUiDestinationValidOnchain =>
      'Dirección on-chain válida para este envío.';

  @override
  String withdrawUiDestinationValidOnchainNetwork(String network) {
    return 'Dirección on-chain válida para $network.';
  }

  @override
  String get withdrawUiScreenTitleOnchain => 'Enviar on-chain';

  @override
  String get withdrawUiScreenTitleLightning => 'Enviar Lightning';

  @override
  String get withdrawUiLiquidityHealthy => 'Envíos Lightning disponibles';

  @override
  String get withdrawUiLiquidityRebalanceRequired =>
      'Ajuste de liquidez recomendado';

  @override
  String get withdrawUiLiquidityBlocked => 'Envíos Lightning pausados';

  @override
  String get withdrawUiLiquidityUnknown => 'Estado operativo indisponible';

  @override
  String get withdrawUiLiquidityHealthyMessage =>
      'La reserva Bitcoin cubre la liquidez Lightning disponible para envío.';

  @override
  String get withdrawUiLiquidityRebalanceMessage =>
      'La reserva está adecuada, pero la liquidez Lightning necesita ajuste antes de envíos mayores.';

  @override
  String get withdrawUiLiquidityBlockedMessage =>
      'Los pagos Lightning fueron pausados hasta que la reserva vuelva al nivel necesario.';

  @override
  String get withdrawUiLiquidityUnknownMessage =>
      'No podemos clasificar la liquidez ahora. Revisa los valores antes de continuar.';

  @override
  String get withdrawUiDestinationHintOnchain => 'Pega la dirección Bitcoin';

  @override
  String get withdrawUiDestinationHintLightning =>
      'Pega la solicitud Lightning o LNURL';

  @override
  String get withdrawUiPasteAction => 'Pegar';

  @override
  String get withdrawUiScanQrTooltip => 'Escanear QR';

  @override
  String get withdrawUiExternalDestinationInstructionLightning =>
      'Ingresa una factura Lightning, LNURL o dirección Lightning para iniciar la transferencia.';

  @override
  String get withdrawUiExternalDestinationInstructionOnchain =>
      'Ingresa la dirección Bitcoin de destino para iniciar la transferencia.';

  @override
  String get withdrawUiExternalDestinationHintLightning => 'lnbc...';

  @override
  String get withdrawUiExternalDestinationHintOnchain => 'bc1...';

  @override
  String get withdrawUiDestinationFallback => 'Destino';

  @override
  String get withdrawUiEstimatedSeconds => 'Segundos';

  @override
  String get withdrawUiEstimatedTenMinutes => '~10 min';

  @override
  String get withdrawUiReviewPaymentTitle => 'Revisar pago';

  @override
  String get withdrawUiReviewSendTitle => 'Revisar envío';

  @override
  String get withdrawUiReviewDetailsSubtitle =>
      'Verifica los detalles antes de confirmar.';

  @override
  String get withdrawUiAmountToSendLabel => 'VALOR A ENVIAR';

  @override
  String get withdrawUiReviewInvoiceDestination => 'Para (Invoice)';

  @override
  String get withdrawUiReviewAddressDestination => 'Para (Dirección)';

  @override
  String get withdrawUiLightningFee => 'Comisión Lightning';

  @override
  String get withdrawUiPlatformFee => 'Comisión Kerosene';

  @override
  String get withdrawUiConfirmPayment => 'Confirmar pago';

  @override
  String get withdrawUiConfirmSend => 'Confirmar envío';

  @override
  String get withdrawUiSendingFromPrefix => 'Enviando desde:';

  @override
  String get withdrawUiSendingToPrefix => 'a:';

  @override
  String get withdrawUiCurrentBalance => 'Saldo actual';

  @override
  String get withdrawUiEstimatedTime => 'Tiempo estimado';

  @override
  String get withdrawUiCalculating => 'Calculando';

  @override
  String get depositLedgerAddressCopied => 'Dirección copiada.';

  @override
  String get depositLedgerMovementsTitle => 'Movimientos';

  @override
  String depositLedgerPage(int page) {
    return 'Página $page';
  }

  @override
  String get depositLedgerBackTooltip => 'Volver';

  @override
  String get depositLedgerRefreshTooltip => 'Actualizar';

  @override
  String get depositLedgerStatementTitle => 'Extracto';

  @override
  String get depositLedgerAccountSubtitle => 'Movimiento de la cuenta';

  @override
  String get depositLedgerBalance => 'Saldo';

  @override
  String get depositLedgerHideBalance => 'Ocultar saldo';

  @override
  String get depositLedgerShowBalance => 'Mostrar saldo';

  @override
  String get depositLedgerItems => 'Ítems';

  @override
  String get depositLedgerPending => 'Pendientes';

  @override
  String get depositLedgerOpenCharges => 'Cobros';

  @override
  String get depositLedgerNetwork => 'Red';

  @override
  String get depositLedgerActive => 'Activa';

  @override
  String get depositLedgerManual => 'Manual';

  @override
  String get depositLedgerCopyAddress => 'Copiar dirección';

  @override
  String get depositLedgerLoadingCharges => 'Cargando cobros';

  @override
  String get depositLedgerOpenChargesTitle => 'Cobros abiertos';

  @override
  String get depositLedgerPaymentLinkTitle => 'Link de pago';

  @override
  String depositLedgerExpiresIn(String time) {
    return 'Expira $time';
  }

  @override
  String get depositLedgerNow => 'Ahora';

  @override
  String get depositLedgerCopyAction => 'copiar';

  @override
  String get depositLedgerManageAction => 'gestionar';

  @override
  String get depositLedgerUpdating => 'Actualizando extracto';

  @override
  String get depositLedgerEmptyTitle => 'Sin movimientos';

  @override
  String get depositLedgerEmptyMessage => 'Nada en esta página.';

  @override
  String get depositLedgerCancelReceive => 'Cancelar recepción';

  @override
  String get depositLedgerCancelReceiveMessage =>
      'Esta recepción será cancelada en Kerosene. Si alguien ya envió BTC a la dirección, la red Bitcoin aún puede confirmar la transacción.';

  @override
  String get depositLedgerBackAction => 'Volver';

  @override
  String get depositLedgerReceiveCanceled => 'Recepción cancelada.';

  @override
  String get depositLedgerPreviousTooltip => 'Anterior';

  @override
  String get depositLedgerNextTooltip => 'Siguiente';

  @override
  String get depositLedgerAlerts => 'Alertas';

  @override
  String get depositLedgerUpdateAction => 'Actualizar';

  @override
  String get depositLedgerErrorTitle => 'No pudimos actualizar';

  @override
  String depositLedgerPageShort(int page) {
    return 'Pág. $page';
  }

  @override
  String depositLedgerRowsPerPage(int count) {
    return '$count por página';
  }

  @override
  String get depositLedgerNoCounterparty => 'Sin contraparte';

  @override
  String get depositLedgerStatusCompleted => 'Concluido';

  @override
  String get depositLedgerStatusConfirming => 'Confirmando';

  @override
  String get depositLedgerStatusPending => 'Pendiente';

  @override
  String get depositLedgerStatusFailed => 'Falló';

  @override
  String get depositLedgerStatusVerifying => 'Verificando';

  @override
  String get depositLedgerStatusPaid => 'Pagado';

  @override
  String get depositLedgerStatusExpired => 'Expirado';

  @override
  String get depositLedgerRelativeSoon => 'en instantes';

  @override
  String depositLedgerRelativeInMinutes(int count) {
    return 'en $count min';
  }

  @override
  String depositLedgerRelativeInHours(int count) {
    return 'en $count h';
  }

  @override
  String depositLedgerRelativeInDays(int count) {
    return 'en $count d';
  }

  @override
  String get depositLedgerRelativeNow => 'ahora';

  @override
  String depositLedgerRelativeMinutesAgo(int count) {
    return 'hace $count min';
  }

  @override
  String depositLedgerRelativeHoursAgo(int count) {
    return 'hace $count h';
  }

  @override
  String get paymentConfirmationErrorTitle => 'No pudimos confirmar';

  @override
  String get paymentConfirmationReviewSubtitle =>
      'Revisa los datos y confirma con tus factores de seguridad.';

  @override
  String get paymentConfirmationDateTime => 'Fecha y hora';

  @override
  String get paymentConfirmationNetwork => 'Red';

  @override
  String get paymentConfirmationCopyAction => 'Copiar';

  @override
  String paymentConfirmationCopied(String label) {
    return '$label copiado.';
  }

  @override
  String get depositFlowDepositTitle => 'Depositar';

  @override
  String get depositFlowAmountSubtitle =>
      'Ingresa el valor y elige cómo deseas recibir.';

  @override
  String get depositFlowSelectedCurrency => 'Moneda seleccionada';

  @override
  String get depositFlowAmountLabel => 'Valor del depósito';

  @override
  String get depositFlowContinue => 'Continuar';

  @override
  String depositFlowEquivalentTo(String amount) {
    return 'Equivale a $amount';
  }

  @override
  String depositFlowYouReceive(String amount) {
    return 'Recibes $amount';
  }

  @override
  String get depositFlowMethodTitle => 'Método de depósito';

  @override
  String get depositFlowMethodSubtitle =>
      'Elige cómo deseas recibir este valor en Bitcoin.';

  @override
  String get depositFlowSelectedAmount => 'Valor elegido';

  @override
  String get depositFlowChooseOption => 'Elige una opción';

  @override
  String get depositFlowLightningFastSubtitle =>
      'Recepción rápida con validez corta y copia en un toque.';

  @override
  String get depositFlowLightningUnavailable =>
      'Lightning no está disponible para esta billetera en este momento.';

  @override
  String get depositFlowLightningChecking =>
      'Verificando disponibilidad para esta billetera.';

  @override
  String get depositFlowLightningCheckError =>
      'No pudimos verificar Lightning ahora. Aún puedes usar on-chain.';

  @override
  String get depositFlowLightningInstant => 'Instantáneo';

  @override
  String get depositFlowUnavailable => 'Indisponible';

  @override
  String get depositFlowValidating => 'Validando';

  @override
  String get depositFlowOnchainColdTitle =>
      'Bitcoin on-chain de la billetera fría';

  @override
  String get depositFlowOnchainTitle => 'Bitcoin on-chain';

  @override
  String get depositFlowOnchainColdSubtitle =>
      'Dirección de tu billetera fría para acompañar el depósito con seguridad.';

  @override
  String get depositFlowOnchainSubtitle =>
      'Dirección Bitcoin exclusiva acompañada hasta la confirmación.';

  @override
  String get depositFlowColdWalletTag => 'Billetera fría';

  @override
  String get depositFlowConfirmationsTag => '3 confirmaciones';

  @override
  String get depositFlowProviderTitle => 'Proveedor de compra';

  @override
  String get depositFlowProviderSubtitle =>
      'Selecciona el checkout para comprar Bitcoin con seguridad.';

  @override
  String get depositFlowRequestedPurchase => 'Compra solicitada';

  @override
  String get depositFlowProviderSecurityHint =>
      'Continuarás en un entorno seguro y la dirección Bitcoin ya estará completada para este pago.';

  @override
  String get depositFlowProvidersLoadingTitle => 'Cargando proveedores';

  @override
  String get depositFlowProvidersLoadingMessage =>
      'Preparando opciones de compra con la dirección de esta billetera.';

  @override
  String get depositFlowProvidersErrorTitle => 'No pudimos cargar proveedores';

  @override
  String get depositFlowUnknownError => 'No pudimos completar esto ahora.';

  @override
  String get depositFlowRetry => 'Intentar de nuevo';

  @override
  String get depositFlowNoProvidersTitle => 'Ningún proveedor disponible';

  @override
  String get depositFlowNoProvidersMessage =>
      'No encontramos opciones de compra disponibles en este momento.';

  @override
  String get depositFlowSecureAddress => 'Dirección segura';

  @override
  String get depositFlowCheckoutSubtitle => 'Checkout seguro en el app.';

  @override
  String get depositFlowDepositAddressCopied =>
      'Dirección de depósito copiada.';

  @override
  String depositFlowEstimatedPurchase(String amount) {
    return 'Compra estimada en $amount';
  }

  @override
  String get depositFlowProviderLoadError => 'No pudimos cargar el proveedor';

  @override
  String get depositFlowCheckoutAddressTitle =>
      'Dirección BTC vinculada al checkout';

  @override
  String get depositFlowAddressUnavailable => 'Dirección indisponible';

  @override
  String get depositFlowCopy => 'Copiar';

  @override
  String get depositLightningLoading => 'Cargando';

  @override
  String get depositLightningGoesTo => 'Llegará a';

  @override
  String get depositLightningSummary => 'Resumen';

  @override
  String get depositInstructionsTitle => 'Instrucciones de depósito';

  @override
  String get depositInstructionsSubtitle =>
      'Lectura corta y directa, en el mismo patrón del flujo.';

  @override
  String get depositInstructionsUnderstood => 'Entendido';

  @override
  String get depositInstructionsNetworkLabel => 'Red';

  @override
  String get depositInstructionsNetworkTitle => 'Deposita BTC solo vía';

  @override
  String get depositInstructionsMinimumLabel => 'Mínimo';

  @override
  String get depositInstructionsMinimumTitle => 'El depósito mínimo es de';

  @override
  String get depositInstructionsMinimumNote =>
      'Depósitos por debajo de este valor se perderán.';

  @override
  String get depositInstructionsMaximumLabel => 'Máximo';

  @override
  String get depositInstructionsMaximumTitle => 'El depósito máximo es de';

  @override
  String get depositInstructionsMaximumSuffix => ' por transacción.';

  @override
  String get depositInstructionsProcessingLabel => 'Procesamiento';

  @override
  String get depositInstructionsProcessingTitle => 'Tiempo estimado:';

  @override
  String get depositInstructionsProcessingHighlight => '< 1 minuto';

  @override
  String get depositInstructionsProcessingSuffix => ' vía Lightning.';

  @override
  String get depositQrReceiveTitle => 'Recibir BTC';

  @override
  String get depositQrReceiveSubtitle => 'QR de depósito simple y seguro.';

  @override
  String get depositQrSetAmount => 'Definir valor';

  @override
  String get depositQrScanTitle => 'Escanea para recibir Bitcoin';

  @override
  String get depositQrBitcoinOnlyWarning =>
      'Envía solo Bitcoin (BTC) a esta dirección.\nEnviar otros activos resultará en pérdida permanente.';

  @override
  String get depositQrAddressLabel => 'Tu dirección BTC';

  @override
  String get depositQrCopy => 'Copiar';

  @override
  String get depositQrCopied => 'Dirección copiada.';

  @override
  String get depositQrShare => 'Compartir';

  @override
  String get depositQrSave => 'Guardar QR';

  @override
  String get receiveQrTitle => 'Recibir por QR';

  @override
  String get receiveQrSubtitle => 'QR compacto y monocromático para mostrar.';

  @override
  String get receiveQrCopied => 'Copiado al portapapeles';

  @override
  String get withdrawReceiptSubtitle =>
      'Comprobante con valor, destino e identificador del envío.';

  @override
  String get receiveHubNfcUnavailable =>
      'NFC no está disponible en este dispositivo en este momento.';

  @override
  String get receiveHubTitle => 'Recibir';

  @override
  String get receiveHubSubtitle => 'Depósito, cobro y QR en un flujo simple.';

  @override
  String get receiveHubActions => 'Acciones disponibles';

  @override
  String get receiveHubIntro =>
      'Elige cómo deseas recibir. Cada opción mantiene el foco en el valor, el destino y la confirmación.';

  @override
  String get receiveHubDeposit => 'Depositar';

  @override
  String get receiveHubDepositSubtitle =>
      'Agregar saldo por compra, Lightning u on-chain';

  @override
  String get receiveHubOnchain => 'Recibir on-chain';

  @override
  String get receiveHubOnchainSubtitle =>
      'Generar QR Bitcoin con valor opcional';

  @override
  String get receiveHubLightning => 'Recibir Lightning';

  @override
  String get receiveHubLightningSubtitle =>
      'Crear solicitud instantánea para la billetera';

  @override
  String get receiveHubPaymentLink => 'Link de pago';

  @override
  String get receiveHubPaymentLinkSubtitle =>
      'Cobro acompañado con destino protegido';

  @override
  String get receiveHubNfc => 'Recibir por NFC';

  @override
  String get receiveHubNfcSubtitle => 'Preparar cobro por aproximación';

  @override
  String get receiveHubNoWalletTitle => 'Ninguna billetera disponible';

  @override
  String get receiveHubNoWalletMessage =>
      'Crea o selecciona una billetera antes de iniciar una recepción.';

  @override
  String get receiveWalletInternalUnavailable =>
      'No hay una billetera interna Kerosene disponible para recibir.';

  @override
  String get receiveWalletOnchainUnavailable =>
      'No hay una billetera fría on-chain disponible para recibir.';

  @override
  String get receiveWalletSelectionTitle => '¿Dónde quieres\nrecibir?';

  @override
  String get receiveWalletSelectionSubtitle =>
      'Elige si los fondos entran en la billetera interna Kerosene o en tu billetera fría on-chain.';

  @override
  String get receiveWalletKeroseneTitle => 'Billetera principal';

  @override
  String get receiveWalletKeroseneSubtitle =>
      'Recibe directamente en tu billetera en Kerosene';

  @override
  String get receiveWalletOnchainTitle => 'Billetera de casa';

  @override
  String get receiveWalletOnchainSubtitle =>
      'Recibe directo en la dirección Bitcoin de tu billetera de casa';

  @override
  String get receiveMethodKeroseneTitle => 'Recibir en Kerosene';

  @override
  String get receiveMethodKeroseneSubtitle =>
      'Elige QR Code, link de pago o NFC para tu billetera interna.';

  @override
  String get receiveMethodOnchainTitle => 'Recibir on-chain';

  @override
  String get receiveMethodOnchainSubtitle =>
      'Elige QR Code, link de pago o NFC para tu billetera fría.';

  @override
  String get receiveMethodGatewayTitle => 'Gateway de pago';

  @override
  String get receiveMethodGatewaySubtitle =>
      'Elegir un proveedor para comprar Bitcoin';

  @override
  String get receiveMethodQrTitle => 'QR Code';

  @override
  String get receiveMethodQrSubtitle =>
      'Generar un código para mostrar al pagador';

  @override
  String get receiveMethodPaymentLinkTitle => 'Link de pago';

  @override
  String get receiveMethodPaymentLinkSubtitle => 'Crear un cobro compartible';

  @override
  String get receiveMethodNfcTitle => 'NFC';

  @override
  String get receiveMethodNfcSubtitle => 'Preparar recepción por aproximación';

  @override
  String get receiveGatewayProvidersTitle => 'Proveedores';

  @override
  String get receiveGatewayRecommendedBrazil => 'Recomendados para Brasil';

  @override
  String get receiveGatewayInstitutional => 'Institucionales';

  @override
  String get receiveGatewayAggregators => 'Agregadores';

  @override
  String get receiveGatewayOther => 'Otros';

  @override
  String get receiveGatewayInstitutionalBadge => 'INSTITUCIONAL';

  @override
  String get receiveGatewayMoonPayMethods =>
      'Pix, tarjeta, Apple Pay • Instantáneo';

  @override
  String get receiveGatewayMoonPayFees => 'Comisiones: 1% a 4,5%';

  @override
  String get receiveGatewayBanxaMethods =>
      'Tarjeta, Apple Pay, Google Pay • Instantáneo';

  @override
  String get receiveGatewayBanxaFees => 'Comisión: 1,99% + network fee';

  @override
  String get receiveGatewayMercuryoMethods =>
      'Pix, tarjeta, Apple Pay • Minutos';

  @override
  String get receiveGatewayMercuryoFees => 'Comisión: 3,95% a 4%';

  @override
  String get receiveGatewayRampMethods =>
      'Tarjeta, Apple Pay, transferencia • Minutos';

  @override
  String get receiveGatewayRampFees => 'Comisiones dinámicas en checkout';

  @override
  String get receiveGatewayStripeMethods =>
      'Tarjeta, Apple Pay, ACH • 1 a 5 min';

  @override
  String get receiveGatewayStripeFees => 'Comisiones dinámicas';

  @override
  String get receiveGatewayCoinbaseMethods =>
      'Tarjeta de débito/crédito • Minutos';

  @override
  String get receiveGatewayCoinbaseFees => 'Comisiones dinámicas';

  @override
  String get receiveGatewayOnramperMethods =>
      'Más de 130 métodos y 30 proveedores';

  @override
  String get receiveGatewayOnramperFees =>
      'Mejor ruta disponible • Fallback ideal';

  @override
  String get receiveGatewayTransakMethods =>
      'Tarjeta, billeteras digitales • Minutos';

  @override
  String get receiveGatewayTransakFees =>
      'Límites y comisiones variables por cobertura';

  @override
  String get receiveGatewayWertMethods =>
      'Tarjeta, Apple Pay, Google Pay • < 60 seg';

  @override
  String get receiveGatewayWertFees => 'Mínimo de US\$30 para BTC';

  @override
  String get receiveGatewayGateFiMethods =>
      'E-wallets, QR Code, cash • Variable';

  @override
  String get receiveGatewayGateFiFees => 'Amplia cobertura global';

  @override
  String get receiveGatewayComingSoon => 'Próximamente';

  @override
  String receiveGatewayLinkCopied(String provider, String wallet) {
    return 'Link de $provider copiado para $wallet.';
  }

  @override
  String receiveGatewayProviderUnavailable(String provider) {
    return '$provider aún no está disponible para esta billetera.';
  }

  @override
  String get financialStatementTitle => 'Transacciones';

  @override
  String get financialStatementLoadErrorTitle => 'No se pudo cargar';

  @override
  String get financialStatementEmptyTitle => 'Sin transacciones';

  @override
  String get financialStatementEmptyMessage =>
      'Los movimientos de la cuenta aparecerán aquí.';

  @override
  String get financialStatementSearchHint => 'Buscar';

  @override
  String get financialStatementFilterAll => 'Todas';

  @override
  String get financialStatementFilterIncoming => 'Recibidas';

  @override
  String get financialStatementFilterOutgoing => 'Enviadas';

  @override
  String get financialStatementFilterPending => 'Pendientes';

  @override
  String get financialStatementFilterFailed => 'Fallidas';

  @override
  String get financialStatementNoResultsTitle =>
      'No se encontraron transacciones';

  @override
  String get financialStatementNoResultsMessage =>
      'Prueba otra búsqueda o borra los filtros.';

  @override
  String get financialStatementClearFilters => 'Borrar filtros';

  @override
  String get financialStatementReportTitle => 'Reporte de movimientos';

  @override
  String get financialStatementMovementVolume => 'Volumen de movimientos';

  @override
  String get financialStatementFundDistribution => 'Distribución de fondos';

  @override
  String get financialStatementMonthlyMovement => 'Movimiento mensual';

  @override
  String get financialStatementOutflows => 'Salidas';

  @override
  String get financialStatementInflows => 'Entradas';

  @override
  String get financialStatementPeriodTooltip => 'Periodo';

  @override
  String get financialStatementPeriodLastSixMonths => 'Últimos 6 meses';

  @override
  String get financialStatementPeriodYearToDate => 'Año actual';

  @override
  String get financialStatementPeriodOneYear => '1 año';

  @override
  String get financialStatementPeriodMonthly => 'Mensual';

  @override
  String get financialStatementPeriodWeekly => 'Semanal';

  @override
  String get financialStatementPeriodAnnual => 'Anual';

  @override
  String get receiveScreenQrEyebrow => 'QR Code';

  @override
  String get receiveScreenPaymentLinkEyebrow => 'Link de pago';

  @override
  String get receiveScreenOnchainEyebrow => 'On-chain';

  @override
  String get receiveScreenLightningEyebrow => 'Lightning';

  @override
  String get receiveScreenQrDescription =>
      'Genera un QR interno con valor y destino protegidos para confirmación.';

  @override
  String get receiveScreenNfcDescription =>
      'Prepara un cobro por aproximación con destino protegido.';

  @override
  String get receiveScreenPaymentLinkDescription =>
      'Crea un link acompañado que abre directo en la confirmación.';

  @override
  String get receiveScreenOnchainDescription =>
      'Genera un QR Bitcoin on-chain con valor y destino definidos.';

  @override
  String get receiveScreenLightningDescription =>
      'Genera una solicitud Lightning para recepción rápida.';

  @override
  String get receiveScreenGenerateQr => 'Generar QR';

  @override
  String get receiveScreenPrepareNfc => 'Preparar NFC';

  @override
  String get receiveScreenCreateLink => 'Crear link';

  @override
  String get receiveScreenGenerateOnchainQr => 'Generar QR on-chain';

  @override
  String get receiveScreenGenerateLightningInvoice =>
      'Generar invoice Lightning';

  @override
  String get receiveScreenSelectDepositWallet =>
      'Selecciona una billetera para depositar.';

  @override
  String get receiveScreenQrSubtitle =>
      'Define el valor y genera un QR interno con destino protegido.';

  @override
  String get receiveScreenNfcSubtitle =>
      'Define el valor y prepara un cobro por aproximación.';

  @override
  String get receiveScreenPaymentLinkSubtitle =>
      'Define el valor y genera un cobro acompañado.';

  @override
  String get receiveScreenOnchainSubtitle =>
      'Define el valor y genera un QR Bitcoin compatible.';

  @override
  String get receiveScreenLightningSubtitle =>
      'Define el valor y continúa hacia una solicitud Lightning.';

  @override
  String get receiveScreenInboundBlockedTitle => 'Recepción no disponible';

  @override
  String get receiveScreenInboundBlockedMessage =>
      'Activa una billetera o agrega saldo para recibir por la plataforma.';

  @override
  String get receiveScreenRefreshStatus => 'Actualizar estado';

  @override
  String receiveScreenEquivalentTo(String amount) {
    return 'Equivale a $amount';
  }

  @override
  String receiveScreenDestination(String walletName) {
    return 'Destino $walletName';
  }

  @override
  String get receiveScreenPrivacyHint =>
      'Quien pague verá solo los datos necesarios para confirmar la recepción.';

  @override
  String get receiveScreenSelectReceiveWallet =>
      'Selecciona una billetera para recibir.';

  @override
  String get receiveScreenInvalidPaymentLink =>
      'No pudimos crear un link de pago válido ahora.';

  @override
  String receiveScreenPaymentLinkError(String error) {
    return 'No fue posible generar el link de pago: $error';
  }

  @override
  String receiveScreenDefaultDescription(String walletName) {
    return 'Recepción $walletName';
  }

  @override
  String get receiveScreenConfigureLinkEyebrow => 'Configurar link';

  @override
  String get receiveScreenConfigureLinkTitle => 'Link de pago';

  @override
  String get receiveScreenConfigureLinkSubtitle =>
      'Define validez, visibilidad e identificación antes de generar el link.';

  @override
  String get receiveScreenDescriptionLabel => 'Descripción';

  @override
  String get receiveScreenReferenceLabel => 'Referencia';

  @override
  String get receiveScreen15Minutes => '15 minutos';

  @override
  String get receiveScreen1Hour => '1 hora';

  @override
  String get receiveScreen3Hours => '3 horas';

  @override
  String get receiveScreen24Hours => '24 horas';

  @override
  String get receiveScreenValidityLabel => 'Validez';

  @override
  String get receiveScreenPrivate => 'Privado';

  @override
  String get receiveScreenPublic => 'Público';

  @override
  String get receiveScreenVisibilityLabel => 'Visibilidad';

  @override
  String get receiveScreenUserActionRequired => 'Concluir con tu confirmación';

  @override
  String get receiveScreenAutoComplete => 'Completar automáticamente';

  @override
  String get receiveScreenCompletionLabel => 'Cierre';

  @override
  String get receiveScreenCustomerLabel => 'Cliente';

  @override
  String get receiveScreenNoteLabel => 'Nota';

  @override
  String get receiveScreenGenerateLink => 'Generar link';

  @override
  String get receivePaymentLinkCancelled => 'Link de pago cancelado.';

  @override
  String get receivePaymentLinkCancelTitle => 'Cancelar link';

  @override
  String get receivePaymentLinkCancelMessage =>
      'Si quieres, informa un motivo para mostrarlo en tu historial.';

  @override
  String get receivePaymentLinkCancelReason => 'Motivo de cancelación';

  @override
  String get receivePaymentLinkConfirmCancel => 'Confirmar cancelación';

  @override
  String get receivePaymentLinkNotInformed => 'No informado';

  @override
  String get receivePaymentLinkStatusChecking => 'Pago en revisión';

  @override
  String get receivePaymentLinkStatusReceived => 'Pago recibido';

  @override
  String get receivePaymentLinkStatusCancelled => 'Link cancelado';

  @override
  String get receivePaymentLinkStatusExpired => 'Link expirado';

  @override
  String get receivePaymentLinkStatusWaiting => 'Esperando pago';

  @override
  String get receivePaymentLinkCheckingMessage =>
      'La red ya identificó el pago. Estamos completando la revisión final.';

  @override
  String get receivePaymentLinkReceivedMessage =>
      'El valor de este link ya fue recibido y el historial fue actualizado.';

  @override
  String receivePaymentLinkCancelledReason(String reason) {
    return 'Este link fue cancelado: $reason.';
  }

  @override
  String get receivePaymentLinkCancelledMessage =>
      'Este link fue cancelado y ya no acepta pagos.';

  @override
  String get receivePaymentLinkExpiredMessage =>
      'Este link ya no acepta pagos. Genera un nuevo QR para seguir recibiendo.';

  @override
  String get receivePaymentLinkLockedMessage =>
      'Quien abra este QR verá una confirmación simple, con valor y destino protegidos.';

  @override
  String get receivePaymentLinkWaitingMessage =>
      'Usa el QR Code o copia el link de pago abajo. El estado se actualizará automáticamente.';

  @override
  String get receivePaymentLinkTitle => 'Recepción';

  @override
  String get receivePaymentLinkSubtitle =>
      'QR, link y seguimiento en una pantalla simple.';

  @override
  String get receivePaymentLinkExpired => 'Expirado';

  @override
  String receivePaymentLinkExpiresIn(String duration) {
    return 'Expira en $duration';
  }

  @override
  String receivePaymentLinkDepositFee(String amount) {
    return 'depósito $amount';
  }

  @override
  String receivePaymentLinkNetAmount(String amount) {
    return 'neto $amount';
  }

  @override
  String get receivePaymentLinkExpires => 'Expira';

  @override
  String get receivePaymentLinkTransactionCode => 'Código de transacción';

  @override
  String get receivePaymentLinkState => 'Estado';

  @override
  String get receivePaymentLinkPaymentLinkTitle => 'Link de pago';

  @override
  String get receivePaymentLinkLockedHelper =>
      'Este link abre la confirmación del pago con valor y destino protegidos.';

  @override
  String get receivePaymentLinkShareHelper =>
      'Comparte este link para recibir el valor definido.';

  @override
  String get receivePaymentLinkCopied =>
      'Link de pago copiado al portapapeles.';

  @override
  String get receivePaymentLinkDepositAddressHelper =>
      'Dirección Bitcoin exclusiva para este pago.';

  @override
  String get receivePaymentLinkDepositAddressCopied =>
      'Dirección de depósito copiada al portapapeles.';

  @override
  String get receivePaymentLinkRefresh => 'Actualizar';

  @override
  String get receivePaymentLinkConfigurationTitle =>
      'Configuración de recepción';

  @override
  String get receivePaymentLinkVisibility => 'Visibilidad';

  @override
  String get receivePaymentLinkCompletion => 'Cierre';

  @override
  String get receivePaymentLinkAmount => 'Valor';

  @override
  String get receivePaymentLinkAmountSet => 'Definido';

  @override
  String get receivePaymentLinkAmountFlexible => 'Flexible';

  @override
  String get receivePaymentLinkReference => 'Referencia';

  @override
  String get receivePaymentLinkCreatedAt => 'Creado en';

  @override
  String get receivePaymentLinkPaidAt => 'Pagado en';

  @override
  String get receivePaymentLinkConfirmedAt => 'Confirmado en';

  @override
  String get receivePaymentLinkCancelledAt => 'Cancelado en';

  @override
  String get receivePaymentLinkCopy => 'Copiar';

  @override
  String get sendMoneyDestinationLabel => 'Destino';

  @override
  String get sendMoneyDestinationHint => 'Dirección o nombre de usuario';

  @override
  String get sendMoneyRecentTitle => 'Ya enviados';

  @override
  String get recentDestinationInternal => 'Transferencia interna';

  @override
  String get recentDestinationOnChain => 'Dirección on-chain';

  @override
  String get recentDestinationLightning => 'Invoice Lightning';

  @override
  String get recentDestinationClearAll => 'Borrar todo';

  @override
  String get sendMoneyGoToAmount => 'Ir al valor';

  @override
  String get sendMoneyMissingDestination =>
      'Informa la dirección o el usuario.';

  @override
  String get sendMoneyExternalUseWithdraw =>
      'Pagos on-chain deben usar el flujo de retiro.';

  @override
  String get sendMoneyReview => 'Revisar';

  @override
  String get sendMoneyDetailType => 'Tipo';

  @override
  String get sendMoneyTypePaymentLink => 'Pago por link interno';

  @override
  String get sendMoneyTypeInternalTransfer => 'Transferencia interna Kerosene';

  @override
  String get sendMoneyDetailValue => 'Valor';

  @override
  String get sendMoneyDetailValueBtc => 'Valor en BTC';

  @override
  String get sendMoneyDetailTotalBtc => 'Total en BTC';

  @override
  String get sendMoneyDetailBalanceBefore => 'Saldo antes del envío';

  @override
  String get sendMoneyDetailLinkId => 'ID del link';

  @override
  String get sendMoneyDetailDestinationHash => 'Hash del destino';

  @override
  String get sendMoneyDestinationHashCopied => 'Hash del destino copiado.';

  @override
  String get sendMoneyConfirmPayment => 'Confirmar pago';

  @override
  String get sendMoneyLockedRequestEyebrow => 'Pedido protegido';

  @override
  String get sendMoneyFinalReviewEyebrow => 'Revisión final';

  @override
  String get sendMoneySourceLabel => 'De';

  @override
  String get sendMoneyDestinationToLabel => 'Para';

  @override
  String get sendMoneyInternalNetwork => 'Interno';

  @override
  String get sendMoneyLockedNotice =>
      'Valor y destino fueron definidos por el link. Confirma solo si reconoces este pedido.';

  @override
  String get sendMoneyReviewNotice =>
      'Revisa los datos antes de confirmar. Después de la autorización, el envío será procesado.';

  @override
  String get sendMoneySecurityMessage =>
      'La confirmación usa tu sesión actual y los factores de seguridad configurados en tu cuenta antes de enviar el pago.';

  @override
  String get sendMoneyAuthFailed =>
      'La autenticación fue cancelada o no pudo completarse.';

  @override
  String get sendMoneyInvalidPaymentRequest => 'Solicitud de pago inválida.';

  @override
  String get sendMoneyExternalQrUseWithdraw =>
      'QR externo detectado. Usa el flujo de retiro para pagos on-chain.';

  @override
  String get sendMoneyRequestDataLoaded => 'Datos de la solicitud cargados.';

  @override
  String get sendMoneyInvalidQrRequest =>
      'Este QR o NFC no parece una solicitud válida.';

  @override
  String get sendMoneyRequestAlreadyPaid => 'Esta solicitud ya fue pagada.';

  @override
  String get sendMoneyRequestExpired => 'Esta solicitud de pago expiró.';

  @override
  String get sendMoneyLockedDestination => 'Destino protegido';

  @override
  String get sendMoneyPaymentRequestLoaded => 'Solicitud de pago cargada.';

  @override
  String get authReasonTransactionConfirm =>
      'Confirma en este dispositivo para autorizar la transacción.';

  @override
  String get transactionAuthVaultTitle => 'Confirmación de la bóveda';

  @override
  String get transactionAuthOperationTitle => 'Confirmación de la operación';

  @override
  String get transactionAuthPassphraseLabel => 'Passphrase';

  @override
  String get transactionAuthConfirmationPassphraseLabel =>
      'Passphrase de confirmación';

  @override
  String get transactionAuthEnterPassphrase =>
      'Ingresa tu passphrase para continuar.';

  @override
  String get transactionAuthTotpCodeLabel => 'Código TOTP';

  @override
  String get transactionAuthEnterAuthenticatorDigits =>
      'Ingresa los 6 dígitos del autenticador.';

  @override
  String get transactionAuthContinue => 'Continuar';

  @override
  String get transactionAuthProfileSubtitleMultisigFull =>
      'Esta política usa passphrase, TOTP y passkey para liberar operaciones críticas.';

  @override
  String get transactionAuthProfileSubtitleMultisigStandard =>
      'Esta política usa passphrase y TOTP para liberar operaciones críticas.';

  @override
  String get transactionAuthProfileSubtitlePasskeyOnly =>
      'La confirmación final se solicitará con tu passkey.';

  @override
  String get transactionAuthProfileSubtitleDefault =>
      'Confirma los factores necesarios para completar esta operación.';

  @override
  String transactionAuthShamirRecoveryError(int threshold) {
    return 'Ingresa $threshold shares completas para reconstruir la passphrase.';
  }

  @override
  String get transactionAuthShamirReconstructFailed =>
      'No fue posible reconstruir la passphrase. Revisa las shares e intenta de nuevo.';

  @override
  String get transactionAuthShamirTitle => 'Autorización Shamir';

  @override
  String transactionAuthShamirSubtitle(int threshold, int totalShares) {
    return 'Reconstruye la passphrase con $threshold de $totalShares shares antes de liberar la operación.';
  }

  @override
  String transactionAuthShareLabel(int index) {
    return 'Share $index';
  }

  @override
  String get transactionAuthReconstructAndContinue => 'Reconstruir y continuar';

  @override
  String get transactionAuthShareHint => 'Pega la share completa aquí';

  @override
  String get walletConfigAddressCopiedMessage =>
      'La dirección de la billetera fue copiada con éxito.';

  @override
  String get walletConfigAddressCopiedTitle => 'Dirección copiada';

  @override
  String get walletConfigExportNoticeMessage =>
      'La exportación de la clave privada depende de la verificación de seguridad del dispositivo.';

  @override
  String get walletConfigExportNoticeTitle => 'Validación necesaria';

  @override
  String get walletConfigAddressTitle => 'Dirección de la billetera';

  @override
  String get walletConfigAddressSubtitle =>
      'Usa esta dirección para depósitos on-chain de esta billetera.';

  @override
  String get walletConfigCopy => 'Copiar';

  @override
  String get walletConfigFeesTitle => 'Tasas de la billetera';

  @override
  String get walletConfigFeesSubtitle =>
      'Valores actualizados para movimientos externos de esta billetera.';

  @override
  String get walletConfigControlsTitle => 'Controles';

  @override
  String get walletConfigControlsSubtitle =>
      'Ajustes de uso y protección visual de la billetera en el app.';

  @override
  String get walletConfigFreezeCardTitle => 'Congelar tarjeta';

  @override
  String get walletConfigFreezeCardSubtitle =>
      'Desactiva temporalmente el uso de esta billetera en el flujo visual.';

  @override
  String get walletConfigHideBalanceTitle => 'Ocultar saldo en home';

  @override
  String get walletConfigHideBalanceSubtitle =>
      'Mantiene la billetera visible, pero reduce la exposición del saldo.';

  @override
  String get walletConfigExportKeyTitle => 'Exportar clave privada';

  @override
  String get walletConfigExportKeySubtitle =>
      'Exige verificación adicional antes de revelar material sensible.';

  @override
  String get walletConfigCardRuleTitle => 'Regla de la tarjeta';

  @override
  String get walletConfigCardRuleSubtitle =>
      'El perfil considera la relación de la cuenta y el volumen elegible de los últimos 30 días.';

  @override
  String get walletConfigTitle => 'Tarjeta de la billetera';

  @override
  String get walletConfigSubtitle =>
      'Configuración visual, dirección y tasas de la billetera.';

  @override
  String walletConfigHeroSummary(
      int level, String cardType, String withdrawRate, String depositRate) {
    return 'Nivel $level • $cardType. Retiros externos usan $withdrawRate y depósitos externos usan $depositRate.';
  }

  @override
  String get walletConfigNetworkLabel => 'Red';

  @override
  String get walletConfigPathLabel => 'Path';

  @override
  String get walletConfigStatusLabel => 'Estado';

  @override
  String get walletConfigStatusFrozen => 'Congelado';

  @override
  String get walletConfigStatusActive => 'Activo';

  @override
  String get walletConfigLevelLabel => 'Nivel';

  @override
  String get walletConfigWithdrawLabel => 'Retiro';

  @override
  String get walletConfigWithdrawHelper => 'Salida externa';

  @override
  String get walletConfigDepositLabel => 'Depósito';

  @override
  String get walletConfigDepositHelper => 'Entrada externa';

  @override
  String get walletConfigInternalLabel => 'Interno';

  @override
  String get walletConfigInternalHelper => 'Entre billeteras Kerosene';

  @override
  String get walletCardUnavailableTitle => 'Tarjeta indisponible';

  @override
  String get walletCardNoActiveTitle => 'Ninguna tarjeta activa';

  @override
  String get walletCardNoActiveMessage =>
      'Crea una billetera para habilitar la tarjeta de la cuenta.';

  @override
  String get walletCardAccountCardsTitle => 'Tarjetas de la cuenta';

  @override
  String walletCardAccountCardsSubtitle(String walletName) {
    return 'Desliza para ver las tarjetas, tasas y requisitos de la cuenta $walletName.';
  }

  @override
  String get walletCardCurrentLabel => 'Actual';

  @override
  String get walletCardUpgradeLabel => 'Upgrade';

  @override
  String get walletCardAutomatic => 'Automático';

  @override
  String get walletCardValidityLabel => 'Validez';

  @override
  String get walletCardRotationLabel => 'Rotación';

  @override
  String get walletCardPreviousLabel => 'Anterior';

  @override
  String get walletCardRotating => 'En rotación';

  @override
  String get walletCardExpiring => 'Expirando';

  @override
  String get walletCardActive => 'Activo';

  @override
  String get walletCardNotInformed => 'No informado';

  @override
  String get walletCardRotationTitle => 'Rotación de la tarjeta';

  @override
  String get walletCardRotationSubtitle =>
      'La validez de la tarjeta es real y la próxima emisión ocurre automáticamente cuando la ventana expira.';

  @override
  String walletCardCurrentExpires(String cardNumber, String date) {
    return '$cardNumber • vence $date';
  }

  @override
  String get walletCardLastRotationLabel => 'Última rotación';

  @override
  String walletCardPreviousExpired(String cardNumber, String date) {
    return '$cardNumber • expiró $date';
  }

  @override
  String get walletCardYourCard => 'Tu tarjeta';

  @override
  String get walletCardDepositLabel => 'Depósito';

  @override
  String get walletCardWithdrawLabel => 'Retiro';

  @override
  String get walletCardHowToGet => 'Cómo conseguir';

  @override
  String get walletCardRulesTitle => 'Cómo cambian las tarjetas';

  @override
  String get walletCardRulesSubtitle =>
      'Cuando tu cuenta cumple los requisitos, la tarjeta cambia automáticamente.';

  @override
  String get walletCardGraphiteTitle => 'Grafito';

  @override
  String get walletCardSilverTitle => 'Plata';

  @override
  String get walletCardBlackTitle => 'Black';

  @override
  String get walletCardHiddenTitle => 'Oculto';

  @override
  String get walletCardGraphiteTier => 'Inicial';

  @override
  String get walletCardSilverTier => 'Intermedio';

  @override
  String get walletCardBlackTier => 'Mayor nivel';

  @override
  String get walletCardGraphiteDescription =>
      'Tarjeta inicial para usuarios nuevos. Es el nivel predeterminado de la cuenta.';

  @override
  String get walletCardSilverDescription =>
      'Mejora intermedia con tarifas menores para depósitos y retiros.';

  @override
  String get walletCardBlackDescription =>
      'Menor costo de la plataforma para cuentas con más tiempo y mayor volumen.';

  @override
  String get walletCardGraphiteQualification =>
      'Disponible automáticamente para cuentas nuevas.';

  @override
  String get walletCardSilverQualification =>
      'Movimiento superior a 1500 por mes y al menos 6 meses de cuenta.';

  @override
  String get walletCardBlackQualification =>
      'Movimiento superior a 4000 por mes y al menos 1 año de cuenta.';

  @override
  String get walletCardGraphiteEligibility => 'Usuarios nuevos.';

  @override
  String get walletCardSilverEligibility =>
      'Movimientos superiores a 1500 por mes y 6 meses de cuenta.';

  @override
  String get walletCardBlackEligibility =>
      'Movimientos superiores a 4000 por mes y 1 año de cuenta.';

  @override
  String get walletCardHashCopiedTitle => 'Hash copiado';

  @override
  String get walletCardHashCopiedMessage =>
      'El hash de la billetera fue copiado.';

  @override
  String get appEntryPinUnavailableTitle => 'PIN indisponible';

  @override
  String get appEntryPinUnavailableMessage =>
      'No fue posible validar la protección de entrada. Actualiza el estado e intenta de nuevo.';

  @override
  String get appEntryRefresh => 'Actualizar';

  @override
  String get appEntryConfirm => 'Confirmar';

  @override
  String get appEntryReset => 'Redefinir';

  @override
  String get appEntryExit => 'Salir';

  @override
  String get appEntryTotpLabel => 'Código TOTP';

  @override
  String get appEntryNewPinLabel => 'Nuevo PIN numérico';

  @override
  String appEntryPinLengthError(int min, int max) {
    return 'Usa entre $min y $max dígitos.';
  }

  @override
  String appEntryRetryIn(String duration) {
    return 'Nuevo intento en $duration.';
  }

  @override
  String get appEntryUnlockPrompt =>
      'Ingresa el PIN de este dispositivo para abrir tu billetera.';

  @override
  String get appEntryLockedHelper => 'Entrada bloqueada temporalmente.';

  @override
  String appEntryAttemptsHelper(int count) {
    return 'Intentos restantes antes del bloqueo: $count.';
  }

  @override
  String get appEntryLocalPinHelper =>
      'Este PIN protege solo este dispositivo.';

  @override
  String get appEntryEyebrow => 'PIN de entrada';

  @override
  String get appEntryResetTitle => 'Redefinir PIN';

  @override
  String get appEntryResetMessage =>
      'Usa el código autenticador de la cuenta para definir un nuevo PIN en este dispositivo.';

  @override
  String get appEntrySavePin => 'Guardar PIN';

  @override
  String get sessionEndedTitle => 'Sesión finalizada';

  @override
  String get primaryNavHome => 'Inicio';

  @override
  String get primaryNavCard => 'Tarjeta';

  @override
  String get primaryNavHistory => 'Historial';

  @override
  String get primaryNavSettings => 'Ajustes';

  @override
  String get securityTreasuryBuffer => 'Buffer';

  @override
  String get securityTreasuryConfirmations => 'Confirmaciones';

  @override
  String get securityTreasuryLightning => 'Lightning';

  @override
  String get securityTreasuryProfit => 'Ganancia';

  @override
  String get landingNavProduct => 'Producto';

  @override
  String get landingNavSecurity => 'Seguridad';

  @override
  String get landingNavBusiness => 'Empresas';

  @override
  String get landingNavInfrastructure => 'Infraestructura';

  @override
  String get landingNavFaq => 'FAQ';

  @override
  String get landingLoginAction => 'Entrar';

  @override
  String get landingCreateAccountAction => 'Crear cuenta';

  @override
  String get landingBusinessPanelAction => 'Ver panel empresarial';

  @override
  String get landingSalesAction => 'Hablar con ventas';

  @override
  String get landingHeroEyebrow => 'Infraestructura financiera Bitcoin privada';

  @override
  String get landingHeroTitle => 'Tu banco Bitcoin.';

  @override
  String get landingHeroSubtitle =>
      'Kerosene hace que Bitcoin sea más seguro, accesible y útil para personas y empresas, con privacidad, transparencia operativa y control real de tus activos.';

  @override
  String get landingHeroFeatureOnchainTitle => 'On-chain + Lightning';

  @override
  String get landingHeroFeatureOnchainBody =>
      'Liquidez y velocidad en el mismo lugar.';

  @override
  String get landingHeroFeatureInternalTitle => 'Transferencias internas';

  @override
  String get landingHeroFeatureInternalBody =>
      'Mueve saldo entre usuarios Kerosene.';

  @override
  String get landingHeroFeatureSecurityTitle => 'Seguridad institucional';

  @override
  String get landingHeroFeatureSecurityBody =>
      'Arquitectura privada con auditoría continua.';

  @override
  String get landingWhatTitle => 'Qué hace Kerosene';

  @override
  String get landingFeatureWalletsTitle => 'Billeteras Bitcoin';

  @override
  String get landingFeatureWalletsBody =>
      'Crea y administra cuentas y billeteras con autonomía y seguridad.';

  @override
  String get landingFeatureOnchainReceiveTitle => 'Recepción on-chain';

  @override
  String get landingFeatureOnchainReceiveBody =>
      'Recibe Bitcoin por dirección on-chain con control total sobre tus activos.';

  @override
  String get landingFeatureLightningTitle => 'Lightning';

  @override
  String get landingFeatureLightningBody =>
      'Crea y paga invoices Lightning con velocidad y bajo costo.';

  @override
  String get landingFeatureInternalTransfersTitle => 'Transferencias internas';

  @override
  String get landingFeatureInternalTransfersBody =>
      'Mueve saldo entre usuarios Kerosene de forma instantánea y privada.';

  @override
  String get landingFeaturePaymentLinksTitle => 'Payment links';

  @override
  String get landingFeaturePaymentLinksBody =>
      'Crea enlaces y solicitudes de pago para recibir Bitcoin con facilidad.';

  @override
  String get landingFeatureRealtimeTitle => 'Tiempo real';

  @override
  String get landingFeatureRealtimeBody =>
      'Sigue saldos y transacciones en tiempo real con total transparencia.';

  @override
  String get landingAudienceTitle => 'Para personas y empresas';

  @override
  String get landingPeopleTitle => 'Para personas';

  @override
  String get landingPeopleDaily => 'Uso diario con privacidad y control.';

  @override
  String get landingPeopleCustody =>
      'Custodia segura con estándar institucional.';

  @override
  String get landingPeopleSeparation =>
      'Separación entre saldo operativo y cold wallets observables.';

  @override
  String get landingPeopleLogin => 'Login con passkey o TOTP.';

  @override
  String get landingBusinessTitle => 'Para empresas';

  @override
  String get landingBusinessPanel =>
      'Panel web completo para equipos y admins.';

  @override
  String get landingBusinessOperations =>
      'Gestión operativa de billeteras y usuarios.';

  @override
  String get landingBusinessMonitoring =>
      'Monitoreo de infraestructura y liquidez.';

  @override
  String get landingBusinessVision =>
      'Visión financiera y operativa en tiempo real.';

  @override
  String get landingArchitectureTitle =>
      'Arquitectura preparada para escenarios sensibles.';

  @override
  String get landingArchitectureSubtitle =>
      'Kerosene fue diseñada más allá de integraciones superficiales. Una infraestructura Bitcoin privada, resiliente, auditable y construida para largo plazo.';

  @override
  String get landingArchitectureBitcoinCoreTitle => 'Bitcoin Core';

  @override
  String get landingArchitectureBitcoinCoreBody =>
      'Capa base de validación y consenso.';

  @override
  String get landingArchitectureLightningTitle => 'Lightning';

  @override
  String get landingArchitectureLightningBody =>
      'Pagos instantáneos y eficientes.';

  @override
  String get landingArchitectureVaultTitle => 'Vault';

  @override
  String get landingArchitectureVaultBody =>
      'Almacenamiento en frío con política de seguridad.';

  @override
  String get landingArchitectureMpcTitle => 'MPC';

  @override
  String get landingArchitectureMpcBody =>
      'Firmas distribuidas sin punto único de falla.';

  @override
  String get landingArchitectureTorTitle => 'Tor';

  @override
  String get landingArchitectureTorBody => 'Privacidad y ruteo anónimo.';

  @override
  String get landingArchitectureShardsTitle => 'Shards regionales';

  @override
  String get landingArchitectureShardsBody =>
      'Infraestructura distribuida por regiones.';

  @override
  String get landingArchitectureLedgerTitle => 'Ledger interno';

  @override
  String get landingArchitectureLedgerBody =>
      'Contabilidad privada y consistente.';

  @override
  String get landingArchitectureAuditTitle => 'Auditoría';

  @override
  String get landingArchitectureAuditBody =>
      'Auditoría continua y transparencia operativa.';

  @override
  String get landingSecurityTitle => 'Seguridad en cada capa.';

  @override
  String get landingSecurityPasskeysTitle => 'Passkeys y TOTP';

  @override
  String get landingSecurityPasskeysBody =>
      'Autenticación moderna con passkeys y 2FA TOTP para proteger accesos.';

  @override
  String get landingSecurityVaultMpcTitle => 'Vault y MPC';

  @override
  String get landingSecurityVaultMpcBody =>
      'Custodia con MPC y vaults distribuidos para máxima resiliencia.';

  @override
  String get landingSecurityPrivacyTitle => 'Privacidad por defecto';

  @override
  String get landingSecurityPrivacyBody =>
      'Privacidad incorporada en toda la operación, por diseño.';

  @override
  String get landingSecurityAuditTitle => 'Auditoría operativa';

  @override
  String get landingSecurityAuditBody =>
      'Monitoreo continuo, logs privados y auditoría independiente.';

  @override
  String get landingFinalTitle =>
      'Más control. Menos exposición. Más previsibilidad.';

  @override
  String get landingFinalBody =>
      'Kerosene es infraestructura financiera Bitcoin privada para personas y empresas que quieren guardar, usar y mover valor con más control, seguridad e independencia.';

  @override
  String get landingFooterRights =>
      '© 2024 Kerosene. Todos los derechos reservados.';

  @override
  String get landingFooterStatus => 'Status';

  @override
  String get landingStatusOnline => 'Operacional';

  @override
  String get landingStatusChecking => 'Verificando';

  @override
  String get landingStatusDegraded => 'Degradado';

  @override
  String get landingStatusUnavailable => 'No disponible';

  @override
  String get landingStatusAuthorized => 'autorizado';

  @override
  String get landingStatusUnknown => 'desconocido';

  @override
  String get landingStatusPageTitle => 'Status público Kerosene';

  @override
  String get landingStatusPageSubtitle =>
      'Readiness y release publicados sin secretos, tokens ni configuración sensible.';

  @override
  String get landingStatusRelease => 'Release';

  @override
  String get landingStatusService => 'Servicio';

  @override
  String get landingStatusRegion => 'Región';

  @override
  String get landingStatusBuild => 'Build';

  @override
  String get landingStatusManifest => 'Manifesto';

  @override
  String get landingNetworkStatusLabel => 'ESTADO DE LA RED';

  @override
  String get landingNetworkOnlineDetail => '100% On-chain & Tor';

  @override
  String get landingNetworkFallbackDetail => 'On-chain & Tor';

  @override
  String get landingApiAccessTitle => 'API ACCESS';

  @override
  String get landingApiAccessBody =>
      'La documentación técnica está disponible en el portal para desarrolladores en red Onion.';

  @override
  String landingStatusLine(String label, String status) {
    return '$label: $status';
  }

  @override
  String get homeFundsDistributionTitle => 'Distribución de fondos';

  @override
  String get homeRecentActivitiesTitle => 'Actividades';

  @override
  String get homeViewStatementShortLabel => 'Extracto';

  @override
  String get homeOnchainFilterLabel => 'On-chain';

  @override
  String get homePlatformFilterLabel => 'Plataforma';

  @override
  String get homeNoticesFilterLabel => 'Avisos';

  @override
  String get homeEducationInternalTitle => 'Kerosene';

  @override
  String get homeEducationInternalBody =>
      'Usa transferencias internas cuando el destino también usa Kerosene. El envío es rápido y sin comisión de red.';

  @override
  String get homeEducationInternalTag => 'Uso interno';

  @override
  String get homeEducationWalletHashTitle => 'Hash de billetera';

  @override
  String get homeEducationWalletHashBody =>
      'Para recibir internamente, comparte solo el hash que entrega tu propia billetera.';

  @override
  String get homeEducationWalletHashTag => 'Identidad de billetera';

  @override
  String get homeEducationLightningTitle => 'Lightning';

  @override
  String get homeEducationLightningBody =>
      'Usa Lightning para pagar invoices o direcciones lightning con confirmación casi inmediata.';

  @override
  String get homeEducationLightningTag => 'Pagos rápidos';

  @override
  String get homeEducationOnchainTitle => 'Bitcoin on-chain';

  @override
  String get homeEducationOnchainBody =>
      'Usa on-chain para guardar valor, mover a autocustodia o enviar a una billetera Bitcoin externa.';

  @override
  String get homeEducationOnchainTag => 'Red principal';

  @override
  String get homeEducationConfirmationsTitle => 'Confirmaciones';

  @override
  String get homeEducationConfirmationsBody =>
      'Las transacciones on-chain entran en bloques. Los valores mayores suelen requerir más confirmaciones.';

  @override
  String get homeEducationConfirmationsTag => 'Tiempo de red';

  @override
  String get homeEducationFeesTitle => 'Comisiones';

  @override
  String get homeEducationFeesBody =>
      'La comisión varía según la red. Antes de confirmar, revisa el total debitado y el importe recibido.';

  @override
  String get homeEducationFeesTag => 'Costo de red';

  @override
  String get homeEducationBitcoinTitle => 'Bitcoin';

  @override
  String get homeEducationBitcoinBody =>
      'Bitcoin es dinero digital escaso. Puedes usar rutas distintas según urgencia y destino.';

  @override
  String get homeEducationBitcoinTag => 'Fundamento';

  @override
  String get homeEducationLightningGeneralBody =>
      'Lightning sirve para pagos menores y rápidos usando invoice, LNURL o dirección lightning.';

  @override
  String get homeEducationLightningGeneralTag => 'Pago instantáneo';

  @override
  String get homeEducationKeroseneGeneralBody =>
      'Kerosene separa envíos internos, Lightning y on-chain para reducir errores.';

  @override
  String get homeEducationKeroseneGeneralTag => 'Cómo elegir';

  @override
  String get designSystemTemplateTitle => 'Design system';

  @override
  String get designSystemTemplateIdentitySection =>
      '01. Identidad visual y título';

  @override
  String get designSystemTemplateHeroTitle => 'Kerosene Sovereign Core';

  @override
  String get designSystemTemplatePanelsSection =>
      '02. Paneles y caja monocromática';

  @override
  String get designSystemTemplateInputSection =>
      '03. Entrada de datos formateada';

  @override
  String get designSystemTemplateButtonsSection => '04. Botones estandarizados';

  @override
  String get designSystemTemplateStatusSection => '05. Etiquetas de estado';

  @override
  String get walletSelectorLoadErrorTitle =>
      'No se pudieron cargar las carteras';

  @override
  String get walletSelectorRetry => 'Reintentar';

  @override
  String get walletSelectorNoWallets =>
      'No se encontraron carteras. Crea una para empezar.';

  @override
  String get walletSelectorSendSubtitle =>
      'Elige qué cartera financiará este envío.';

  @override
  String get walletSelectorReceiveSubtitle =>
      'Elige dónde deben llegar los fondos recibidos.';

  @override
  String get walletSelectorDepositSubtitle =>
      'Elige qué cartera recibirá este depósito.';

  @override
  String get walletSelectorWithdrawSubtitle =>
      'Elige qué cartera financiará este retiro externo.';

  @override
  String get walletSelectorAvailableBalance => 'Saldo disponible';
}
