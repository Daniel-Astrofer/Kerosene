class User {
  String username = '';
  String passphrase = '';
  String totpSecret = '';
  String totpCode = '';

  static final User instance = User._internal();
  User._internal();

  String getUsername() => username;
  String getPassphrase() => passphrase;
  String getTotpSecret() => totpSecret;
  String getTotpCode() => totpCode;

  void setUsername(String u) => username = u;
  void setPassphrase(String p) => passphrase = p;
  void setTotpSecret(String t) => totpSecret = t;
  void setTotpCode(String c) => totpCode = c;
}
