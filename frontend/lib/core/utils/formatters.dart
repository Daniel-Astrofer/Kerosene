import 'package:intl/intl.dart';

/// Utilitários de formatação
class Formatters {
  // Prevent instantiation
  Formatters._();

  /// Formata data
  static String formatDate(DateTime date, {String pattern = 'dd/MM/yyyy'}) {
    return DateFormat(pattern).format(date);
  }

  /// Formata data e hora
  static String formatDateTime(DateTime dateTime, {String pattern = 'dd/MM/yyyy HH:mm'}) {
    return DateFormat(pattern).format(dateTime);
  }

  /// Formata hora
  static String formatTime(DateTime time, {String pattern = 'HH:mm'}) {
    return DateFormat(pattern).format(time);
  }

  /// Formata moeda (BRL)
  static String formatCurrency(double value, {String locale = 'pt_BR', String symbol = 'R\$'}) {
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  /// Formata número com separador de milhares
  static String formatNumber(num value, {int decimalDigits = 0}) {
    final formatter = NumberFormat.decimalPattern('pt_BR');
    if (decimalDigits > 0) {
      return formatter.format(value);
    }
    return value.toStringAsFixed(decimalDigits);
  }

  /// Formata CPF (Brasil)
  static String formatCPF(String cpf) {
    cpf = cpf.replaceAll(RegExp(r'[^\d]'), '');
    if (cpf.length != 11) return cpf;
    return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9)}';
  }

  /// Formata telefone (Brasil)
  static String formatPhone(String phone) {
    phone = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    if (phone.length == 11) {
      // Celular: (XX) XXXXX-XXXX
      return '(${phone.substring(0, 2)}) ${phone.substring(2, 7)}-${phone.substring(7)}';
    } else if (phone.length == 10) {
      // Fixo: (XX) XXXX-XXXX
      return '(${phone.substring(0, 2)}) ${phone.substring(2, 6)}-${phone.substring(6)}';
    }
    
    return phone;
  }

  /// Formata CEP (Brasil)
  static String formatCEP(String cep) {
    cep = cep.replaceAll(RegExp(r'[^\d]'), '');
    if (cep.length != 8) return cep;
    return '${cep.substring(0, 5)}-${cep.substring(5)}';
  }

  /// Formata tamanho de arquivo
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Formata duração
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formata tempo relativo (ex: "há 2 horas")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'agora mesmo';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'há $minutes ${minutes == 1 ? 'minuto' : 'minutos'}';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'há $hours ${hours == 1 ? 'hora' : 'horas'}';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return 'há $days ${days == 1 ? 'dia' : 'dias'}';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'há $weeks ${weeks == 1 ? 'semana' : 'semanas'}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'há $months ${months == 1 ? 'mês' : 'meses'}';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'há $years ${years == 1 ? 'ano' : 'anos'}';
    }
  }

  /// Capitaliza primeira letra
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Capitaliza cada palavra
  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  /// Trunca texto
  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - suffix.length)}$suffix';
  }
}
