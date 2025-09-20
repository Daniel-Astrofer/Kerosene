package kerosene.v05.contracts;

public interface UserDB extends User{
    String getTOTPSecret();
    void setTOTPSecret(String totpSecret);

}
