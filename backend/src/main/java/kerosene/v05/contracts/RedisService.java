package kerosene.v05.contracts;

import kerosene.v05.dto.SignupUserDTO;

import javax.crypto.SecretKey;

public interface RedisService {

    Boolean totpVerify(SignupUserDTO signupUserDTO);
    SignupUserDTO jsonToSignupUserDTO(String key, String username);
    String TOTPDecryptedToString(SignupUserDTO signupUserDTO, SecretKey keybase);
    String getFromRedis(String key);
    void createTempUser(SignupUserDTO signupUserDTO);

}
