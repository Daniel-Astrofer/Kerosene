package kerosene.v05.contracts;

public interface User{

    String getUsername();
    String getPassphrase();
    void setUsername(String username);
    void setPassphrase(byte[] passphrase);


}
