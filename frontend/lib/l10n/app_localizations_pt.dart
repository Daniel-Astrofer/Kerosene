// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Kerosene';

  @override
  String get home => 'Início';

  @override
  String get market => 'Mercado';

  @override
  String get profile => 'Perfil';

  @override
  String get totalBalance => 'Saldo Total (BTC)';

  @override
  String get totalBalanceGeneric => 'Saldo Total';

  @override
  String get myWallets => 'Minhas Carteiras';

  @override
  String get actions => 'Ações';

  @override
  String get send => 'Enviar';

  @override
  String get receive => 'Receber';

  @override
  String get addFunds => 'Adicionar Fundos';

  @override
  String get recentTransactions => 'Transações Recentes';

  @override
  String get viewAll => 'Ver Tudo';

  @override
  String get noTransactions => 'Nenhuma transação encontrada';

  @override
  String get bitcoinTrading => 'Negociação Bitcoin';

  @override
  String get marketStats => 'Estatísticas do Mercado';

  @override
  String get high24h => 'Máxima 24h';

  @override
  String get low24h => 'Mínima 24h';

  @override
  String get totalVolume24h => 'Volume Total (24h)';

  @override
  String get fiatVolume => 'Volume Fiat';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get personalData => 'Dados Pessoais';

  @override
  String get security => 'Segurança';

  @override
  String get notifications => 'Notificações';

  @override
  String get helpSupport => 'Ajuda & Suporte';

  @override
  String get language => 'Idioma';

  @override
  String get logout => 'Sair da Conta';

  @override
  String get wallets => 'Carteiras';

  @override
  String get totalVolume => 'Volume Total';

  @override
  String get depositAddress => 'Endereço de Depósito';

  @override
  String get platformDepositAddress => 'Endereço de Depósito da Plataforma';

  @override
  String get amount => 'Valor';

  @override
  String get sourceWallet => 'Carteira de Origem';

  @override
  String get generatePaymentLink => 'Gerar Link de Pagamento';

  @override
  String get paymentInstructions => 'Instruções de Pagamento';

  @override
  String get sendExactAmount =>
      'Envie exatamente este valor para o endereço abaixo:';

  @override
  String get fundsWillBeCredited =>
      'Os fundos serão creditados após confirmação da rede';

  @override
  String get close => 'Fechar';

  @override
  String get addressCopied => 'Endereço copiado!';

  @override
  String get destinationAddress => 'Endereço de Destino';

  @override
  String get estimatedFee => 'Taxa Estimada';

  @override
  String get total => 'Total';

  @override
  String get confirmSend => 'Confirmar & Enviar';

  @override
  String get scanQR => 'Escanear QR';

  @override
  String get pasteAddress => 'Colar Endereço';

  @override
  String get transactionDetails => 'Detalhes da Transação';

  @override
  String get status => 'Status';

  @override
  String get value => 'Valor';

  @override
  String get fee => 'Taxa';

  @override
  String get hash => 'Hash';

  @override
  String get date => 'Data';

  @override
  String get confirmed => 'Confirmada';

  @override
  String get pending => 'Pendente';

  @override
  String get failed => 'Falhou';

  @override
  String get welcome => 'Bem-vindo';

  @override
  String get getStarted => 'Começar';

  @override
  String get login => 'Entrar';

  @override
  String get register => 'Registrar';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Senha';

  @override
  String get confirmPassword => 'Confirmar Senha';

  @override
  String get name => 'Nome';

  @override
  String get error => 'Erro';

  @override
  String get success => 'Sucesso';

  @override
  String get loading => 'Carregando';

  @override
  String get retry => 'Tentar Novamente';

  @override
  String get cancel => 'Cancelar';

  @override
  String get goBack => 'Voltar';

  @override
  String get done => 'Concluído';

  @override
  String get save => 'Salvar';

  @override
  String get invalidAmount => 'Valor inválido';

  @override
  String get insufficientFunds => 'Fundos insuficientes';

  @override
  String get pleaseEnterAmount => 'Por favor, insira um valor';

  @override
  String get pleaseCompleteFields => 'Por favor, preencha todos os campos';

  @override
  String get depositInitiated => 'Depósito Iniciado!';

  @override
  String get depositSuccess =>
      'Sua transação de depósito foi transmitida. Será creditada após confirmação.';

  @override
  String get errorLoadingData => 'Erro ao carregar dados';

  @override
  String get tryAgain => 'Tentar Novamente';

  @override
  String get noChartData => 'Sem dados do gráfico';

  @override
  String get walletSettings => 'Configurações da Carteira';

  @override
  String get spendingLimit => 'Limite de Gastos';

  @override
  String get exportPrivateKey => 'Exportar Chave Privada';

  @override
  String get removeWallet => 'Remover Carteira';

  @override
  String currencyQuotation(Object value) {
    return '1 BRL = $value USD';
  }

  @override
  String approximateValue(Object currency, Object value) {
    return '≈ $value $currency';
  }

  @override
  String get paymentLinks => 'Links de Pagamento';

  @override
  String get networkFee => 'Taxa de Rede';

  @override
  String get youWillReceive => 'Você receberá';

  @override
  String get confirmationTime => 'Tempo de confirmação';

  @override
  String get walletName => 'Nome da Carteira';

  @override
  String get setSpendingLimit => 'Definir Limite de Gastos';

  @override
  String get amountInBtc => 'Valor em BTC';

  @override
  String get getStartedDescription =>
      'Crie sua primeira carteira Bitcoin para começar.';

  @override
  String get welcomeSlogan =>
      'Construída com infraestrutura monetária moderna, projetada para oferecer segurança, previsibilidade e velocidade.';

  @override
  String get signIn => 'Entrar';

  @override
  String get createAccount => 'Criar Conta';

  @override
  String get welcomeBack => 'Bem-vindo de Volta';

  @override
  String get signInToAccess => 'Entre para acessar sua carteira';

  @override
  String get username => 'Usuário';

  @override
  String get passphrase => 'Frase secreta';

  @override
  String get required => 'Obrigatório';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get currency => 'Moeda';

  @override
  String get selectLanguage => 'Selecionar Idioma';

  @override
  String get selectCurrency => 'Selecionar Moeda';

  @override
  String get selectWalletToSend => 'Selecione uma carteira para enviar.';

  @override
  String get errorLoadingWallets => 'Erro ao carregar carteiras';

  @override
  String get add => 'Add';

  @override
  String get deposit => 'Depositar';

  @override
  String get nfc => 'NFC';

  @override
  String get qrCode => 'QR Code';

  @override
  String get sentTo => 'Enviado para';

  @override
  String get receivedFrom => 'Recebido de';

  @override
  String get showLess => 'Ver Menos';

  @override
  String get confirming => 'Confirmando';

  @override
  String get typeSend => 'Envio';

  @override
  String get typeReceive => 'Recebimento';

  @override
  String get typeSwap => 'Troca';

  @override
  String get typeFee => 'Taxa';

  @override
  String get hashCopied => 'Hash copiado!';

  @override
  String get transactionSentSuccess => 'Transação enviada com sucesso!';

  @override
  String get recipient => 'Destinatário';

  @override
  String get selectRecipient => 'Selecionar Destinatário';

  @override
  String get searchAddress => 'Buscar ou colar endereço';

  @override
  String get noRecentContacts => 'Sem contatos recentes';

  @override
  String get unknown => 'Desconhecido';

  @override
  String fromWallet(Object name) {
    return 'De: $name';
  }

  @override
  String get yourBitcoinAddress => 'Seu Endereço Bitcoin';

  @override
  String get addressNotAvailable => 'Endereço não disponível';

  @override
  String get copyAddress => 'Copiar Endereço';

  @override
  String get howMuchToReceive => 'Quanto você quer receber?';

  @override
  String get receiveMethod => 'Método de Recebimento';

  @override
  String get generateQrCodeDescription => 'Gere um código para ser escaneado';

  @override
  String get nfcBeam => 'NFC Beam';

  @override
  String get nfcTagDescription => 'Grave o pedido em uma tag NFC';

  @override
  String get scanToPay => 'Escanear para Pagar';

  @override
  String get approachPhoneToNfc => 'Aproxime o celular da tag NFC';

  @override
  String get nfcTagNotSupported => 'Tag não suporta NDEF';

  @override
  String get nfcTagNotWritable => 'Tag não pode ser gravada';

  @override
  String get nfcTagCapacityError => 'Pedido maior que a capacidade da tag';

  @override
  String get nfcTagWrittenSuccess => 'Tag gravada com sucesso!';

  @override
  String get writeNfcTag => 'Gravar Tag NFC';

  @override
  String errorWriting(Object error) {
    return 'Erro ao gravar: $error';
  }

  @override
  String get typeWithdrawal => 'Retirada';

  @override
  String get typeDeposit => 'Depósito';

  @override
  String get rememberMe => 'Lembrar de mim';

  @override
  String get torOnionActive => 'Protocolo Onion Ativo (Kerosene Core)';

  @override
  String get signupFeeTitle => 'Taxa de Ativação';

  @override
  String get signupFeeSubtitle =>
      'Uma taxa única de 0,003 BTC é necessária para ativar sua conta e evitar spam.';

  @override
  String get signupFeeWhyTitle => 'Por que uma taxa?';

  @override
  String get signupFeeWhyBody =>
      'A Kerosene não tem formulário de cadastro ou e-mail. A taxa é uma Prova de Trabalho que protege a rede contra bots e contas falsas.';

  @override
  String get signupFeeNotRefundable => 'Não reembolsável';

  @override
  String get signupFeeNotRefundableBody =>
      'Uma vez transmitida, a taxa não pode ser recuperada. Certifique-se de estar pronto antes de continuar.';

  @override
  String get signupFeeContinue => 'Entendi, Continuar';

  @override
  String get seedSecurityTitle => 'Segurança da Semente';

  @override
  String get seedSecuritySubtitle =>
      'Escolha como deseja proteger a frase de recuperação da sua carteira.';

  @override
  String get seedStandardTitle => 'Padrão';

  @override
  String get seedStandardDesc =>
      'Uma frase de recuperação de 12, 18 ou 24 palavras. Ideal para uso geral e simplicidade.';

  @override
  String get seedSlip39Title => 'Shamir SLIP-39 (Multi-partes)';

  @override
  String get seedSlip39Desc =>
      'Divida sua semente em várias partes. Requer um número mínimo para recuperar (ex: 3-de-5). Ideal para armazenamento físico distribuído.';

  @override
  String get seedMultisigTitle => 'Cofre Multisig 2FA';

  @override
  String get seedMultisigDesc =>
      'Uma carteira Multisig 2-de-3. A Kerosene co-assina transações via TOTP. Protege contra o roubo do dispositivo.';

  @override
  String get seedSlip39ConfigTitle => 'Configuração SLIP-39';

  @override
  String get seedSlip39TotalShares => 'Total de Partes (Peças)';

  @override
  String get seedSlip39Threshold => 'Limite Necessário';

  @override
  String seedSlip39Summary(Object threshold, Object total) {
    return 'Requer $threshold de $total partes para restaurar a carteira.';
  }

  @override
  String get passphraseTitle => 'Sua Frase Secreta';

  @override
  String get passphraseSubtitle =>
      'Anote estas 18 palavras em um papel físico. Nunca salve digitalmente.';

  @override
  String get passphraseWrittenDown => 'Já Anotei';

  @override
  String get passphraseWarning =>
      'Se você perder essas palavras, perderá permanentemente o acesso à sua conta e fundos.';

  @override
  String get passphraseVerifyTitle => 'Verificar Frase';

  @override
  String get passphraseVerifySubtitle =>
      'Digite sua frase secreta para confirmar que fez o backup corretamente.';

  @override
  String get passphraseVerifyHint => 'palavra1 palavra2 palavra3...';

  @override
  String get passphraseVerifyError =>
      'Frase incorreta. Por favor, tente novamente.';

  @override
  String get passphraseVerifyContinue => 'Verificar e Continuar';

  @override
  String get passphraseGoBack => 'Voltar para ver a frase';

  @override
  String get passphraseEnterWords => 'Digite suas 18 palavras';

  @override
  String get slip39SharesTitle => 'Suas Partes SLIP-39';

  @override
  String slip39SharesSubtitle(Object threshold, Object total) {
    return 'Sua semente está dividida em $total peças. Você precisa de $threshold delas para recuperar sua carteira.';
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
    return 'Digite as palavras da Parte $index exatamente como você as anotou.';
  }

  @override
  String slip39ConfirmShare(Object index) {
    return 'Confirmar Parte $index';
  }

  @override
  String get slip39AllConfirmedContinue =>
      'Todas as Partes Confirmadas — Continuar';

  @override
  String slip39ConfirmAllPending(Object total) {
    return 'Confirme as $total partes para continuar';
  }

  @override
  String slip39Warning(Object threshold) {
    return 'NÃO armazene todas as partes no mesmo local. Se um atacante encontrar partes suficientes, pode recuperar sua carteira.';
  }

  @override
  String get twoFaPrimaryTitle => 'Sua Semente Principal';

  @override
  String get twoFaPrimaryBadge =>
      'Chave 1 de 3 — Fica apenas no seu dispositivo';

  @override
  String get twoFaPrimarySubtitle =>
      'Esta frase de 18 palavras é sua chave privada principal. Sozinha, NÃO é suficiente para assinar transações — uma autorização TOTP da Kerosene é sempre necessária.';

  @override
  String get twoFaPrimaryWritten => 'Já Anotei';

  @override
  String get twoFaBackupTitle => 'Sua Semente de Recuperação';

  @override
  String get twoFaBackupBadge =>
      'Chave 3 de 3 — Emergência / Bypass de Soberania';

  @override
  String get twoFaBackupSubtitle =>
      'Se a Kerosene encerrar, use esta semente de 12 palavras com sua semente principal para recuperar os fundos sem envolvimento do servidor.';

  @override
  String get twoFaCoSignerNote =>
      'A Chave 2 de 3 fica criptografada na Kerosene e é usada apenas para co-assinar transações quando você fornecer um código TOTP válido.';

  @override
  String get twoFaBothStored => 'Guardei Ambas as Sementes';

  @override
  String get twoFaBackToPrimary => 'Voltar à Semente Principal';

  @override
  String get twoFaVerifyTitle => 'Verificar Semente Principal';

  @override
  String get twoFaVerifySubtitle =>
      'Confirme sua Chave Principal (18 palavras) para provar que está armazenada com segurança.';

  @override
  String get twoFaVerifyHint => 'palavra1 palavra2 palavra3...';

  @override
  String get twoFaVerifyError =>
      'Incorreto. Por favor, verifique sua Semente Principal.';

  @override
  String get twoFaVerifyActivate => 'Verificar e Ativar Cofre 2FA';

  @override
  String get twoFaBackToBackup => 'Voltar à Semente de Recuperação';

  @override
  String get totpSetupTitle => 'Configurar Autenticador';

  @override
  String get totpSetupSubtitle =>
      'Escaneie o QR code com seu app autenticador, depois insira o código de 6 dígitos para verificar.';

  @override
  String get totpCodeLabel => 'Insira o código de 6 dígitos';

  @override
  String get totpVerifyButton => 'Verificar e Continuar';

  @override
  String get totpErrorInvalid => 'Código inválido. Por favor, tente novamente.';

  @override
  String get passkeyTitle => 'Registrar Passkey';

  @override
  String get passkeySubtitle =>
      'Registre uma passkey biométrica para fazer login rápido e sem senha neste dispositivo.';

  @override
  String get passkeyRegisterButton => 'Registrar Passkey (Biometria)';

  @override
  String get passkeySuccessMessage => 'Passkey registrada com sucesso!';

  @override
  String get passkeySkip => 'Pular por enquanto';

  @override
  String get usernameTitle => 'Escolha seu Apelido';

  @override
  String get usernameSubtitle =>
      'Escolha um nome de usuário único. Esta é sua identidade pública na Kerosene.';

  @override
  String get usernameFieldLabel => 'Usuário';

  @override
  String get usernameFieldHint => '@seu_usuario';

  @override
  String get usernameCheckButton => 'Verificar Disponibilidade';

  @override
  String get usernameAvailable => 'Usuário disponível!';

  @override
  String get usernameTaken => 'Usuário já está em uso.';

  @override
  String get usernameContinue => 'Reservar Usuário e Continuar';

  @override
  String get paymentTitle => 'Pagamento de Ativação';

  @override
  String get paymentSubtitle =>
      'Envie exatamente o valor mostrado abaixo para ativar sua conta.';

  @override
  String get paymentTimeLeft => 'Tempo restante';

  @override
  String get paymentExpired => 'Janela de pagamento expirou';

  @override
  String get paymentExpiredMessage =>
      'Você não concluiu o pagamento na janela de 15 minutos. Seus dados temporários serão apagados e você deve recomeçar.';

  @override
  String get paymentWaiting => 'Aguardando pagamento...';

  @override
  String get paymentAmountLabel => 'Valor';

  @override
  String get paymentAddressLabel => 'Endereço de Depósito';

  @override
  String get paymentCopyAddress => 'Copiar Endereço';

  @override
  String get paymentAddressCopied => 'Endereço copiado!';

  @override
  String get confirmationsTitle => 'Aguardando Confirmações';

  @override
  String get confirmationsSubtitle =>
      'Seu pagamento foi detectado. Aguardando 3 confirmações da rede Bitcoin para finalizar sua conta.';

  @override
  String confirmationsProgress(Object current, Object total) {
    return '$current / $total confirmações';
  }

  @override
  String get confirmationsDone => 'Conta Ativada!';

  @override
  String get presentationSlide1Title =>
      'Infraestrutura Segura desde o Primeiro Acesso';

  @override
  String get presentationSlide1Body =>
      'A Kerosene opera com arquitetura tecnológica avançada em ambiente protegido via rede onion. Essa estrutura reforça privacidade, resiliência e proteção contra interferências externas.\n\nSegurança não é um recurso adicional.\nÉ a base do sistema.';

  @override
  String get presentationSlide2Title =>
      'Criação de Conta com Mecanismo de Proteção Estrutural';

  @override
  String get presentationSlide2Body =>
      'Para preservar a integridade da infraestrutura, a criação de conta exige o envio de 0.003 BTC.\nEsse valor permanece integralmente na sua conta.\nNo processo de registro, é descontada apenas a taxa de transação da rede necessária para confirmação da operação.\nEssa exigência técnica existe para:\n\n• Impedir criação automatizada de contas\n• Reduzir vetores de ataque distribuído\n• Manter estabilidade operacional\n• Proteger todos os usuários da plataforma\n\nNão se trata de mensalidade.\nNão é cobrança recorrente.\nÉ um mecanismo de proteção estrutural.';

  @override
  String get presentationSlide3Title => 'Estrutura de Taxas Clara e Objetiva';

  @override
  String get presentationSlide3Body =>
      'Nossa política é simples:\n\n• 0.9% sobre depósitos\n• 0.9% sobre saques\n• 0% para transferências internas\n\nTransferências entre usuários da Kerosene são instantâneas e sem custo.\n\nSem tarifas ocultas.\nSem variações inesperadas.';

  @override
  String get presentationSlide4Title => 'Compromisso com Previsibilidade';

  @override
  String get presentationSlide4Body =>
      'A Kerosene foi projetada para operar com:\n\n• Estabilidade técnica\n• Transparência operacional\n• Segurança estrutural\n• Previsibilidade de custos\n\nNossa prioridade é manter uma infraestrutura sólida, protegida e sustentável no longo prazo.';

  @override
  String get presentationSkip => 'Pular';

  @override
  String get presentationNext => 'Avançar';

  @override
  String get presentationStart => 'Acessar Kerosene';

  @override
  String get signupScreenTitle => 'Criar Carteira';

  @override
  String get signupScreenSubtitle =>
      'Configure seu usuário e chave de segurança.';

  @override
  String get signupUsernameHelper => 'Apenas a-z, 0-9 e _';

  @override
  String get signupUsernameHint => 'letras minúsculas, números e _';

  @override
  String get signupUsernameMinChars => 'Mínimo 3 caracteres';

  @override
  String get signupUsernameInvalid => 'Caracteres inválidos';

  @override
  String get signupMnemonicLabel => 'SUA FRASE SECRETA (BIP39)';

  @override
  String get signupMnemonicWarning =>
      'Guarde esta frase com segurança. É a ÚNICA forma de recuperar sua conta.';

  @override
  String get signupMnemonicCopySuccess => 'Frase copiada com segurança!';

  @override
  String get signupMnemonicCopy => 'Copiar';

  @override
  String get signupMnemonicGenerateNew => 'Gerar Nova';

  @override
  String get signupMnemonicError => 'Erro ao gerar frase, tente novamente';

  @override
  String get feeExplanationTitle => 'Taxa de Rede Segura';

  @override
  String get feeExplanationSubtitle =>
      'Para evitar spam e garantir a robustez da rede Kerosene, a criação de conta requer uma pequena taxa anti-spam de 0.003 BTC.';

  @override
  String get feeExplanationWhereGoesTitle => 'Para onde isso vai?';

  @override
  String get feeExplanationWhereGoesSubtitle =>
      'O valor total de 0.003 BTC vai diretamente para o saldo da sua carteira assim que a conta for criada.';

  @override
  String get feeExplanationContinue => 'Eu Entendo, Continuar';

  @override
  String get seedSecurityContinue => 'Continuar';

  @override
  String get totpTitle => 'Autenticação de Dois Fatores';

  @override
  String get totpSubtitle =>
      'Escaneie este código QR com seu aplicativo autenticador (ex: Google Authenticator, Authy).';

  @override
  String get totpSecretCopied => 'Segredo copiado para a área de transferência';

  @override
  String get totpEnterCodeHint => '000000';

  @override
  String get totpEnter6Digits => 'Digite 6 dígitos';

  @override
  String get totpInvalidCode => 'Código inválido. Tente novamente.';

  @override
  String get totpVerifyContinue => 'Verificar e Continuar';

  @override
  String get totpVerifying => 'Verificando código...';

  @override
  String get totpAuthenticating => 'Autenticando...';

  @override
  String get totpEstablishingSession => 'Estabelecendo Sessão...';

  @override
  String get passkeySessionNotFound =>
      'Sessão não encontrada. Por favor, reinicie o processo.';

  @override
  String get passkeyNoBiometrics =>
      'Nenhum hardware biométrico disponível neste dispositivo.';

  @override
  String passkeyErrorStarting(String message) {
    return 'Erro ao iniciar registro: $message';
  }

  @override
  String get passkeyBiometricReason =>
      'Crie uma Passkey para proteger sua carteira Kerosene';

  @override
  String passkeyErrorFinishing(String message) {
    return 'Erro ao finalizar registro: $message';
  }

  @override
  String get passkeyAuthFailed => 'Autenticação cancelada ou falhou.';

  @override
  String passkeyUnexpectedError(String error) {
    return 'Erro inesperado: $error';
  }

  @override
  String get passkeyLoadingInitBiom => 'Inicializando Biometria...';

  @override
  String get passkeyLoadingSecuring => 'Protegendo Dispositivo...';

  @override
  String get passkeyLoadingRegistering => 'Registrando Passkey...';

  @override
  String get usernameHintChars => 'a-z, 0-9 e _';

  @override
  String get usernameHelperLength => 'Deve ter entre 3 e 15 caracteres';

  @override
  String get usernameErrorMin => 'Mínimo 3 caracteres';

  @override
  String get usernameErrorMax => 'Máximo 15 caracteres';

  @override
  String get usernameErrorInvalidChars => 'Caracteres inválidos';

  @override
  String get usernameLoadingPow => 'Calculando Prova de Trabalho...';

  @override
  String get usernameLoadingKeys => 'Protegendo Chaves...';

  @override
  String get usernameLoadingInvoice => 'Gerando Fatura...';

  @override
  String get usernameLoadingNetwork => 'Conectando à Rede...';

  @override
  String get paymentExpiredLabel => 'EXPIRADO';

  @override
  String get confNetworkError => 'Erro de Rede';

  @override
  String get confNetworkVerified => 'Rede Verificada!';

  @override
  String get confConfirming => 'Confirmando na Blockchain';

  @override
  String get confErrorMsg =>
      'Ocorreu um erro ao finalizar a criação da sua conta no servidor. Por favor, reinicie o processo de configuração com segurança.';

  @override
  String get confVerifiedMsg =>
      'Sua conta foi criada oficialmente e sua taxa adicionada ao seu saldo. Entrando no gateway...';

  @override
  String get confWaitingMsg =>
      'Aguardando 3 confirmações da rede Bitcoin. Isso pode levar cerca de 30 minutos, mas você pode sair do aplicativo com segurança; nós o notificaremos quando estiver pronto.';

  @override
  String get confRestartSignup => 'Reiniciar Cadastro';

  @override
  String get confNotificationNotice =>
      'Você receberá uma notificação push quando a 3ª confirmação chegar.';

  @override
  String get homePlatformLiquidity => 'LIQUIDEZ DA PLATAFORMA';

  @override
  String get homeDeposits => 'DEPÓSITOS';

  @override
  String get homeWithdrawals => 'SAQUES';

  @override
  String get authRequired => 'Autenticação obrigatória';

  @override
  String get unlock => 'Desbloquear';

  @override
  String get pendingDeposits => 'Depósitos Pendentes';

  @override
  String get saqueAction => 'Saque';

  @override
  String get detailsTransaction => 'Detalhes da Transação';

  @override
  String get detailsClose => 'Fechar';

  @override
  String get noWalletsFound => 'Nenhuma carteira encontrada';

  @override
  String get createWalletPrompt =>
      'Crie uma carteira para começar a monitorar transações';

  @override
  String get createWalletAction => 'Criar Carteira';

  @override
  String get withdrawExternalBtc => 'Saque Externo BTC';

  @override
  String get withdrawExternalBtcDesc =>
      'Mova fundos da sua carteira Kerosene para um endereço Bitcoin externo.';

  @override
  String get withdrawAddressLabel => 'Endereço Bitcoin (toAddress)';

  @override
  String get withdrawAmountLabel => 'Valor em BTC';

  @override
  String get withdrawDescLabel => 'Descrição (Opcional)';

  @override
  String get withdrawDescHint => 'Ex: Transferência para Hardware Wallet';

  @override
  String get withdrawCancel => 'CANCELAR';

  @override
  String get withdrawAction => 'SACAR AGORA';

  @override
  String get errorAddressRequired => 'Endereço é obrigatório';

  @override
  String get errorAmountRequired => 'Valor é obrigatório';

  @override
  String get errorAmountInvalid => 'Valor inválido';

  @override
  String get txSent => 'Transferência Enviada';

  @override
  String get txReceived => 'Transferência Recebida';

  @override
  String get loginTotpTitle => 'Verificação de Dispositivo';

  @override
  String get loginTotpDesc =>
      'Este dispositivo é novo. Por favor insira o código de 6 dígitos do seu aplicativo autenticador para autorizá-lo.';

  @override
  String get loginTotpAction => 'VERIFICAR E ENTRAR';

  @override
  String get createWalletNameRequired => 'Nome obrigatório';

  @override
  String get createWalletNameChars => 'Apenas letras e números são permitidos';

  @override
  String get sendDescriptionLabel =>
      'Descrição (opcional, ex: Pagamento da pizza)';

  @override
  String sendInsufficientBalance(String amount) {
    return 'Saldo insuficiente. Faltam $amount BTC para completar este envio.';
  }

  @override
  String get sendSelectWallet => 'Selecionar Carteira';

  @override
  String get sendReviewTitle => 'Revisar Transação';

  @override
  String get sendTrackedReviewTitle => 'Confirmar Pagamento Rastreado';

  @override
  String get sendRecipientLabel => 'Destinatário';

  @override
  String get sendNetworkFeeLabel => 'Taxa de Rede';

  @override
  String get sendTotalLabel => 'Total';

  @override
  String get sendConfirmAction => 'Confirmar';

  @override
  String get sendPayNowAction => 'Pagar Agora';

  @override
  String get sendEnterAddressError =>
      'Por favor, insira um nome de usuário ou endereço de destino válido';

  @override
  String get sendEnterAmountError => 'Por favor, insira um valor válido';

  @override
  String get sendPaymentSuccess => 'Pagamento realizado com sucesso!';

  @override
  String get receiveReceivingWallet => 'Carteira de Recebimento';

  @override
  String get receiveExpirationLabel => 'Expiração do Link de Pagamento';

  @override
  String get receiveNoExpiration => 'Sem Expiração';

  @override
  String get receive15Min => '15 Minutos';

  @override
  String get receive1Hour => '1 Hora';

  @override
  String get receive24Hours => '24 Horas';

  @override
  String get receiveGenAction => 'Gerar Link de Pagamento';

  @override
  String get receiveQrMethod => 'QR Code';

  @override
  String get receiveNfcMethod => 'NFC Beam';

  @override
  String get receiveScanToPay => 'Escaneie para Pagar';

  @override
  String get receiveReadyToBeam => 'Pronto para Transmitir';

  @override
  String get receiveWriteNfc => 'Gravar na Tag NFC';

  @override
  String get unknownDeviceTitle => 'Autorizar Novo Dispositivo';

  @override
  String get unknownDeviceDesc =>
      'Este dispositivo não foi vinculado à sua conta.\nInsira o código de 6 dígitos do seu aplicativo autenticador para autorizá-lo.';

  @override
  String get unknownDeviceBanner => 'Novo dispositivo detectado';

  @override
  String get unknownDeviceInputHint => '000000';

  @override
  String get unknownDeviceInputErrorEmpty => 'Insira o código de 6 dígitos';

  @override
  String get unknownDeviceInputErrorLength => 'O código deve ter 6 dígitos';

  @override
  String get unknownDeviceHelper =>
      'Abra seu aplicativo autenticador e insira o código atual.';

  @override
  String get unknownDeviceAction => 'AUTORIZAR LOGIN';

  @override
  String get unknownDeviceSecurityNote =>
      'Se você não tentou fazer login, suas credenciais podem estar comprometidas. Altere sua passphrase imediatamente.';

  @override
  String get createWalletTitle => 'Nova Carteira';

  @override
  String get createWalletSuccess => 'Carteira criada com sucesso!';

  @override
  String get createWalletErrorGenFirst =>
      'Por favor, gere uma passphrase primeiro.';

  @override
  String get createWalletIdentity => 'IDENTIDADE DA CARTEIRA';

  @override
  String get createWalletNameHint => 'Poupança, Diário, etc.';

  @override
  String get createWalletSecurity => 'SEGURANÇA DA PASSPHRASE';

  @override
  String createWalletWords(int count) {
    return '$count Palavras';
  }

  @override
  String get createWalletActionGen => 'Gerar Chave de Segurança';

  @override
  String get createWalletActionCreate => 'CRIAR CARTEIRA';

  @override
  String get createWalletCopyAction => 'Copiar';

  @override
  String get createWalletCopySuccess => 'Copiado!';

  @override
  String get createWalletNewAction => 'Novo';

  @override
  String get createWalletWarning =>
      'Guarde bem estas palavras. Sem elas, seus fundos serão perdidos.';

  @override
  String get errUnexpected => 'Ocorreu um erro inesperado.';

  @override
  String get errAuthUserAlreadyExists => 'Este nome de usuário já está em uso.';

  @override
  String get errAuthUsernameMissing => 'O nome de usuário é obrigatório.';

  @override
  String get errAuthPassphraseMissing => 'A senha é obrigatória.';

  @override
  String get errAuthInvalidUsernameFormat =>
      'O formato do nome de usuário é inválido.';

  @override
  String get errAuthCharLimitExceeded => 'O limite de caracteres foi excedido.';

  @override
  String get errAuthUserNotFound =>
      'Usuário não encontrado. Verifique se digitou corretamente.';

  @override
  String get errAuthInvalidPassphraseFormat =>
      'A senha não atende aos requisitos.';

  @override
  String get errAuthIncorrectTotp => 'O código TOTP está incorreto ou expirou.';

  @override
  String get errAuthInvalidCredentials => 'Usuário ou senha incorretos.';

  @override
  String get errAuthUnrecognizedDevice =>
      'Dispositivo não reconhecido. Por favor, autorize-o.';

  @override
  String get errAuthTotpTimeout => 'O tempo para inserir o código expirou.';

  @override
  String get errLedgerNotFound =>
      'Conta financeira não encontrada. Verifique se seu cadastro foi concluído.';

  @override
  String get errLedgerAlreadyExists =>
      'A conta já possui registros financeiros.';

  @override
  String get errLedgerInsufficientBalance =>
      'Você não possui saldo suficiente para realizar esta transação.';

  @override
  String get errLedgerInvalidOperation => 'Tentativa de operação inválida.';

  @override
  String get errLedgerReceiverNotFound =>
      'O destinatário da transação não foi encontrado.';

  @override
  String get errLedgerGeneric => 'Erro interno na conta financeira.';

  @override
  String get errLedgerPaymentRequestNotFound =>
      'Link de pagamento não encontrado.';

  @override
  String get errLedgerPaymentRequestExpired =>
      'Este link de pagamento expirou.';

  @override
  String get errLedgerPaymentRequestAlreadyPaid =>
      'Este link de pagamento já foi pago.';

  @override
  String get errLedgerPaymentRequestSelfPay =>
      'Você não pode pagar um link criado por você mesmo.';

  @override
  String get errWalletAlreadyExists =>
      'Você já possui uma carteira com este nome.';

  @override
  String get errWalletNotFound => 'A carteira informada não foi encontrada.';

  @override
  String get errWalletGeneric => 'Erro de validação na carteira.';

  @override
  String get errNotifMissingToken => 'Token de notificação ausente.';

  @override
  String get errNotifMissingFields =>
      'Campos obrigatórios ausentes na notificação.';

  @override
  String get errInternalServer =>
      'Nossos servidores estão temporariamente indisponíveis.';

  @override
  String get errSessionExpired =>
      'Sua sessão expirou. Por favor, faça login novamente.';

  @override
  String get errForbidden => 'Acesso negado ou dispositivo não reconhecido.';

  @override
  String get errTooManySignupAttempts =>
      'Muitas tentativas de cadastro seguidas. Tente novamente mais tarde.';

  @override
  String get errNoInternet =>
      'Sem conexão com a internet ou servidor fora do ar.';

  @override
  String get errTimeout =>
      'A conexão demorou muito. Verifique sua internet e tente novamente.';

  @override
  String get errCommFailure => 'Falha na comunicação com o servidor Kerosene.';

  @override
  String get errInvalidBtcAddress => 'O endereço Bitcoin informado é inválido.';

  @override
  String get withdrawInvalidFields => 'Preencha um endereço e um valor válido.';

  @override
  String get withdrawAuthReason => 'Autentique para confirmar o saque.';

  @override
  String get withdrawAuthCancelled => 'Autenticação cancelada.';

  @override
  String get withdrawSuccess =>
      'Saque enviado com sucesso para a rede Bitcoin!';

  @override
  String get withdrawFeeSection => 'DIFICULDADE DA REDE (TAXA)';

  @override
  String get withdrawFeeFast => 'Rápido';

  @override
  String get withdrawFeeMedium => 'Médio';

  @override
  String get withdrawFeeSlow => 'Demorado';

  @override
  String get withdrawErrorFee => 'Erro ao estimar taxas da rede.';
}
