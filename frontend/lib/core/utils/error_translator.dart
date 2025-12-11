class ErrorTranslator {
  static String translate(String message) {
    final lower = message.toLowerCase();

    // Erros de Autenticação / Conta
    if (lower.contains('403') || lower.contains('forbidden')) {
      return 'Dispositivo não reconhecido. Por favor, crie uma nova conta neste aparelho para vincular a segurança.';
    }
    if (lower.contains('user not found') ||
        lower.contains('usuário não encontrado')) {
      return 'Usuário não encontrado. Verifique se digitou corretamente.';
    }
    if (lower.contains('incorrect password') ||
        lower.contains('senha incorreta')) {
      return 'Senha incorreta. Tente novamente.';
    }
    if (lower.contains('user already exists') ||
        lower.contains('already registered')) {
      return 'Este nome de usuário já está em uso.';
    }

    // Erros de Rede
    if (lower.contains('connection refused') ||
        lower.contains('sahostexception') ||
        lower.contains('network is unreachable')) {
      return 'Não foi possível conectar ao servidor. Verifique sua internet.';
    }
    if (lower.contains('timeout')) {
      return 'A conexão demorou muito. Tente novamente.';
    }

    // Erros Gerais
    if (lower.contains('format exception') ||
        lower.contains('unexpected character')) {
      return 'Erro técnico ao processar resposta. Tente novamente mais tarde.';
    }

    // Fallback amigável se a mensagem for técnica demais
    if (message.length > 100 && !message.contains(' ')) {
      // Se for um hash ou stacktrace gigante
      return 'Ocorreu um erro inesperado. Tente novamente.';
    }

    // Retorna a original se não mapeada (mas tenta limpar prefixos chatos)
    return message
        .replaceFirst('ServerException:', '')
        .replaceFirst('Exception:', '')
        .replaceFirst('Erro:', '')
        .trim();
  }
}
