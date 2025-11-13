package kerosene.v05.application.service.cripto.contracts;

public interface Hasher{

    String hash(String input);
    Boolean verify(String input, String hash);
}
