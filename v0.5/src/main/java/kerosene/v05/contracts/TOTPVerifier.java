package kerosene.v05.contracts;

public interface TOTPVerifier {

    boolean totpMatcher(String totpSecret,String code);
}
