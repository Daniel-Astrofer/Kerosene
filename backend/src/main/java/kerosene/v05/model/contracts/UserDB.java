package kerosene.v05.model.contracts;

public interface UserDB extends User {
    String getTOTPSecret();
    void setTOTPSecret(String totpSecret);

}
