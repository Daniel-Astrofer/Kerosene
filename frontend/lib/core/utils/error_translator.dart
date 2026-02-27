import 'dart:convert';

class ErrorTranslator {
  static String translate(String codeOrMessage) {
    if (codeOrMessage.isEmpty) return 'Ocorreu um erro inesperado.';

    String codeToTest = codeOrMessage;
    String? extractedMessage;

    // Try to parse JSON from AppException.toString()
    try {
      final decoded = jsonDecode(codeOrMessage);
      if (decoded is Map<String, dynamic> &&
          decoded['type'] == 'AppException') {
        extractedMessage = decoded['message']?.toString();
        final code = decoded['errorCode']?.toString();
        if (code != null && code.isNotEmpty && code != 'null') {
          codeToTest = code;
        }
      }
    } catch (_) {
      // Fallback to regex just in case older strings are logged or passed
      final regex = RegExp(
        r'AppException\(message:\s*(.+?),\s*statusCode:\s*(.+?),\s*errorCode:\s*(.+?)\)',
      );
      final match = regex.firstMatch(codeOrMessage);
      if (match != null) {
        extractedMessage = match.group(1)?.trim();
        final code = match.group(3)?.trim();
        if (code != null && code != 'null') {
          codeToTest = code;
        }
      }
    }

    // Check for exact known Error Codes explicitly
    switch (codeToTest) {
      // Auth Errors
      case 'ERR_AUTH_USER_ALREADY_EXISTS':
        return 'Este nome de usuário já está em uso.';
      case 'ERR_AUTH_USERNAME_MISSING':
        return 'O nome de usuário é obrigatório.';
      case 'ERR_AUTH_PASSPHRASE_MISSING':
        return 'A senha é obrigatória.';
      case 'ERR_AUTH_INVALID_USERNAME_FORMAT':
        return 'O formato do nome de usuário é inválido.';
      case 'ERR_AUTH_CHARACTER_LIMIT_EXCEEDED':
        return 'O limite de caracteres foi excedido.';
      case 'ERR_AUTH_USER_NOT_FOUND':
        return 'Usuário não encontrado. Verifique se digitou corretamente.';
      case 'ERR_AUTH_INVALID_PASSPHRASE_FORMAT':
        return 'A senha não atende aos requisitos.';
      case 'ERR_AUTH_INCORRECT_TOTP':
        return 'O código TOTP está incorreto ou expirou.';
      case 'ERR_AUTH_INVALID_CREDENTIALS':
        return 'Usuário ou senha incorretos.';
      case 'ERR_AUTH_UNRECOGNIZED_DEVICE':
        return 'Dispositivo não reconhecido. Por favor, autorize-o.';
      case 'ERR_AUTH_TOTP_TIMEOUT':
        return 'O tempo para inserir o código expirou.';

      // Ledger / Balance Errors
      case 'ERR_LEDGER_NOT_FOUND':
        // This might happen if trying to fetch balance for a user that hasn't initialized their ledger yet.
        return 'Conta financeira não encontrada. Verifique se seu cadastro foi concluído.';
      case 'ERR_LEDGER_ALREADY_EXISTS':
        return 'A conta já possui registros financeiros.';
      case 'ERR_LEDGER_INSUFFICIENT_BALANCE':
        return 'Você não possui saldo suficiente para realizar esta transação.';
      case 'ERR_LEDGER_INVALID_OPERATION':
        return 'Tentativa de operação inválida.';
      case 'ERR_LEDGER_RECEIVER_NOT_FOUND':
        return 'O destinatário da transação não foi encontrado.';
      case 'ERR_LEDGER_GENERIC':
        return 'Erro interno na conta financeira.';
      case 'ERR_LEDGER_PAYMENT_REQUEST_NOT_FOUND':
        return 'Link de pagamento não encontrado.';
      case 'ERR_LEDGER_PAYMENT_REQUEST_EXPIRED':
        return 'Este link de pagamento expirou.';
      case 'ERR_LEDGER_PAYMENT_REQUEST_ALREADY_PAID':
        return 'Este link de pagamento já foi pago.';
      case 'ERR_LEDGER_PAYMENT_REQUEST_SELF_PAY':
        return 'Você não pode pagar um link criado por você mesmo.';

      // Wallet Errors
      case 'ERR_WALLET_ALREADY_EXISTS':
        return 'Você já possui uma carteira com este nome.';
      case 'ERR_WALLET_NOT_FOUND':
        return 'A carteira informada não foi encontrada.';
      case 'ERR_WALLET_GENERIC':
        return 'Erro de validação na carteira.';

      // Notifications & System Errors
      case 'ERR_NOTIF_MISSING_TOKEN':
        return 'Token de notificação ausente.';
      case 'ERR_NOTIF_MISSING_FIELDS':
        return 'Campos obrigatórios ausentes na notificação.';
      case 'ERR_INTERNAL_SERVER':
        return 'Nossos servidores estão temporariamente indisponíveis.';
    }

    // Se extraiu uma mensagem amigável do backend, vamos tentar traduzi-la se estiver em inglês
    String messageToReturn = extractedMessage ?? codeOrMessage;
    final lower = messageToReturn.toLowerCase();

    // English Fallback Translations
    if (lower.contains('invalid credentials') ||
        lower.contains('wrong password')) {
      return 'Usuário ou senha incorretos.';
    }
    if (lower.contains('totp') &&
        (lower.contains('expired') ||
            lower.contains('incorrect') ||
            lower.contains('invalid'))) {
      return 'O código TOTP está incorreto ou expirou.';
    }
    if (lower.contains('already exists')) {
      return 'Este registro já existe no sistema.';
    }
    if (lower.contains('not found')) {
      return 'O registro não foi encontrado.';
    }
    if (lower.contains('insufficient balance') ||
        lower.contains('not enough funds')) {
      return 'Você não possui saldo suficiente para realizar esta transação.';
    }
    if (lower.contains('unauthorized') ||
        lower.contains('token expired') ||
        lower.contains('invalid token')) {
      return 'Sua sessão expirou. Por favor, faça login novamente.';
    }
    if (lower.contains('forbidden') || lower.contains('access denied')) {
      return 'Acesso negado ou dispositivo não reconhecido.';
    }
    if (lower.contains('too many signup attempts')) {
      return 'Muitas tentativas de cadastro seguidas. Tente novamente mais tarde.';
    }
    if (lower.contains('connection refused') ||
        lower.contains('network is unreachable')) {
      return 'Sem conexão com a internet ou servidor fora do ar.';
    }
    if (lower.contains('timeout') || lower.contains('deadline exceeded')) {
      return 'A conexão demorou muito. Verifique sua internet e tente novamente.';
    }
    if (lower.contains('format exception') ||
        lower.contains('unexpected character')) {
      return 'Falha na comunicação com o servidor Kerosene.';
    }
    if (lower.contains('invalid address') ||
        lower.contains('bitcoin address')) {
      return 'O endereço Bitcoin informado é inválido.';
    }

    if (extractedMessage != null &&
        extractedMessage.isNotEmpty &&
        extractedMessage != 'null') {
      // Prioritize the backend message if it's not a technical string
      if (extractedMessage.contains(' ') || extractedMessage.length < 40) {
        return extractedMessage;
      }
    }

    if (codeOrMessage.length > 80 && !codeOrMessage.contains(' ')) {
      return 'Ocorreu um erro técnico inesperado. Tente novamente mais tarde.';
    }

    return codeOrMessage
        .replaceFirst('ServerException:', '')
        .replaceFirst('Exception:', '')
        .replaceFirst('Erro:', '')
        .trim();
  }
}
