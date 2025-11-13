package kerosene.v05.application.service.validation.totp.contratcs;

import kerosene.v05.dto.contracts.UserDTO;

import javax.crypto.SecretKey;

public interface TOTPVerifier {

    boolean totpMatcher(String totpSecret,String code);
    void totpVerify(String totpSecret,String code) ;
    String totpDecryptedToString(String totpSecret, SecretKey secretKey);
}
