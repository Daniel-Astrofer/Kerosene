package kerosene.v05.contracts;

public interface LoginVerifier {
    boolean checkUsername(String username);
    boolean passphraseMatcher(String username, String passphrase);
}
