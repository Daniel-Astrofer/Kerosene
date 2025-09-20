package kerosene.v05.dto;


import com.fasterxml.jackson.annotation.JsonInclude;
import kerosene.v05.contracts.UserDTO;


@JsonInclude(JsonInclude.Include.NON_NULL)
public class SignupUserDTO implements UserDTO {

    private String username;
    private String passphrase;
    private String totpSecret;
    private String totpCode;


    @Override
    public String getUsername() {
        return username;
    }

    @Override
    public String getPassphrase() {
        return passphrase;
    }

    @Override
    public String getTOTPSecret() {
        return totpSecret;
    }

    @Override
    public String getTOTPCode() {
        return totpCode;
    }

    @Override
    public void setUsername(String username) {
        this.username = username;
    }

    @Override
    public void setPassphrase(String passphrase) {
        this.passphrase = passphrase;
    }

    @Override
    public void setTOTPSecret(String totpSecret) {
        this.totpSecret = totpSecret;
    }

    @Override
    public void setTOTPCode(String totpCode) {
        this.totpCode = totpCode;
    }
}
