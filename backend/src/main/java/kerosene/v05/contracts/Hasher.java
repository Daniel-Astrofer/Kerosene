package kerosene.v05.contracts;

public interface Hasher{

    String hash(String input);
    Boolean verify(String input, String hash);
}
