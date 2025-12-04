class User {
  String username;
  String passphrase;
  String totpSecret;
  String totpCode;

  User({
    this.username = '',
    this.passphrase = '',
    this.totpSecret = '',
    this.totpCode = '',
  });

  // Singleton instance for backward compatibility if needed, 
  // but preferably we should use the constructor.
  static final User instance = User();
}
