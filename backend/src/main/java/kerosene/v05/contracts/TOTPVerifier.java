package kerosene.v05.contracts;

public interface TOTPVerifier {

    boolean TOTPMatcher(String totpSecret,String code);
}
