/// Constantes da aplicação
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // API Endpoints
  static const String authEndpoint = '/auth';
  static const String loginEndpoint = '$authEndpoint/login';
  static const String signupEndpoint = '$authEndpoint/signup';
  static const String logoutEndpoint = '$authEndpoint/logout';
  static const String refreshTokenEndpoint = '$authEndpoint/refresh';

  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minNameLength = 3;
  static const int maxNameLength = 100;

  // Error Messages
  static const String networkErrorMessage = 'Sem conexão com a internet';
  static const String serverErrorMessage = 'Erro no servidor. Tente novamente mais tarde';
  static const String unknownErrorMessage = 'Erro desconhecido. Tente novamente';
  static const String authErrorMessage = 'Credenciais inválidas';
  static const String sessionExpiredMessage = 'Sessão expirada. Faça login novamente';

  // Success Messages
  static const String loginSuccessMessage = 'Login realizado com sucesso';
  static const String signupSuccessMessage = 'Cadastro realizado com sucesso';
  static const String logoutSuccessMessage = 'Logout realizado com sucesso';

  // Regex Patterns
  static const String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phonePattern = r'^\+?[1-9]\d{1,14}$';
  
  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String timeFormat = 'HH:mm';

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Debounce Durations
  static const Duration searchDebounce = Duration(milliseconds: 500);
  static const Duration buttonDebounce = Duration(milliseconds: 300);
}
