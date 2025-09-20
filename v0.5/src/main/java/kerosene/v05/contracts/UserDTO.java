package kerosene.v05.contracts;

public interface UserDTO {


    String getUsername();
    String getPassphrase();
    String getTOTPSecret();
    String getTOTPCode();

    void setUsername(String username);
    void setPassphrase(String passphrase);
    void setTOTPSecret(String totpSecret);
    void setTOTPCode(String totpCode);



}
