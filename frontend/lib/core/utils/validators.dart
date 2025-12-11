/// Utilitários de validação
class Validators {
  // Prevent instantiation
  Validators._();

  /// Valida email
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Valida senha
  static bool isValidPassword(String password) {
    if (password.isEmpty) return false;
    return password.length >= 6;
  }

  /// Valida senha forte (com requisitos)
  static bool isStrongPassword(String password) {
    if (password.length < 8) return false;
    
    // Pelo menos uma letra maiúscula
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    
    // Pelo menos uma letra minúscula
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    
    // Pelo menos um número
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    
    // Pelo menos um caractere especial
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    
    return true;
  }

  /// Valida nome
  static bool isValidName(String name) {
    if (name.isEmpty) return false;
    if (name.length < 3) return false;
    return true;
  }

  /// Valida telefone
  static bool isValidPhone(String phone) {
    if (phone.isEmpty) return false;
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[\s\-\(\)]'), ''));
  }

  /// Valida CPF (Brasil)
  static bool isValidCPF(String cpf) {
    cpf = cpf.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cpf.length != 11) return false;
    
    // Verifica se todos os dígitos são iguais
    if (RegExp(r'^(\d)\1*$').hasMatch(cpf)) return false;
    
    // Validação do primeiro dígito verificador
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cpf[i]) * (10 - i);
    }
    int digit1 = 11 - (sum % 11);
    if (digit1 >= 10) digit1 = 0;
    
    if (digit1 != int.parse(cpf[9])) return false;
    
    // Validação do segundo dígito verificador
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cpf[i]) * (11 - i);
    }
    int digit2 = 11 - (sum % 11);
    if (digit2 >= 10) digit2 = 0;
    
    return digit2 == int.parse(cpf[10]);
  }

  /// Valida URL
  static bool isValidUrl(String url) {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  /// Valida data de nascimento (maior de 18 anos)
  static bool isValidBirthDate(DateTime birthDate) {
    final now = DateTime.now();
    final age = now.year - birthDate.year;
    
    if (age < 18) return false;
    if (age == 18) {
      if (now.month < birthDate.month) return false;
      if (now.month == birthDate.month && now.day < birthDate.day) return false;
    }
    
    return true;
  }
}
