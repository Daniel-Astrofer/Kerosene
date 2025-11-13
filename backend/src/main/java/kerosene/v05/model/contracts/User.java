package kerosene.v05.model.contracts;

public interface User{

    String getUsername();
    String getPassphrase();
    long getId();
    void setUsername(String username);
    void setPassphrase(String passphrase);


}
