import 'package:flutter/material.dart';

String signupCreateAccountTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Create account',
    'es' => 'Crear cuenta',
    _ => 'Criar conta',
  };
}

String signupUsernameSubtitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' =>
      'Please choose a username.\nIt will be your unique identity\nin Kerosene.',
    'es' =>
      'Por favor, elige un nombre de usuario.\nSerá tu identificación exclusiva\nen Kerosene.',
    _ =>
      'Por favor, escolha um nome de usuário.\nEle será sua identificação exclusiva\nna Kerosene.',
  };
}

String signupUsernameHint(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Enter your username',
    'es' => 'Ingresa tu nombre de usuario',
    _ => 'Digite seu nome de usuário',
  };
}

String signupUsernameCharsetRule(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Only lowercase letters, numbers, or underscore',
    'es' => 'Solo letras minúsculas, números o underscore',
    _ => 'Apenas letras minúsculas, números ou underscore',
  };
}

String signupPassphraseTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Create a strong password',
    'es' => 'Crea una contraseña fuerte',
    _ => 'Crie uma senha forte',
  };
}

String signupPassphraseSubtitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' =>
      'It protects your account and assets with maximum security. Nobody at Kerosene has access to your key.',
    'es' =>
      'Protege tu cuenta y tus activos con máxima seguridad. Nadie en Kerosene tiene acceso a tu clave.',
    _ =>
      'Ela protege sua conta e seus ativos com a máxima segurança. Ninguém da Kerosene tem acesso à sua chave.',
  };
}

String signupPassphraseLabel(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Your passphrase',
    'es' => 'Tu passphrase',
    _ => 'Sua Passphrase',
  };
}

String signupPassphraseHint(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Enter your chosen password',
    'es' => 'Ingresa la contraseña elegida',
    _ => 'Insira sua senha escolhida',
  };
}

String signupProceedAction(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Proceed',
    'es' => 'Continuar',
    _ => 'Prosseguir',
  };
}

String signupConfirmTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Confirm your password',
    'es' => 'Confirma tu contraseña',
    _ => 'Confirme sua senha',
  };
}

String signupConfirmSubtitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Please enter your passphrase again to continue.',
    'es' => 'Por favor, ingresa tu passphrase nuevamente para continuar.',
    _ => 'Por gentileza, insira sua passphrase novamente para prosseguir.',
  };
}

String signupConfirmHint(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Confirm your passphrase',
    'es' => 'Confirma tu passphrase',
    _ => 'Confirme sua passphrase',
  };
}

String signupFinishCreateAccountAction(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Finish account creation',
    'es' => 'Finalizar creación de cuenta',
    _ => 'Finalizar criação da conta',
  };
}

String signupCreatingAlmostReadyTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Almost ready',
    'es' => 'Casi listo',
    _ => 'Quase pronto',
  };
}

String signupCreatingAlmostReadySubtitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'We are configuring the final details with maximum security.',
    'es' => 'Estamos configurando los últimos detalles con máxima seguridad.',
    _ => 'Estamos configurando os últimos detalhes com segurança máxima.',
  };
}

String signupCreatingSecurityProgress(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Securing your account...',
    'es' => 'Protegiendo tu cuenta...',
    _ => 'Garantindo a segurança da sua conta...',
  };
}

String signupTotpTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Protect your account even more (optional)',
    'es' => 'Eleva la seguridad de tu cuenta (opcional)',
    _ => 'Eleve a segurança de sua conta (opcional)',
  };
}

String signupTotpSubtitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' =>
      'We recommend enabling two-factor authentication for an extra protection layer.',
    'es' =>
      'Recomendamos activar la autenticación de dos factores para una capa superior de protección.',
    _ =>
      'Recomendamos a ativação da autenticação de dois fatores para uma camada superior de proteção.',
  };
}

String signupRecoveryCodesTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Recovery codes',
    'es' => 'Códigos de recuperación',
    _ => 'Códigos de Recuperação',
  };
}

String signupTotpCodeInstruction(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Enter the 6-digit code',
    'es' => 'Ingresa el código de 6 dígitos',
    _ => 'Insira o código de 6 dígitos',
  };
}

String signupRecoveryCodesCopiedMessage(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Recovery codes copied.',
    'es' => 'Códigos de recuperación copiados.',
    _ => 'Códigos de recuperação copiados.',
  };
}

String signupRecoveryCodesUnavailableTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Codes unavailable',
    'es' => 'Códigos no disponibles',
    _ => 'Códigos indisponíveis',
  };
}

String signupRecoveryCodesUnavailableMessage(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Wait for account creation to finish and try again.',
    'es' =>
      'Espera a que termine la creación de la cuenta e inténtalo otra vez.',
    _ => 'Aguarde a criação da conta terminar e tente novamente.',
  };
}

String signupSkipAction(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Skip',
    'es' => 'Saltar',
    _ => 'Pular',
  };
}

String signupConfirmAction(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Confirm',
    'es' => 'Confirmar',
    _ => 'Confirmar',
  };
}

String signupPasskeyTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Authorize this device.',
    'es' => 'Autoriza este dispositivo.',
    _ => 'Autorize este dispositivo.',
  };
}

String signupPasskeySubtitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' =>
      'Registration is essential to ensure exclusive and protected access to your account.',
    'es' =>
      'El registro es esencial para asegurar acceso exclusivo y protegido a tu cuenta.',
    _ =>
      'O registro é essencial para assegurar um acesso exclusivo e protegido à sua conta.',
  };
}

String signupAuthorizeDeviceAction(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Authorize device',
    'es' => 'Autorizar dispositivo',
    _ => 'Autorizar dispositivo',
  };
}

String signupSuccessBody(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'You are now a Kerosene user. You can start moving funds.',
    'es' => 'Ahora eres usuario de Kerosene. Ya puedes realizar movimientos.',
    _ => 'Agora você é um usuário da Kerosene. Já pode realizar movimentações.',
  };
}

String signupStartAction(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Start',
    'es' => 'Comenzar',
    _ => 'Começar',
  };
}
